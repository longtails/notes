

Start by installing required packages run 'npm install'
Then run 'node enrollAdmin.js', then 'node registerUser'

The 'node invoke.js' will fail until it has been updated with valid arguments
The 'node query.js' may be run at anytime once the user has been registered



kubeadm join 172.19.124.123:6443 --token d6tgja.2n9k4w48vq25wprp \
    --discovery-token-ca-cert-hash sha256:689c7f42fe3b8a3520f463c8317a6d784612f32c667ed2c891b06c19d8a0337c 



To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.19.124.123:6443 --token d6tgja.2n9k4w48vq25wprp \
    --discovery-token-ca-cert-hash sha256:689c7f42fe3b8a3520f463c8317a6d784612f32c667ed2c891b06c19d8a0337c 
root@node1:~/blockchain# packet_write_wait: Connection to 106.15.46.11 port 22: Broken pipe
liu@liudeMacBook-Pro ~ % node1
Lhy12345




/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp: Setup error: nil conf reference




----
直接stop有个bug error要解决

2019-10-25 01:40:24.899 UTC [chaincode] ProcessStream -> ERRO 06e handling chaincode support stream: rpc error: code = Canceled desc = context canceled
receive failed
github.com/hyperledger/fabric/core/chaincode.(*Handler).ProcessStream
	/opt/gopath/src/github.com/hyperledger/fabric/core/chaincode/handler.go:427
github.com/hyperledger/fabric/core/chaincode.(*ChaincodeSupport).HandleChaincodeStream
	/opt/gopath/src/github.com/hyperledger/fabric/core/chaincode/chaincode_support.go:193
github.com/hyperledger/fabric/core/chaincode.(*ChaincodeSupport).Register
	/opt/gopath/src/github.com/hyperledger/fabric/core/chaincode/chaincode_support.go:198
github.com/hyperledger/fabric/core/chaincode/accesscontrol.(*interceptor).Register
	/opt/gopath/src/github.com/hyperledger/fabric/core/chaincode/accesscontrol/interceptor.go:57
github.com/hyperledger/fabric/protos/peer._ChaincodeSupport_Register_Handler
	/opt/gopath/src/github.com/hyperledger/fabric/protos/peer/chaincode_shim.pb.go:1069
github.com/hyperledger/fabric/vendor/google.golang.org/grpc.(*Server).processStreamingRPC
	/opt/gopath/src/github.com/hyperledger/fabric/vendor/google.golang.org/grpc/server.go:1124
github.com/hyperledger/fabric/vendor/google.golang.org/grpc.(*Server).handleStream
	/opt/gopath/src/github.com/hyperledger/fabric/vendor/google.golang.org/grpc/server.go:1212
github.com/hyperledger/fabric/vendor/google.golang.org/grpc.(*Server).serveStreams.func1.1
	/opt/gopath/src/github.com/hyperledger/fabric/vendor/google.golang.org/grpc/server.go:686
runtime.goexit
	/opt/go/src/runtime/asm_amd64.s:1333


2019-10-25 05:46:01.387 UTC [gossip.privdata] StoreBlock -> INFO 07d [mychannel] Received block [6] from buffer
2019-10-25 05:46:01.387 UTC [vscc] Validate -> ERRO 07e VSCC error: ValidateLSCCInvocation failed, err Existing version of the cc on the ledger (2.0) should be different from the upgraded one
2019-10-25 05:46:01.388 UTC [committer.txvalidator] validateTx -> ERRO 07f VSCCValidateTx for transaction txId = 2161e0b6052caab2f8ee89ac3dab777f5df6add080fdafdf71666eae847736d2 returned error: Existing version of the cc on the ledger (2.0) should be different from the upgraded one
2019-10-25 05:46:01.388 UTC [committer.txvalidator] Validate -> INFO 080 [mychannel] Validated block [6] in 0ms
2019-10-25 05:46:01.388 UTC [valimpl] preprocessProtoBlock -> WARN 081 Channel [mychannel]: Block [6] Transaction index [0] TxId [2161e0b6052caab2f8ee89ac3dab777f5df6add080fdafdf71666eae847736d2] marked as invalid by committer. Reason code [ENDORSEMENT_POLICY_FAILURE]
2019-10-25 05:46:01.429 UTC [kvledger] CommitWithPvtData -> INFO 082 [mychannel] Committed block [6] with 1 transaction(s) in 40ms (state_validation=0ms block_and_pvtdata_commit=33ms state_commit=4ms) commitHash=[d6e2aa3d279c8483f7d5db378140187c39aa099d79bd51fd7e0cc3a45e71123d]
2019-10-25 05:46:02.592 UTC [endorser] callChaincode -> INFO 083 [mychannel][f751ae45] Entry chaincode: name:"mycc" 
2019-10-25 05:46:02.724 UTC [chaincode] ProcessStream -> ERRO 084 handling chaincode support stream: rpc error: code = Canceled desc = context canceled
receive failed
github.com/hyperledger/fabric/core/chaincode.(*Handler).ProcessStream
	/opt/gopath/src/github.com/hyperledger/fabric/core/chaincode/handler.go:427
