### fabric二次开发


Fabric peer chaincode添加一个参数


fabric/peer/chaincode/chaincode.go


func addFlags(cmd *cobra.Command),加入参数  

demo:
```go
func addFlags(cmd *cobra.Command) {
	common.AddOrdererFlags(cmd)
	flags := cmd.PersistentFlags()
	flags.StringVarP(&transient, "transient", "", "", "Transient map of arguments in JSON encoding")
	flags.BoolP( "demo", "d", false, "test demo")//we add
}
```

var chaincodeCmd = &cobra.Command{}

```go
var chaincodeCmd = &cobra.Command{
	Use:              chainFuncName,
	Short:            fmt.Sprint(chainCmdDes),
	Long:             fmt.Sprint(chainCmdDes),
	PersistentPreRun: common.SetOrdererEnv,
	Run: func(cmd *cobra.Command, args []string) {
		if val,err:=cmd.Flags().GetBool("demo");err!=nil{
			logger.Debug("demo flag is err,",err)
		}else{
			logger.Debug("demo flag is ",val)
		}
	},
}
```

test
```bash
root@248aa9db5ffe:/opt/gopath/src/github.com/hyperledger/fabric/peer# ./bin/peer chaincode --demo
...
2019-10-16 07:41:21.627 UTC [chaincodeCmd] func1 -> DEBU 037 demo flag is  true

root@248aa9db5ffe:/opt/gopath/src/github.com/hyperledger/fabric/peer# ./bin/peer chaincode -d 
...
2019-10-16 07:41:57.441 UTC [chaincodeCmd] func1 -> DEBU 037 demo flag is  true

root@248aa9db5ffe:/opt/gopath/src/github.com/hyperledger/fabric/peer# ./bin/peer chaincode
...
2019-10-16 07:42:51.444 UTC [chaincodeCmd] func1 -> DEBU 037 demo flag is  false

```


修改ccspec


./bin/peer  chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}' --serverless


root@bfe6b578c5c8:/var/hyperledger/production/chaincodes# ls
mycc.1.0



query和invoke 不用指定version，所以找不到存储的信息  
但是invoke前，要启动链码，是如何确定是哪个版本的。

现在通过为query和invoke增加version参数，使其能够找到对应的链码

改好了，chaincode_support.go中有个cccontext,其中包含id,name,version等信息，其实可以考虑加上serverless参数，这样就不用读取链码spec了。


peer chaincode --serverless install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd 
peer chaincode install -n mycc -v 2.0 -p github.com/chaincode/chaincode_example02/cmd

peer chaincode --serverless upgrade -n mycc -C mychannel -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd 

peer chaincode upgrade -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -v 2.0 -c '{"Args":["init","a","90","b","210"]}' -P "OR ('Org1MSP.peer','Org2MSP.peer','Org3MSP.peer')"
peer chaincode upgrade -o orderer.example.com:7050  -C mychannel -n mycc -v 2.0 -c '{"Args":["init","a","90","b","210"]}' -P "OR ('Org1MSP.peer','Org2MSP.peer','Org3MSP.peer')"

这个参数就删掉吧


-----
改fabric container  改完

fabric/container/util/dockerutil.go/NewDockerClient()


容器创建过程，定位

peer node start

fabric/peer/node/start.go
1. var cobra.command.RunE
2. func serve(args []string) error 
3. func registerChaincodeSupport(grpcServer *comm.GRPCServer, ccEndpoint string, ca tlsgen.CA, aclProvider aclmgmt.ACLProvider) (*chaincode.ChaincodeSupport, ccprovider.ChaincodeProvider, *scc.Provider) 

初始化虚拟机执行环境，插件化，对应控制器,启动链码grpc服务
```go
	chaincodeSupport := chaincode.NewChaincodeSupport(
		chaincode.GlobalConfig(),
		ccEndpoint,
		userRunsCC,
		ca.CertBytes(),
		authenticator,
		&ccprovider.CCInfoFSImpl{},
		aclProvider,
		//这是初始化了，几个controller，docker:newprovidor,system:ipregistry
		container.NewVMController(map[string]container.VMProvider{   //虚拟机实现接口,process,若要实现新的启动方式，则要实现一个controller,包括k8s,serverless
			dockercontroller.ContainerType: dockercontroller.NewProvider(  //dockercontroller.ContainerType is Docker, mp, key=docker,value=new provider
				viper.GetString("peer.id"),
				viper.GetString("peer.networkId"),
			),
			inproccontroller.ContainerType: ipRegistry,
		}),
		sccp,
	)
		ccp := chaincode.NewProvider(chaincodeSupport)

	ccSrv := pb.ChaincodeSupportServer(chaincodeSupport)
	if tlsEnabled {
		ccSrv = authenticator.Wrap(ccSrv)
	}

	//Now that chaincode is initialized, register all system chaincodes.
	sccs := scc.CreateSysCCs(ccp, sccp, aclProvider)
	for _, cc := range sccs {
		sccp.RegisterSysCC(cc)
	}
	pb.RegisterChaincodeSupportServer(grpcServer.Server(), ccSrv)//grpc进行链码执行，触发后，有执行对应的ccSrv的内容。chaincode_shim.pb.go
	//这边调用，docker端触发，执行，并将结果返回
```

endorsement，客户端发送enorse消息，grpc服务端接收到处理背书。




---
背书的服务端流程和客户端流程，blog1,2

blog1. 背书服务，创建背书服务grpc，并加入到auth的Filter中，auth是peer.EndorseServer,随后启动endorse服务；
blog2. 客户端请求背书endorse发送grpc消息到触发到auth，peer.EndorseServer处理函数，	
ProcessProposal(context.Context, *SignedProposal) (*ProposalResponse, error)  
endorse包含合约处理的内容，callchaincode  

blog3. 改造

---
命令行入口   
cobra fabric如何搞的

改动怎么改  

---
blog4. 链码容器服务端启动流程   & 链码客户端

怎么改

blog5. k8s改动，适配链码

