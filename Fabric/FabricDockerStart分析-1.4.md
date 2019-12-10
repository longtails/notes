### Fabric Docker Start 分析

这里主要分析dockercontroller.go/Start函数。

1. fabric/core/container/dockercontroller/dockercontroller.go/Start是链码容器启动的执行函数，这里详细分析该函数，解析各个过程
```go
// Start starts a container using a previously created docker image
func (vm *DockerVM) Start(ccid ccintf.CCID, args, env []string, filesToUpload map[string][]byte, builder container.Builder) error {
    //获取链码镜像名字 
    //dev-peer0.org2.example.com-mycc-1.0-15b571b3ce849066b7ec74497da3b27e54e0df1345daff3951b94245ce09c42b
	imageName, err := vm.GetVMNameForDocker(ccid)
	if err != nil {
		return err
	}

    //日志等辅助
    attachStdout := viper.GetBool("vm.docker.attachStdout")
    //生成容器名字
    //e7dd62978db0
	containerName := vm.GetVMName(ccid)
	logger := dockerLogger.With("imageName", imageName, "containerName", containerName)

    //获取一个docker client
	client, err := vm.getClientFnc()
	if err != nil {
		logger.Debugf("failed to get docker client", "error", err)
		return err
	}

    //先停止已经启动的同名容器，见2. stopInternal的分析
	vm.stopInternal(client, containerName, 0, false, false)
    //传入镜像名字、容器名字、启动参数、环境、标准输出等，启动容器
	err = vm.createContainer(client, imageName, containerName, args, env, attachStdout)
	if err == docker.ErrNoSuchImage {
        //没有对应镜像，通过builder创建
        //fabric cc 实例化时启动链码容器，这里的处理情况，主要针对服务重启后，链码可以直接用，不用重新build
        //builder来自于
		reader, err := builder.Build()
		if err != nil {
			return errors.Wrapf(err, "failed to generate Dockerfile to build %s", containerName)
        }
        //部署镜像
		err = vm.deployImage(client, ccid, reader)
		if err != nil {
			return err
        }
        //创建镜像后，在创建容器
		err = vm.createContainer(client, imageName, containerName, args, env, attachStdout)
		if err != nil {
			logger.Errorf("failed to create container: %s", err)
			return err
		}
	} else if err != nil {
		logger.Errorf("create container failed: %s", err)
		return err
	}

	// stream stdout and stderr to chaincode logger
	if attachStdout {
		containerLogger := flogging.MustGetLogger("peer.chaincode." + containerName)
		streamOutput(dockerLogger, client, containerName, containerLogger)
	}

	// upload specified files to the container before starting it
	// this can be used for configurations such as TLS key and certs
	if len(filesToUpload) != 0 {
		// the docker upload API takes a tar file, so we need to first
		// consolidate the file entries to a tar
		payload := bytes.NewBuffer(nil)
		gw := gzip.NewWriter(payload)
		tw := tar.NewWriter(gw)

        //filesToUpload中是链码启动的命令、环境参数、启动参数等信息，详见
        //5. fabric/core/chaincode/container_runtime.go/LaunchCOnfig
		for path, fileToUpload := range filesToUpload {
            //将链码打包成tar.gz,写进payload中
			cutil.WriteBytesToPackage(path, fileToUpload, tw)
		}

		// Write the tar file out
		if err := tw.Close(); err != nil {
			return fmt.Errorf("Error writing files to upload to Docker instance into a temporary tar blob: %s", err)
		}

        gw.Close()
        //将tar.gz上传到容器中,也就是最开始的createContainer虽然最终失败了，但是仍是创建了
        //见，6. github.com/fsouza/go-dockerclient/containger.go/UploadToContainer将文件上传到容器
		err := client.UploadToContainer(containerName, docker.UploadToContainerOptions{
			InputStream:          bytes.NewReader(payload.Bytes()),
			Path:                 "/",
			NoOverwriteDirNonDir: false,
		})
		if err != nil {
			return fmt.Errorf("Error uploading files to the container instance %s: %s", containerName, err)
		}
	}

    //启动容器，见，7. github.com/fsouza/go-dockerclient/containger.go/StartContainer启动容器
	// start container with HostConfig was deprecated since v1.10 and removed in v1.2
	err = client.StartContainer(containerName, nil)
	if err != nil {
		dockerLogger.Errorf("start-could not start container: %s", err)
		return err
	}

	dockerLogger.Debugf("Started container %s", containerName)
	return nil
}

```