github.com/hyperledger/fabric/core/chaincode.(*ChaincodeSupport).HandleChaincodeStream
	/opt/gopath/src/github.com/hyperledger/fabric/core/chaincode/chaincode_support.go:235
github.com/hyperledger/fabric/core/chaincode.(*ChaincodeSupport).Register
	/opt/gopath/src/github.com/hyperledger/fabric/core/chaincode/chaincode_support.go:240
github.com/hyperledger/fabric/core/chaincode/accesscontrol.(*interceptor).Register
	/opt/gopath/src/github.com/hyperledger/fabric/core/chaincode/accesscontrol/interceptor.go:57
github.com/hyperledger/fabric/protos/peer._ChaincodeSupport_Register_Handler
	/opt/gopath/src/github.com/hyperledger/fabric/protos/peer/chaincode_shim.pb.go:1069
github.com/hyperledger/fabric/vendor/google.golang.org/grpc.(*Server).processStreamingRPC
	/opt/gopath/src/github.com/hyperledger/fabric/vendor/google.golang.org/grpc/server.go:1124
github.com/hyperledger/fabric/vendor/google.golang.org/grpc.(*Server).handleStream
	/opt/gopath/src/github.com/hyperledger/fabric/vendor/google.golang.org/grpc/server.go:1212
github.com/hyperledger/fabric/vendor/google.golang.org/grpc.(*Server).serveStreams.func1.1
	/opt/gopath/src/github.com/hyperledger/fabric/vendor/google.golang.org/grpc/server.go:686
runtime.goexit
	/opt/go/src/runtime/asm_amd64.s:1333


----

k8s

1. 修改了protobuf chaincode.proto


peer client   createProposalFromCDS


