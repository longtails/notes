### 编译ccenv若干问题

```bash
➜  fabric-dev git:(master) ✗ make ccenv
mkdir -p .build/image/ccenv/payload
cp .build/docker/gotools/bin/protoc-gen-go .build/bin/chaintool .build/goshim.tar.bz2 .build/image/ccenv/payload
cp: .build/docker/gotools/bin/protoc-gen-go: No such file or directory
make: *** [.build/image/ccenv/payload] Error 1
```

之前下修改proto文件安装下载过proto-gen-go（v2编译的，适配fabric1.4.2）,所以只需要从$GOPATH/bin下复制到 .build/docker/gotools/bin即可

```bash
➜  fabric-dev git:(master) ✗ cp $GOPATH/bin/protoc-gen-go .build/docker/gotools/bin
➜  fabric-dev git:(master) ✗ make ccenv
mkdir -p .build/image/ccenv/payload
cp .build/docker/gotools/bin/protoc-gen-go .build/bin/chaintool .build/goshim.tar.bz2 .build/image/ccenv/payload
mkdir -p .build/image/ccenv
Building docker ccenv-image
docker build  -t hyperledger/fabric-ccenv .build/image/ccenv
Sending build context to Docker daemon  26.37MB
Step 1/5 : FROM hyperledger/fabric-baseimage:amd64-0.4.15
 ---> c4c532c23a50
Step 2/5 : COPY payload/chaintool payload/protoc-gen-go /usr/local/bin/
 ---> 2117e92348c2
Step 3/5 : ADD payload/goshim.tar.bz2 $GOPATH/src/
 ---> ed14c5ac2f17
Step 4/5 : RUN mkdir -p /chaincode/input /chaincode/output
 ---> Running in 4a15881d764a
Removing intermediate container 4a15881d764a
 ---> 8724c6072a23
Step 5/5 : LABEL org.hyperledger.fabric.version=1.4.2       org.hyperledger.fabric.base.version=0.4.15
 ---> Running in 0a21f1f71649
Removing intermediate container 0a21f1f71649
 ---> 492584972c8f
Successfully built 492584972c8f
Successfully tagged hyperledger/fabric-ccenv:latest
docker tag hyperledger/fabric-ccenv hyperledger/fabric-ccenv:amd64-1.4.2-snapshot-11db71d
docker tag hyperledger/fabric-ccenv hyperledger/fabric-ccenv:amd64-latest
```

通过make gotools安装相关工具，拉取不到一些package, timeout,放弃了。


（还有，proto文件的编译，之前还想怎么把peer下的protos编译，结果在makefile中发现了，直接通过make protos就编译）


---

**修改了chaincode的shim**，加入了健康检测。ccenv是链码实例化时的编译环境，所以要使这些修改生效，需要重新编译ccenv镜像，才能在链码实例化起作用。

make ccenv 编译ccenv镜像

```bash
➜  fabric-dev git:(master) ✗ make ccenv
Installing chaintool
curl -fL https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/chaintool-1.1.3/hyperledger-fabric-chaintool-1.1.3.jar > .build/bin/chaintool
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 16.4M  100 16.4M    0     0  25181      0  0:11:25  0:11:25 --:--:-- 16277
chmod +x .build/bin/chaintool
Creating .build/goshim.tar.bz2       #这一步把本地修改过的内容加入到了ccenv的gopath/src中
mkdir -p .build/image/ccenv/payload
cp .build/docker/gotools/bin/protoc-gen-go .build/bin/chaintool .build/goshim.tar.bz2 .build/image/ccenv/payload
mkdir -p .build/image/ccenv
Building docker ccenv-image
docker build --build-arg 'http_proxy=http://127.0.0.1:1087' --build-arg 'https_proxy=http://127.0.0.1:1087' -t hyperledger/fabric-ccenv .build/image/ccenv
Sending build context to Docker daemon  26.38MB
Step 1/5 : FROM hyperledger/fabric-baseimage:amd64-0.4.15
 ---> c4c532c23a50
Step 2/5 : COPY payload/chaintool payload/protoc-gen-go /usr/local/bin/
 ---> Using cache
 ---> 67407bd280b1
Step 3/5 : ADD payload/goshim.tar.bz2 $GOPATH/src/
 ---> 67ba8c41cfc2
Step 4/5 : RUN mkdir -p /chaincode/input /chaincode/output
 ---> Running in 3c7d3213af18
Removing intermediate container 3c7d3213af18
 ---> 80117e7b8d1f
Step 5/5 : LABEL org.hyperledger.fabric.version=1.4.2       org.hyperledger.fabric.base.version=0.4.15
 ---> Running in 67073efa0fd5
Removing intermediate container 67073efa0fd5
 ---> ef886f3ccb64
Successfully built ef886f3ccb64
Successfully tagged hyperledger/fabric-ccenv:latest
docker tag hyperledger/fabric-ccenv hyperledger/fabric-ccenv:amd64-1.4.2-snapshot-11db71d
docker tag hyperledger/fabric-ccenv hyperledger/fabric-ccenv:amd64-latest
```
---

