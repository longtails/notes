

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

#### make peer-docker error


```bash
liu@liudeMacBook-Pro fabric % make peer-docker-clean
docker images --quiet --filter=reference='hyperledger/fabric-peer:amd64-1.4.4-snapshot-*' | xargs docker rmi -f
liu@liudeMacBook-Pro fabric % make peer-docker      
mkdir -p .build/image/peer/payload
cp .build/docker/bin/peer .build/sampleconfig.tar.bz2 .build/image/peer/payload
mkdir -p .build/image/peer
Building docker peer-image
docker build  -t hyperledger/fabric-peer .build/image/peer
Sending build context to Docker daemon  38.85MB
Step 1/7 : FROM hyperledger/fabric-baseos:amd64-0.4.16
 ---> f711d456dcc4
Step 2/7 : ENV FABRIC_CFG_PATH /etc/hyperledger/fabric
 ---> Using cache
 ---> 37208aa44860
Step 3/7 : RUN mkdir -p /var/hyperledger/production $FABRIC_CFG_PATH
 ---> Using cache
 ---> a9aa22315715
Step 4/7 : COPY payload/peer /usr/local/bin
 ---> Using cache
 ---> 119a1e66635d
Step 5/7 : ADD  payload/sampleconfig.tar.bz2 $FABRIC_CFG_PATH
failed to copy files: Error processing tar file(bzip2 data invalid: bad magic value in continuation file): 
make: *** [.build/image/peer/.dummy-amd64-1.4.4-snapshot-d0eecbac7] Error 1

```


https://github.com/HyperledgerHandsOn/trade-finance-logistics/issues/61


mac更新推荐zsh,但是之前配置的还在bash上，同时goland的终端也要source一下


https://wge4v65y.mirror.aliyuncs.com


fabric protocs    undefined: proto.ProtoPackageIsVersion3


https://xbuba.com/questions/53952723



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