fabric/protos/utils/proputils.go
```go
// createProposalFromCDS returns a deploy or upgrade proposal given a
// serialized identity and a ChaincodeDeploymentSpec
func createProposalFromCDS(chainID string, msg proto.Message, creator []byte, propType string, args ...[]byte) (*peer.Proposal, string, error) {
	// in the new mode, cds will be nil, "deploy" and "upgrade" are instantiates.
	var ccinp *peer.ChaincodeInput
	var b []byte
	var err error
	if msg != nil {
		b, err = proto.Marshal(msg)
		if err != nil {
			return nil, "", err
		}
	}
	switch propType {
	case "deploy":
		fallthrough
	case "upgrade":  //deploy和upgrade使用同一个处理，都是实例化相关的
		cds, ok := msg.(*peer.ChaincodeDeploymentSpec)
		if !ok || cds == nil {
			return nil, "", errors.New("invalid message for creating lifecycle chaincode proposal")
		}
		Args := [][]byte{[]byte(propType), []byte(chainID), b}
		Args = append(Args, args...)

		ccinp = &peer.ChaincodeInput{Args: Args}
	case "install":
		ccinp = &peer.ChaincodeInput{Args: [][]byte{[]byte(propType), b}}
	}

	// wrap the deployment in an invocation spec to lscc...
	lsccSpec := &peer.ChaincodeInvocationSpec{
		ChaincodeSpec: &peer.ChaincodeSpec{
			Type:        peer.ChaincodeSpec_GOLANG,
			ChaincodeId: &peer.ChaincodeID{Name: "lscc"},
			Input:       ccinp,
		},
	}

	// ...and get the proposal for it
	return CreateProposalFromCIS(common.HeaderType_ENDORSER_TRANSACTION, chainID, lsccSpec, creator)
}
```
peer/node/start.go
```go

//NOTE - when we implement JOIN we will no longer pass the chainID as param
//The chaincode support will come up without registering system chaincodes
//which will be registered only during join phase.
func registerChaincodeSupport(
	grpcServer *comm.GRPCServer,
	ccEndpoint string,
	ca tlsgen.CA,
	packageProvider *persistence.PackageProvider,
	aclProvider aclmgmt.ACLProvider,
	pr *platforms.Registry,
	lifecycleSCC *lifecycle.SCC,
	ops *operations.System,
) (*chaincode.ChaincodeSupport, ccprovider.ChaincodeProvider, *scc.Provider) {
	//get user mode
	userRunsCC := chaincode.IsDevMode()
	tlsEnabled := viper.GetBool("peer.tls.enabled")

	authenticator := accesscontrol.NewAuthenticator(ca)
	ipRegistry := inproccontroller.NewRegistry()

	sccp := scc.NewProvider(peer.Default, peer.DefaultSupport, ipRegistry)
	lsccInst := lscc.New(sccp, aclProvider, pr)

	dockerProvider := dockercontroller.NewProvider(
		viper.GetString("peer.id"),
		viper.GetString("peer.networkId"),
		ops.Provider,
	)
	dockerVM := dockercontroller.NewDockerVM(
		dockerProvider.PeerID,
		dockerProvider.NetworkID,
		dockerProvider.BuildMetrics,
	)

	err := ops.RegisterChecker("docker", dockerVM)
	if err != nil {
		logger.Panicf("failed to register docker health check: %s", err)
	}

	//SIRK8S
	fmt.Println("registryChaincodeSupport!----------------")
	//SIRK8s start
	k8sDockerVM := k8scontroller.NewK8sDockerVM(
		dockerProvider.PeerID,
		dockerProvider.NetworkID,
	)

	fmt.Println(k8sDockerVM)
	/*
		if err := ops.RegisterChecker("k8s", k8sDockerVM);err != nil {
			logger.Panicf("failed to register docker health check: %s", err)
			fmt.Println("failed to register docker health check: %s", err)
		}

	*/

	k8sDockerProvider:=k8scontroller.NewProvider(
		viper.GetString("peer.id"),
		viper.GetString("peer.networkId"),
		//ops.Provider,
	)
	fmt.Println(k8sDockerProvider)
	chaincodeSupport := chaincode.NewChaincodeSupport(
		chaincode.GlobalConfig(),
		ccEndpoint,
		userRunsCC,
		ca.CertBytes(),
		authenticator,
		packageProvider,
		lsccInst,
		aclProvider,
		container.NewVMController(
			map[string]container.VMProvider{
				dockercontroller.ContainerType: dockerProvider,
				inproccontroller.ContainerType: ipRegistry,
			},
		),
		sccp,
		pr,
		peer.DefaultSupport,
		ops.Provider,
	)
	ipRegistry.ChaincodeSupport = chaincodeSupport
	ccp := chaincode.NewProvider(chaincodeSupport)

	ccSrv := pb.ChaincodeSupportServer(chaincodeSupport)
	if tlsEnabled {
		ccSrv = authenticator.Wrap(ccSrv)
	}

	csccInst := cscc.New(ccp, sccp, aclProvider)
	qsccInst := qscc.New(aclProvider)

	//Now that chaincode is initialized, register all system chaincodes.
	sccs := scc.CreatePluginSysCCs(sccp)
	for _, cc := range append([]scc.SelfDescribingSysCC{lsccInst, csccInst, qsccInst, lifecycleSCC}, sccs...) {
		sccp.RegisterSysCC(cc)
	}
	pb.RegisterChaincodeSupportServer(grpcServer.Server(), ccSrv)

	return chaincodeSupport, ccp, sccp
}
```

---

1. chaincode.proto



docker vm有个 health checker