2. fabric/core/container/dockercontroller/dockercontroller.go/stopInternal 关闭镜像，移除镜像

```go
func (vm *DockerVM) stopInternal(client dockerClient, id string, timeout uint, dontkill, dontremove bool) error {
	logger := dockerLogger.With("id", id)

	logger.Debugw("stopping container")
	err := client.StopContainer(id, timeout)
	dockerLogger.Debugw("stop container result", "error", err)

	if !dontkill {
        //根据flag，决定是否杀死容器
		logger.Debugw("killing container")
		err = client.KillContainer(docker.KillContainerOptions{ID: id})
		logger.Debugw("kill container result", "error", err)
	}

	if !dontremove {
        //根据flag，决定是否删除(rmi)容器
		logger.Debugw("removing container")
		err = client.RemoveContainer(docker.RemoveContainerOptions{ID: id, Force: true})
		logger.Debugw("remove container result", "error", err)
	}

	return err
}
```

3. fabric/core/container/dockercontroller/dockercontroller.go/createContainer 创建容器
```go

func (vm *DockerVM) createContainer(client dockerClient, imageID, containerID string, args, env []string, attachStdout bool) error {
	logger := dockerLogger.With("imageID", imageID, "containerID", containerID)
    logger.Debugw("create container")
    //传入镜像、启动命令、环境参数、标准输出、标出错误流
	_, err := client.CreateContainer(docker.CreateContainerOptions{
		Name: containerID,
		Config: &docker.Config{
			Cmd:          args,
			Image:        imageID,
			Env:          env,
			AttachStdout: attachStdout,
			AttachStderr: attachStdout,
		},
		HostConfig: getDockerHostConfig(),
	})
	if err != nil {
		return err
	}
	logger.Debugw("created container")
	return nil
}
```

4. fabric/core/chaincode/container_runtime.go/Start,构建了链码启动所需要的信息，包括链码包、参数等

```go
// Start launches chaincode in a runtime environment.
func (c *ContainerRuntime) Start(ccci *ccprovider.ChaincodeContainerInfo, codePackage []byte) error {
	cname := ccci.Name + ":" + ccci.Version
    //构建链码启动的命令、参数、环境等
	lc, err := c.LaunchConfig(cname, ccci.Type)
	if err != nil {
		return err
	}

	chaincodeLogger.Debugf("start container: %s", cname)
	chaincodeLogger.Debugf("start container with args: %s", strings.Join(lc.Args, " "))
	chaincodeLogger.Debugf("start container with env:\n\t%s", strings.Join(lc.Envs, "\n\t"))

	scr := container.StartContainerReq{
		Builder: &container.PlatformBuilder{
			Type:             ccci.Type,
			Name:             ccci.Name,
			Version:          ccci.Version,
			Path:             ccci.Path,
			CodePackage:      codePackage,
			PlatformRegistry: c.PlatformRegistry,
		},
		Args:          lc.Args,
		Env:           lc.Envs,
		FilesToUpload: lc.Files,
		CCID: ccintf.CCID{
			Name:    ccci.Name,
			Version: ccci.Version,
		},
	}

	if err := c.Processor.Process(ccci.ContainerType, scr); err != nil {
		return errors.WithMessage(err, "error starting container")
	}

	return nil
}
```

5. fabric/core/chaincode/container_runtime.go/LaunchCOnfig,构建了链码启动的命令、环境、参数等