测试e2e,实例化时失败，报出编译镜像时找不到依赖。
```bash
Error: could not assemble transaction, err proposal response was not successful, error code 500, msg error starting container: error starting container: Failed to generate platform-specific docker build: Error returned from build: 1 "opt/gopath/src/github.com/docker/docker/pkg/system/path.go:9:2: cannot find package "github.com/containerd/continuity/pathdriver" in any of:
	/opt/go/src/github.com/containerd/continuity/pathdriver (from $GOROOT)
	/chaincode/input/src/github.com/containerd/continuity/pathdriver (from $GOPATH)
	/opt/gopath/src/github.com/containerd/continuity/pathdriver
...
opt/gopath/src/k8s.io/client-go/util/flowcontrol/backoff.go:24:2: cannot find package "k8s.io/utils/integer" in any of:
	/opt/go/src/k8s.io/utils/integer (from $GOROOT)
	/chaincode/input/src/k8s.io/utils/integer (from $GOPATH)
	/opt/gopath/src/k8s.io/utils/integer
"
!!!!!!!!!!!!!!! Chaincode instantiation on peer0.org1 on channel 'mychannel' failed !!!!!!!!!!!!!!!!
========= ERROR !!! FAILED to execute End-2-End Scenario ===========

```



为什么找不到依赖？很明显这些依赖是我们修改代码后导入的，官方的Makefile只加入了之前需要的依赖，所以这里我们要修改一下Makefile。

本地可以通过vendor解决依赖:用刚编译的ccenv镜像启动一个容器，并把fabric/vendor挂载进去，再进入容器重新编译、运行链码。

```bash
root@ccenv-vendor:/opt/gopath/src/github.com/chaincode/chaincode_example02/go# go build chaincode_example02.go
root@ccenv-vendor:/opt/gopath/src/github.com/chaincode/chaincode_example02/go# ls
chaincode_example02  chaincode_example02.go
root@ccenv-vendor:/opt/gopath/src/github.com/chaincode/chaincode_example02/go# ./chaincode_example02
2019-12-22 12:55:39.910 UTC [shim] setupChaincodeLogging -> INFO 001 Chaincode log level not provided; defaulting to: INFO
2019-12-22 12:55:39.910 UTC [shim] setupChaincodeLogging -> INFO 002 Chaincode (build level: ) starting up ...
2019-12-22 12:55:39.911 UTC [shim] func1 -> INFO 003 Start healthz!
^C
```


成功编译了链码，启动链码，可以看到healthz启动了。   

这里是用k8s测试的，以下是测试用的pod
```bash
➜  dnstest cat ccenvendor.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ccenv-vendor
spec:
  containers:
  - image: hyperledger/fabric-ccenv
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
    name: ccenv-build
    command:
     - sleep
     - "3600"
    name: ccenv-build
    env:
    - name: GOPATH
      value: /opt/gopath
    volumeMounts:
    - mountPath: /opt/gopath/src/github.com/chaincode
      name: chaincode
    - mountPath: /opt/gopath/src/github.com/hyperledger/fabric/vendor
      name: vendor

  restartPolicy: Always
  volumes:
  - name: chaincode
    hostPath:
      path: /Users/liu/work/go/src/github.com/hyperledger/fabric-dev/examples/fabric-samples/e2e_cli.solo/chaincode
  - name: vendor
    hostPath:
      path: /Users/liu/work/go/src/github.com/hyperledger/fabric-dev/vendor

➜  dnstest docker images |grep ccenv
hyperledger/fabric-ccenv             amd64-1.4.2-snapshot-11db71d   ef886f3ccb64        36 minutes ago      1.44GB
hyperledger/fabric-ccenv             amd64-latest                   ef886f3ccb64        36 minutes ago      1.44GB
hyperledger/fabric-ccenv             latest                         ef886f3ccb64        36 minutes ago      1.44GB
hyperledger/fabric-ccenv             1.4.2                          fc0f502399a6        5 months ago        1.43GB
➜  dnstest
```