fabric/core/chaincode/chaincode_support.go
```go
// NewChaincodeSupport creates a new ChaincodeSupport instance.
func NewChaincodeSupport(
	config *Config,
	peerAddress string,
	userRunsCC bool,
	caCert []byte,
	certGenerator CertGenerator,
	packageProvider PackageProvider,
	lifecycle Lifecycle,
	aclProvider ACLProvider,
	processor Processor,
	SystemCCProvider sysccprovider.SystemChaincodeProvider,
	platformRegistry *platforms.Registry,
	appConfig ApplicationConfigRetriever,
	metricsProvider metrics.Provider,
) *ChaincodeSupport {
	cs := &ChaincodeSupport{
		UserRunsCC:       userRunsCC,
		Keepalive:        config.Keepalive,
		ExecuteTimeout:   config.ExecuteTimeout,
		HandlerRegistry:  NewHandlerRegistry(userRunsCC),
		ACLProvider:      aclProvider,
		SystemCCProvider: SystemCCProvider,
		Lifecycle:        lifecycle,
		appConfig:        appConfig,
		HandlerMetrics:   NewHandlerMetrics(metricsProvider),
		LaunchMetrics:    NewLaunchMetrics(metricsProvider),
	}

	// Keep TestQueries working
	if !config.TLSEnabled {
		certGenerator = nil
	}

	cs.Runtime = &ContainerRuntime{
		CertGenerator:    certGenerator,
		Processor:        processor,
		CACert:           caCert,
		PeerAddress:      peerAddress,
		PlatformRegistry: platformRegistry,
		CommonEnv: []string{
			"CORE_CHAINCODE_LOGGING_LEVEL=" + config.LogLevel,
			"CORE_CHAINCODE_LOGGING_SHIM=" + config.ShimLogLevel,
			"CORE_CHAINCODE_LOGGING_FORMAT=" + config.LogFormat,
		},
	}

	cs.Launcher = &RuntimeLauncher{
		Runtime:         cs.Runtime,
		Registry:        cs.HandlerRegistry,
		PackageProvider: packageProvider,
		StartupTimeout:  config.StartupTimeout,
		Metrics:         cs.LaunchMetrics,
	}

	return cs
}
```

fabric/core/chaincode/container_runtime.go
```go

// Start launches chaincode in a runtime environment.
func (c *ContainerRuntime) Start(ccci *ccprovider.ChaincodeContainerInfo, codePackage []byte) error {
	cname := ccci.Name + ":" + ccci.Version

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

	fmt.Println("-------------!!!!!!!",ccci.ContainerType)
	if err := c.Processor.Process(ccci.ContainerType, scr); err != nil {
		return errors.WithMessage(err, "error starting container")
	}

	return nil
}
```


---
peer/chaincode/instantiate.go
```go
//instantiate the command via Endorser
func instantiate(cmd *cobra.Command, cf *ChaincodeCmdFactory) (*protcommon.Envelope, error) {
	spec, err := getChaincodeSpec(cmd)
	if err != nil {
		return nil, err
	}

	cds, err := getChaincodeDeploymentSpec(spec, false)
	if err != nil {
		return nil, fmt.Errorf("error getting chaincode code %s: %s", chaincodeName, err)
	}

	creator, err := cf.Signer.Serialize()
	if err != nil {
		return nil, fmt.Errorf("error serializing identity for %s: %s", cf.Signer.GetIdentifier(), err)
	}

	prop, _, err := utils.CreateDeployProposalFromCDS(channelID, cds, creator, policyMarshalled, []byte(escc), []byte(vscc), collectionConfigBytes)
	if err != nil {
		return nil, fmt.Errorf("error creating proposal  %s: %s", chainFuncName, err)
	}

	var signedProp *pb.SignedProposal
	signedProp, err = utils.GetSignedProposal(prop, cf.Signer)
	if err != nil {
		return nil, fmt.Errorf("error creating signed proposal  %s: %s", chainFuncName, err)
	}

	// instantiate is currently only supported for one peer
	proposalResponse, err := cf.EndorserClients[0].ProcessProposal(context.Background(), signedProp)
	if err != nil {
		return nil, fmt.Errorf("error endorsing %s: %s", chainFuncName, err)
	}

	if proposalResponse != nil {
		// assemble a signed transaction (it's an Envelope message)
		env, err := utils.CreateSignedTx(prop, cf.Signer, proposalResponse)
		if err != nil {
			return nil, fmt.Errorf("could not assemble transaction, err %s", err)
		}

		return env, nil
	}

	return nil, nil
}

```
找到设置的地方了
peer/chaincode/common.go