```go
// LaunchConfig creates the LaunchConfig for chaincode running in a container.
func (c *ContainerRuntime) LaunchConfig(cname string, ccType string) (*LaunchConfig, error) {
	var lc LaunchConfig

	// common environment variables
	lc.Envs = append(c.CommonEnv, "CORE_CHAINCODE_ID_NAME="+cname)

	// language specific arguments
	switch ccType {
	case pb.ChaincodeSpec_GOLANG.String(), pb.ChaincodeSpec_CAR.String():
		lc.Args = []string{"chaincode", fmt.Sprintf("-peer.address=%s", c.PeerAddress)}
	case pb.ChaincodeSpec_JAVA.String():
		lc.Args = []string{"/root/chaincode-java/start", "--peerAddress", c.PeerAddress}
	case pb.ChaincodeSpec_NODE.String():
		lc.Args = []string{"/bin/sh", "-c", fmt.Sprintf("cd /usr/local/src; npm start -- --peer.address %s", c.PeerAddress)}
	default:
		return nil, errors.Errorf("unknown chaincodeType: %s", ccType)
	}

	// Pass TLS options to chaincode
	if c.CertGenerator != nil {
		certKeyPair, err := c.CertGenerator.Generate(cname)
		if err != nil {
			return nil, errors.WithMessage(err, fmt.Sprintf("failed to generate TLS certificates for %s", cname))
		}
		lc.Files = c.getTLSFiles(certKeyPair)
		if lc.Files == nil {
			return nil, errors.Errorf("failed to acquire TLS certificates for %s", cname)
		}

		lc.Envs = append(lc.Envs, "CORE_PEER_TLS_ENABLED=true")
		lc.Envs = append(lc.Envs, fmt.Sprintf("CORE_TLS_CLIENT_KEY_PATH=%s", TLSClientKeyPath))
		lc.Envs = append(lc.Envs, fmt.Sprintf("CORE_TLS_CLIENT_CERT_PATH=%s", TLSClientCertPath))
		lc.Envs = append(lc.Envs, fmt.Sprintf("CORE_PEER_TLS_ROOTCERT_FILE=%s", TLSClientRootCertPath))
	} else {
		lc.Envs = append(lc.Envs, "CORE_PEER_TLS_ENABLED=false")
	}

	chaincodeLogger.Debugf("launchConfig: %s", lc.String())

	return &lc, nil
}
```
6. github.com/fsouza/go-dockerclient/containger.go/UploadToContainer将文件上传到容器
```go
// UploadToContainer uploads a tar archive to be extracted to a path in the
// filesystem of the container.
//
// See https://goo.gl/g25o7u for more details.
func (c *Client) UploadToContainer(id string, opts UploadToContainerOptions) error {
	url := fmt.Sprintf("/containers/%s/archive?", id) + queryString(opts)

	return c.stream("PUT", url, streamOptions{
		in:      opts.InputStream,
		context: opts.Context,
	})
}
```

7. github.com/fsouza/go-dockerclient/containger.go/StartContainer启动容器
```go

// StartContainer starts a container, returning an error in case of failure.
//
// Passing the HostConfig to this method has been deprecated in Docker API 1.22
// (Docker Engine 1.10.x) and totally removed in Docker API 1.24 (Docker Engine
// 1.12.x). The client will ignore the parameter when communicating with Docker
// API 1.24 or greater.
//
// See https://goo.gl/fbOSZy for more details.
func (c *Client) StartContainer(id string, hostConfig *HostConfig) error {
	return c.startContainer(id, hostConfig, doOptions{})
}

// StartContainerWithContext starts a container, returning an error in case of
// failure. The context can be used to cancel the outstanding start container
// request.
//
// Passing the HostConfig to this method has been deprecated in Docker API 1.22
// (Docker Engine 1.10.x) and totally removed in Docker API 1.24 (Docker Engine
// 1.12.x). The client will ignore the parameter when communicating with Docker
// API 1.24 or greater.
//
// See https://goo.gl/fbOSZy for more details.
func (c *Client) StartContainerWithContext(id string, hostConfig *HostConfig, ctx context.Context) error {
	return c.startContainer(id, hostConfig, doOptions{context: ctx})
}

func (c *Client) startContainer(id string, hostConfig *HostConfig, opts doOptions) error {
	path := "/containers/" + id + "/start"
	if c.serverAPIVersion == nil {
		c.checkAPIVersion()
	}
	if c.serverAPIVersion != nil && c.serverAPIVersion.LessThan(apiVersion124) {
		opts.data = hostConfig
		opts.forceJSON = true
	}
	resp, err := c.do("POST", path, opts)
	if err != nil {
		if e, ok := err.(*Error); ok && e.Status == http.StatusNotFound {
			return &NoSuchContainer{ID: id, Err: err}
		}
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusNotModified {
		return &ContainerAlreadyRunning{ID: id}
	}
	return nil
}
```