---

我们看下怎么能把vendor也添加到ccenv中


.build/image/ccenv下有生成的编译ccenv的Dockerfile,可以看到goshim.tar.bz2是ccenv中编译的依赖文件
```bash
➜  ccenv git:(master) ✗ cat Dockerfile 
# Copyright Greg Haskins All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
FROM hyperledger/fabric-baseimage:amd64-0.4.15
COPY payload/chaintool payload/protoc-gen-go /usr/local/bin/
ADD payload/goshim.tar.bz2 $GOPATH/src/
RUN mkdir -p /chaincode/input /chaincode/output
LABEL org.hyperledger.fabric.version=1.4.2 \
      org.hyperledger.fabric.base.version=0.4.15
```


看下Makefile

```makefile

92 GOSHIM_DEPS = $(shell ./scripts/goListFiles.sh $(PKGNAME)/core/chaincode/shim)


180 ccenv: $(BUILD_DIR)/image/ccenv/$(DUMMY)

266 # payload definitions'
267 $(BUILD_DIR)/image/ccenv/payload:      $(BUILD_DIR)/docker/gotools/bin/protoc-gen-go \
				$(BUILD_DIR)/bin/chaintool \
				$(BUILD_DIR)/goshim.tar.bz2


302 $(BUILD_DIR)/image/%/$(DUMMY): Makefile $(BUILD_DIR)/image/%/payload $(BUILD_DIR)/image/%/Dockerfile
	$(eval TARGET = ${patsubst $(BUILD_DIR)/image/%/$(DUMMY),%,${@}})
	@echo "Building docker $(TARGET)-image"
	$(DBUILD) -t $(DOCKER_NS)/fabric-$(TARGET) $(@D)
	docker tag $(DOCKER_NS)/fabric-$(TARGET) $(DOCKER_NS)/fabric-$(TARGET):$(DOCKER_TAG)
	docker tag $(DOCKER_NS)/fabric-$(TARGET) $(DOCKER_NS)/fabric-$(TARGET):$(ARCH)-latest
	@touch $@


313 $(BUILD_DIR)/goshim.tar.bz2: $(GOSHIM_DEPS)
	@echo "Creating $@"
	@tar -jhc -C $(GOPATH)/src $(patsubst $(GOPATH)/src/%,%,$(GOSHIM_DEPS)) > $@
```

make ccenv 依赖\$(BUILD_DIR)/image/ccenv/\$(DUMMY)

\$(BUILD_DIR)/image/ccenv/\$(DUMMY)的依赖被302行的target包括，这里使用了通配符。其中涉及下一步的依赖\$(BUILD_DIR)/image/\%/payload

\$(BUILD_DIR)/image/ccenv/payload被\$(BUILD_DIR)/image/\%/payload 包含，看267行的target,找到了goshim.tar.bz2

\$(BUILD_DIR)/goshim.tar.bz2: \$(GOSHIM_DEPS) 包含了将依赖打包的命令（注意makefile中projectname是fabric,这里压缩fabric/下的依赖，所以如果我们开发自己的分支注意不要随意修改项目名字，或者把makefile中的project name也修改了，建议还是不要修改，因为docker生成等使用了大量的fabric的名字）  



最后定位在tar压缩，patsubst是在通过git ls-files配合通配符管理依赖，但是我们新增的依赖没有管理好。
```bash
	@tar -jhc -C $(GOPATH)/src $(patsubst $(GOPATH)/src/%,%,$(GOSHIM_DEPS)) > $@
```