在这个地方设置启动了具体类型+++++++++++
```go
// getChaincodeDeploymentSpec get chaincode deployment spec given the chaincode spec
func getChaincodeDeploymentSpec(spec *pb.ChaincodeSpec, crtPkg bool) (*pb.ChaincodeDeploymentSpec, error) {
	var codePackageBytes []byte
	if chaincode.IsDevMode() == false && crtPkg {
		var err error
		if err = checkSpec(spec); err != nil {
			return nil, err
		}

		codePackageBytes, err = container.GetChaincodePackageBytes(platformRegistry, spec)
		if err != nil {
			err = errors.WithMessage(err, "error getting chaincode package bytes")
			return nil, err
		}
	}
	chaincodeDeploymentSpec := &pb.ChaincodeDeploymentSpec{ChaincodeSpec: spec, CodePackage: codePackageBytes}
	return chaincodeDeploymentSpec, nil
}
```



通过配置文件，设置peertools的debug选项，k8s/docker运行环境


peer tools客户端 改成了k8s/docker,这下来要从服务端来看


测试docker vm安装完镜像的完整流程



```go
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
```


配置文件挂在
/root/.kube/config


私有仓库配置的ip为127,无法解析，需要配置上registry docker.network，同样加上了参数解析

http://172.17.0.2:5000/v2/dev-peer0.org1.example.com-mycc-1.0-384f11f484b9302df90b453200cfb25174305fce8f53f4e94d45ee3b6cab0ce9/manifests/latest
http://127.0.0.1:5000/v2/dev-peer0.org1.example.com-mycc-1.0-384f11f484b9302df90b453200cfb25174305fce8f53f4e94d45ee3b6cab0ce9/manifests/latest


docker run -d -p 5000:5000 --name=registry --network net_byfn   --restart=always --privileged=true  --log-driver=none -v /tmp/data/registrydata:/tmp/registry registry
docker run -d --name=busybox --network net_byfn busybox sleep 3600

给他们配置到yaml文件中

lucid_bell pendantic_hertz  kind_hopper condescending_volhard condescending_ellis reverent_maxwell


//名字不符合！！！
dev-peer0.org1.example.com-mycc-1.0-384f11f484b9302df90b453200cfb25174305fce8f53f4e94d45ee3b6cab0ce9
需要解决名字和
dev-peer0-org1-example-com-mycc-1-0-384f11f484b9302df90b453200cfb25174305fce8f53f4e94d45ee3b6cab0ce9

demo-deployment-7bb7c9b595-cscd5









--apiserver-advertise-address=<ip-address>


kubeadm 打开公网监听

kubeadm init --apiserver-advertise-address=106.15.46.11  --kubernetes-version=v1.14.6 --ignore-preflight-errors=NumCPU  --image-repository gcr.azk8s.cn/google_containers 

docker pull gcr.azk8s.cn/google_containers/<imagename>:<version>
docker pull gcr.azk8s.cn/google_containers/kube-controller-manager:v1.14.6


kubeadm init --ignore-preflight-errors=NumCPU --image-repository gcr.azk8s.cn/google_containers --kubernetes-version=v1.14.6 
kubeadm init  --image-repository gcr.azk8s.cn/google_containers --kubernetes-version=v1.14.6 

node 1

kubeadm init --apiserver-advertise-address=106.15.46.11 --ignore-preflight-errors=NumCPU --image-repository=registry.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16

修改etcd
/etc/kubernetes/manifests/etcd.yaml

kubeadm init --ignore-preflight-errors=NumCPU --image-repository registry.aliyuncs.com/google_containers
kubeadm init --apiserver-advertise-address=139.159.148.148 --ignore-preflight-errors=NumCPU --image-repository registry.aliyuncs.com/google_containers

node3 
kubeadm init --apiserver-advertise-address=121.36.9.214   --kubernetes-version=v1.14.6 --image-repository registry.aliyuncs.com/google_containers


k8s.gcr.io/kube-scheduler:v1.14.6
k8s.gcr.io/kube-proxy:v1.14.6
k8s.gcr.io/kube-controller-manager:v1.14.6
k8s.gcr.io/kube-apiserver:v1.14.6


http://mirror.azure.cn/help/gcr-proxy-cache.html

https://cloud.tencent.com/developer/article/1454325

https://blog.csdn.net/Andriy_dangli/article/details/85062983


kubeadm join 106.15.46.11:6443 --token npaeg8.2wj7w65z1h1pdvkf \
>     --discovery-token-ca-cert-hash sha256:d5e0bed9c54b90bd596e2e8207bada09595e328ca1b2f52b20da51de0bf21656

之后，加上flannel插件
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml


https://www.cnblogs.com/life-of-coding/p/11879067.html
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/


kubeadm reset
systemctl stop kubelet
systemctl stop docker
rm -rf /var/lib/cni/
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/
ifconfig cni0 down
ifconfig flannel.1 down
ifconfig docker0 down
ip link delete cni0
ip link delete flannel.1
systemctl start docker
 




root@node3:~# kubeadm init --kubernetes-version=v1.14.6
[init] Using Kubernetes version: v1.14.6
[preflight] Running pre-flight checks
	[WARNING HTTPProxy]: Connection to "https://192.168.0.43" uses proxy "http://127.0.0.1:8123". If that is not intended, adjust your proxy settings
	[WARNING HTTPProxyCIDR]: connection to "10.96.0.0/12" uses proxy "http://127.0.0.1:8123". This may lead to malfunctional cluster setup. Make sure that Pod and Services IP ranges specified correctly as exceptions in proxy configuration
	[WARNING FileExisting-socat]: socat not found in system path
	[WARNING SystemVerification]: this Docker version is not on the list of validated versions: 19.03.5. Latest validated version: 18.09
	[WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'



本地安装kubelet,只有二进制包是不行的


kubelet是要安装的，如果手动下载二进制，那可能会操成发现不了


---

安装指定版本的kubelet
```bash
root@node3:~# apt-cache madison kubelet
   kubelet |  1.17.0-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.16.4-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.16.3-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.16.2-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.16.1-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.16.0-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.15.7-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.15.6-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.15.5-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.15.4-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.15.3-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.15.2-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.15.1-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.15.0-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet | 1.14.10-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.14.9-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.14.8-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.14.7-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.14.6-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.14.5-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.14.4-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.14.3-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.14.2-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.14.1-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubelet |  1.14.0-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages

root@node3:~# apt install kubelet=1.14.6-00
```


kubelet latest
```bash
root@node2-hw:~# cat /lib/systemd/system/kubelet.service
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/home/

[Service]
ExecStart=/usr/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target

```



https://developer.aliyun.com/mirror


获取ca sha

openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'

openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'

kubeadm join 106.15.46.11:6443 --token npaeg8.2wj7w65z1h1pdvkf  --discovery-token-ca-cert-hash sha256:d5e0bed9c54b90bd596e2e8207bada09595e328ca1b2f52b20da51de0bf21656  --apiserver-advertise-address 139.159.148.148  --skip-preflight-checks


kubeadm join --token b3bgdk.u5q3e2293yacce81 --discovery-token-ca-cert-hash sha256:d5e0bed9c54b90bd596e2e8207bada09595e328ca1b2f52b20da51de0bf21656   --apiserver-advertise-address 139.159.148.148 106.15.46.11:6443

0fd95a9bc67a7bf0ef42da968a0d55d92e52898ec37c971bd77ee501d845b538  172.16.6.79:6443 --skip-preflight-checks
d5e0bed9c54b90bd596e2e8207bada09595e328ca1b2f52b20da51de0bf21656



k8s 公网集群已经安装完成，（待整理）

```bash
root@node1:~# kubectl get nodes
NAME       STATUS   ROLES    AGE   VERSION
node1      Ready    master   36h   v1.14.6
node2-hw   Ready    <none>   36h   v1.14.6
node3      Ready    <none>   36h   v1.14.6
root@node1:~# kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7db9fccd9b-d94nh   1/1     Running   0          36h
root@node1:~#
```


kubeadm init 要制定cidr  --service-cidr 

----

部署测试