所以干脆，直接把vendor压缩到goshim中,tar命令后边再加一个要压缩的文件\$(GOPATH)/src/github.com/\$(PROJECT_NAME)/vendor,但这样会把本地的路径保存下来，下条命令是不保存路径的，所以我们干脆把\$(GOPATH)/src/github.com/\$(PROJECT_NAME)/vendor添加到变量\$(GOSHIM_DEPS)中，按原来的方式处理。
```bash
92 GOSHIM_DEPS = $(shell ./scripts/goListFiles.sh $(PKGNAME)/core/chaincode/shim) $(GOPATH)/src/github.com/$(PROJECT_NAME)/vendor

313 $(BUILD_DIR)/goshim.tar.bz2: $(GOSHIM_DEPS)
	@echo "Creating $@"
	@tar -jhc -C $(GOPATH)/src $(patsubst $(GOPATH)/src/%,%,$(GOSHIM_DEPS)) > $@
```

写一个test目标，测试以下

```makefile
92 GOSHIM_DEPS = $(shell ./scripts/goListFiles.sh $(PKGNAME)/core/chaincode/shim) $(GOPATH)/src/github.com/$(PROJECT_NAME)/vendor

test: $(GOSHIM_DEPS)
	@echo "Creating $@"
	@tar -jhc -C $(GOPATH)/src $(patsubst $(GOPATH)/src/%,%,$(GOSHIM_DEPS)) > $@
```
```bash
➜  fabric-dev git:(master) ✗ ls
CHANGELOG.md       Gopkg.toml         bccsp              core               docker-env.mk      go.sum             images             peer               release_notes      test               tox.ini
CODE_OF_CONDUCT.md LICENSE            ci.properties      crossbuild.sh      docs               gossip             integration        protos             sampleconfig       test-pyramid.png   unit-test
CONTRIBUTING.md    Makefile           cmd                devenv             examples           gotools.mk         msp                pullimage.sh       scripts            testingInfo.rst    vendor
Gopkg.lock         README.md          common             discovery          go.mod             idemix             orderer            release            settings.gradle    token
➜  fabric-dev git:(master) ✗ mv test .build/test 
➜  fabric-dev git:(master) ✗ cd .build/test 

➜  test git:(master) ✗ tar -jxf test 
➜  test git:(master) ✗ ls 
github.com        golang.org        google.golang.org gopkg.in          k8s.io            test
➜  test git:(master) ✗ ls github.com/hyperledger/fabric 
bccsp  common core   idemix msp    protos vendor
➜  test git:(master) ✗ 

```
已经成功将vendor压缩到\$GOPATH/src/github.com/hyperledger/fabric下。


---
再次用新编译好的ccenv启动一个容器，编译链码测试

```bash
root@ccenv-build:/# cd $GOPATH/src
root@ccenv-build:/opt/gopath/src# ls
github.com  golang.org  google.golang.org  gopkg.in  k8s.io
root@ccenv-build:/opt/gopath/src# cd github.com/
root@ccenv-build:/opt/gopath/src/github.com# ls
BurntSushi  Knetic  chaincode  docker  fsouza  gogo  golang  hyperledger  magiconair  mitchellh  pkg  sirupsen  spf13
root@ccenv-build:/opt/gopath/src/github.com# ls hyperledger/fabric/
bccsp  common  core  idemix  msp  protos  vendor
root@ccenv-build:/opt/gopath/src/github.com# cd chaincode/
abac/                fabcar/              marbles02_private/
chaincode_example02/ marbles02/           sacc/
root@ccenv-build:/opt/gopath/src/github.com# cd chaincode/chaincode_example02/go
root@ccenv-build:/opt/gopath/src/github.com/chaincode/chaincode_example02/go# ls
chaincode_example02.go

root@ccenv-build:/opt/gopath/src/github.com/chaincode/chaincode_example02/go# go build chaincode_example02.go
root@ccenv-build:/opt/gopath/src/github.com/chaincode/chaincode_example02/go# ls
chaincode_example02  chaincode_example02.go
root@ccenv-build:/opt/gopath/src/github.com/chaincode/chaincode_example02/go# ./chaincode_example02
2019-12-22 14:30:43.550 UTC [shim] setupChaincodeLogging -> INFO 001 Chaincode log level not provided; defaulting to: INFO
2019-12-22 14:30:43.550 UTC [shim] setupChaincodeLogging -> INFO 002 Chaincode (build level: ) starting up ...
2019-12-22 14:30:43.550 UTC [shim] func1 -> INFO 003 Start healthz!
^C
```

可以看到加入的healthz启动了！