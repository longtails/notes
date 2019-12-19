### Fabric链码实例化是由组织内的哪个节点完成的？

今天，修改了链码实例化的代码，在peer0.org1 peer1.org1安装链码，实例化通过peer0.org1完成。

等等，实例化通过peer0.org1完成？是的，我打算这样，方便后边看输出日志，检查代码的修改效果。
产生这个想法也是因为fabric-sample的script.sh中实例化指定了组织节点。

```bash
➜  fabric-samples git:(master) ✗ ls first-network/scripts/script.sh
first-network/scripts/script.sh
➜  fabric-samples git:(master) ✗
➜  fabric-samples git:(master) ✗ cat first-network/scripts/script.sh
# Instantiate chaincode on peer0.org1
echo "Instantiating chaincode on peer0.org1..."
instantiateChaincode 0 1
# Instantiate chaincode on peer0.org2
echo "Instantiating chaincode on peer0.org2..."
instantiateChaincode 0 2
```


但，实际上，我按照脚本指定了peer0.org1实例化，打开peer0.org1的日志输出，等cli端完成了，也没见到peer0.org1上容器启动的日志（注意是容器启动部分），最后还是在peer1.org1上看到的。  
当然，多次测试发现，容器启动部分再peer0.org1和peer1.org1上都可能出现，所以，这里就分析探索一下到底是怎么回事。


---

解决这个问题，我们先看下peer chaincode的help信息，有两个相关参数--peerAddresses和--orderer，看他们的描述
```bash
--peerAddresses stringArray      The addresses of the peers to connect to，客户端通过peers连上网络，这也是上述脚本指定的节点，客户端连接到指定的peer,交易当然由它完成了，但注意我们这里要看是谁完成了具体的容器启动的，这里还暂时看不到
  -o, --orderer string                      Ordering service endpoint,客户端连接到osn
```
实例化命令help全貌
```bash
➜  fabric-samples git:(master) ✗ peer chaincode instantiate --help
Deploy the specified chaincode to the network.

Usage:
  peer chaincode instantiate [flags]

Flags:
  -C, --channelID string               The channel on which this command should be executed
      --collections-config string      The fully qualified path to the collection JSON file including the file name
      --connectionProfile string       Connection profile that provides the necessary connection information for the network. Note: currently only supported for providing peer connection information
  -c, --ctor string                    Constructor message for the chaincode in JSON format (default "{}")
  -E, --escc string                    The name of the endorsement system chaincode to be used for this chaincode
  -h, --help                           help for instantiate
  -l, --lang string                    Language the chaincode is written in (default "golang")
  -n, --name string                    Name of the chaincode
      --peerAddresses stringArray      The addresses of the peers to connect to
  -P, --policy string                  The endorsement policy associated to this chaincode
      --tlsRootCertFiles stringArray   If TLS is enabled, the paths to the TLS root cert files of the peers to connect to. The order and number of certs specified should match the --peerAddresses flag
  -v, --version string                 Version of the chaincode specified in install/instantiate/upgrade commands
  -V, --vscc string                    The name of the verification system chaincode to be used for this chaincode

Global Flags:
      --cafile string                       Path to file containing PEM-encoded trusted certificate(s) for the ordering endpoint
      --certfile string                     Path to file containing PEM-encoded X509 public key to use for mutual TLS communication with the orderer endpoint
      --clientauth                          Use mutual TLS when communicating with the orderer endpoint
      --connTimeout duration                Timeout for client to connect (default 3s)
      --keyfile string                      Path to file containing PEM-encoded private key to use for mutual TLS communication with the orderer endpoint
  -o, --orderer string                      Ordering service endpoint
      --ordererTLSHostnameOverride string   The hostname override to use when validating the TLS connection to the orderer.
      --tls                                 Use TLS when communicating with the orderer endpoint
      --transient string                    Transient map of arguments in JSON encoding
➜  fabric-samples git:(master) ✗
```

这里我们就能看到，指定哪个节点（peer0.org1），就由谁完成此次交易（peer0.org1）,注意是这次交易，这里还看不到链码容器具体启动的过程。

---

参考[5-ChainCode生命周期、分类及安装、实例化命令解析](https://zhuanlan.zhihu.com/p/35419439),有一段话比较好：
> install 链码的对象是背书节点  
> instance 链码的对象是channel

这也是为什么实例化时指定了peer0.org1，却在peer1.org1上看到了容器的启动日志。


接下来我们从Fabric源码上来看一下，具体是怎么完成链码容器启动的。

---

链码实例化的源码可参考之前写的分析,[源码分析-Fabric 1.4.2 lscc启动用户链码的过程](https://blog.csdn.net/scylhy/article/details/102782884),还是比较清晰的，这里再回顾一下。

1. Fabric原生由两类链码系统链码和用户链码，系统链码是一段逻辑代码，形式上和用户链码相似，但不需要启动容器，对应的用户链码就是我们平常熟悉的链码，它运行在容器中。
2. 用户容器的链码是通过系统链码lscc启动的。
3. fabric peer部分分为客户端和服务端两部分，它们通过grpc连接，peer的代码入口在fabric/peer/main.go下，peer子命令包括version、node、chaincode、channel和logging,除help外正好对应peer --help对应的内容，没有help是因为help由cobra自动完成的。这些子命令，node是服务端的，chaincode、channel是客户端的会和服务进行连接。
4. 我们再说下grpc，peer客户端、服务端是通过grpc通信的，相关grpc建立过程参考[源码分析-Fabric 1.4.2 lscc启动用户链码的过程](https://blog.csdn.net/scylhy/article/details/102782884),这里重要关注双方的关联点，它们的处理函数，ProcessProposal(),后边我们分析，直接从服务端的ProcessProposal分析即可。客户端的ProcessProposal在各个子命令最后调用的时候，服务端在背书部分ProcessProposal


fabric/peer/main.go
```go
...
var mainCmd = &cobra.Command{
	Use: "peer"}
func main() {
    ...
	mainCmd.AddCommand(version.Cmd())
	mainCmd.AddCommand(node.Cmd())
	mainCmd.AddCommand(chaincode.Cmd(nil))
	mainCmd.AddCommand(clilogging.Cmd(nil))
    mainCmd.AddCommand(channel.Cmd(nil))
    ...
}
```
peer命令帮助内容
```bash
➜  ~ peer help
Usage:
  peer [command]

Available Commands:
  chaincode   Operate a chaincode: install|instantiate|invoke|package|query|signpackage|upgrade|list.
  channel     Operate a channel: create|fetch|join|list|update|signconfigtx|getinfo.
  help        Help about any command
  logging     Logging configuration: getlevel|setlevel|getlogspec|setlogspec|revertlevels.
  node        Operate a peer node: start|status|reset|rollback.
  version     Print fabric peer version.

Flags:
  -h, --help   help for peer

Use "peer [command] --help" for more information about a command.
```


peer grpc接口,fabric/protos/peer/peer.proto
```go
syntax = "proto3";

option java_package = "org.hyperledger.fabric.protos.peer";
option go_package = "github.com/hyperledger/fabric/protos/peer";

package protos;

import "peer/proposal.proto";
import "peer/proposal_response.proto";

message PeerID {
    string name = 1;
}

message PeerEndpoint {
    PeerID id = 1;
    string address = 2;
}

service Endorser {
	rpc ProcessProposal(SignedProposal) returns (ProposalResponse) {}
}
```

fabric peer instantiate的grpc客户端调用入口
```go
//instantiate the command via Endorser
func instantiate(cmd *cobra.Command, cf *ChaincodeCmdFactory) (*protcommon.Envelope, error) {
    ...
	// instantiate is currently only supported for one peer
    proposalResponse, err := cf.EndorserClients[0].ProcessProposal(context.Background(), signedProp)
    ...
}
```
fabric endorser的grpc服务端处理入口
```go
// ProcessProposal process the Proposal
func (e *Endorser) ProcessProposal(ctx context.Context, signedProp *pb.SignedProposal) (*pb.ProposalResponse, error) {
    ...
	// 0 -- check and validate
	vr, err := e.preProcess(signedProp)
	if err != nil {
		resp := vr.resp
		return resp, err
    }
    ...
	// this could be a request to a chainless SysCC

	// TODO: if the proposal has an extension, it will be of type ChaincodeAction;
	//       if it's present it means that no simulation is to be performed because
	//       we're trying to emulate a submitting peer. On the other hand, we need
	//       to validate the supplied action before endorsing it

	// 1 -- simulate
	cd, res, simulationResult, ccevent, err := e.SimulateProposal(txParams, hdrExt.ChaincodeId)
	if err != nil {
		return &pb.ProposalResponse{Response: &pb.Response{Status: 500, Message: err.Error()}}, nil
	}
	if res != nil {
		if res.Status >= shim.ERROR {
            ...
            pResp, err := putils.CreateProposalResponseFailure(prop.Header, prop.Payload, res, simulationResult, cceventBytes, hdrExt.ChaincodeId, hdrExt.PayloadVisibility)
            ...
		}
	}

	// 2 -- endorse and get a marshalled ProposalResponse message
	var pResp *pb.ProposalResponse

	// TODO till we implement global ESCC, CSCC for system chaincodes
	// chainless proposals (such as CSCC) don't have to be endorsed
	if chainID == "" {
		pResp = &pb.ProposalResponse{Response: res}
	} else {
		// Note: To endorseProposal(), we pass the released txsim. Hence, an error would occur if we try to use this txsim
        pResp, err = e.endorseProposal(ctx, chainID, txid, signedProp, prop, res, simulationResult, ccevent, hdrExt.PayloadVisibility, hdrExt.ChaincodeId, txsim, cd)
        ...
    }
    ...
}
```


---

上述4点基本上把fabric peer的逻辑整体上的情况介绍了下，接下来主要下实例化的过程。

1. peer chaincode instantiate --peerAddresses peer0.org1 ...连接到peer服务端，这个命令发送的lscc调用，上边也介绍了链码的安装、实例化都是由lscc完成的。

peer chaincode instantiate内容
```go
//fabric/peer/chaincode/instantiate.go
//instantiate the command via Endorser
func instantiate(cmd *cobra.Command, cf *ChaincodeCmdFactory) (*protcommon.Envelope, error) {
    //构造议案了，我们要看下这个函数的内容
    prop, _, err := utils.CreateDeployProposalFromCDS(channelID, cds, creator, policyMarshalled, []byte(escc), []byte(vscc), collectionConfigBytes)
    ...
    //向客户端请求
    //这里注释写的很清楚，目前仅仅支持一个节点进行背书！！但为什么会被peer1执行了呢
	// instantiate is currently only supported for one peer
	proposalResponse, err := cf.EndorserClients[0].ProcessProposal(context.Background(), signedProp)
	if err != nil {
		return nil, fmt.Errorf("error endorsing %s: %s", chainFuncName, err)
    }
    ...
}
```
peer instantiate lscc议案构建内容
```go
// CreateDeployProposalFromCDS returns a deploy proposal given a serialized
// identity and a ChaincodeDeploymentSpec
func CreateDeployProposalFromCDS(
	chainID string,
	cds *peer.ChaincodeDeploymentSpec,
	creator []byte,
	policy []byte,
	escc []byte,
	vscc []byte,
	collectionConfig []byte) (*peer.Proposal, string, error) {
	if collectionConfig == nil {
		return createProposalFromCDS(chainID, cds, creator, "deploy", policy, escc, vscc)
	}
	return createProposalFromCDS(chainID, cds, creator, "deploy", policy, escc, vscc, collectionConfig)
}
// createProposalFromCDS returns a deploy or upgrade proposal given a
// serialized identity and a ChaincodeDeploymentSpec
func createProposalFromCDS(chainID string, msg proto.Message, creator []byte, propType string, args ...[]byte) (*peer.Proposal, string, error) {
    ...
    switch propType {
	case "deploy":
		fallthrough
	case "upgrade":
		cds, ok := msg.(*peer.ChaincodeDeploymentSpec)
		fmt.Println("see ---->",cds)
		logger.Info("see->>>>",cds)
		if !ok || cds == nil {
			return nil, "", errors.New("invalid message for creating lifecycle chaincode proposal")
		}

		Args := [][]byte{[]byte(propType), []byte(chainID), b}
		Args = append(Args, args...)

		ccinp = &peer.ChaincodeInput{Args: Args}
	case "install":
		ccinp = &peer.ChaincodeInput{Args: [][]byte{[]byte(propType), b}}
    }
    //就是这，构造了lscc类型的交易请求
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

2. peer node start后启动了服务端，等待客户端请求，接收到实例化的请求

peer服务端背书处理入口
```go
//fabric/core/endorser/endorser.go
// ProcessProposal process the Proposal
func (e *Endorser) ProcessProposal(ctx context.Context, signedProp *pb.SignedProposal) (*pb.ProposalResponse, error) {
    ...
    // 0 -- check and validate
    vr, err := e.preProcess(signedProp)
    ...
	// obtaining once the tx simulator for this proposal. This will be nil
	// for chainless proposals
    // Also obtain a history query executor for history queries, since tx simulator does not cover history
    ...
	if acquireTxSimulator(chainID, vr.hdrExt.ChaincodeId) {
		if txsim, err = e.s.GetTxSimulator(chainID, txid); err != nil {
			return &pb.ProposalResponse{Response: &pb.Response{Status: 500, Message: err.Error()}}, nil
		}
		// txsim acquires a shared lock on the stateDB. As this would impact the block commits (i.e., commit
		// of valid write-sets to the stateDB), we must release the lock as early as possible.
		// Hence, this txsim object is closed in simulateProposal() as soon as the tx is simulated and
		// rwset is collected before gossip dissemination if required for privateData. For safety, we
		// add the following defer statement and is useful when an error occur. Note that calling
		// txsim.Done() more than once does not cause any issue. If the txsim is already
		// released, the following txsim.Done() simply returns.
		defer txsim.Done()

		if historyQueryExecutor, err = e.s.GetHistoryQueryExecutor(chainID); err != nil {
			return &pb.ProposalResponse{Response: &pb.Response{Status: 500, Message: err.Error()}}, nil
		}
    }
    ...
	// this could be a request to a chainless SysCC

	// TODO: if the proposal has an extension, it will be of type ChaincodeAction;
	//       if it's present it means that no simulation is to be performed because
	//       we're trying to emulate a submitting peer. On the other hand, we need
	//       to validate the supplied action before endorsing it

	// 1 -- simulate
    cd, res, simulationResult, ccevent, err := e.SimulateProposal(txParams, hdrExt.ChaincodeId)
    ...
	// 2 -- endorse and get a marshalled ProposalResponse message
	var pResp *pb.ProposalResponse

	// TODO till we implement global ESCC, CSCC for system chaincodes
	// chainless proposals (such as CSCC) don't have to be endorsed
	if chainID == "" {
		pResp = &pb.ProposalResponse{Response: res}
	} else {
		// Note: To endorseProposal(), we pass the released txsim. Hence, an error would occur if we try to use this txsim
        pResp, err = e.endorseProposal(ctx, chainID, txid, signedProp, prop, res, simulationResult, ccevent, hdrExt.PayloadVisibility, hdrExt.ChaincodeId, txsim, cd)
        ...
    }
    ...
}
```
模拟执行
```go
//fabric/core/endorser/endorser.go
// SimulateProposal simulates the proposal by calling the chaincode
func (e *Endorser) SimulateProposal(txParams *ccprovider.TransactionParams, cid *pb.ChaincodeID) (ccprovider.ChaincodeDefinition, *pb.Response, []byte, *pb.ChaincodeEvent, error) {
    ...
	// we do expect the payload to be a ChaincodeInvocationSpec
	// if we are supporting other payloads in future, this be glaringly point
    // as something that should change
    ...
    //这里判断调用链码是否是系统链码，
    if !e.s.IsSysCC(cid.Name) {
        ...
	}
    // ---3. execute the proposal and get simulation results
    //这里的callChaincode是实际调用链码处理的地方
	res, ccevent, err = e.callChaincode(txParams, version, cis.ChaincodeSpec.Input, cid)
	if err != nil {
		endorserLogger.Errorf("[%s][%s] failed to invoke chaincode %s, error: %+v", txParams.ChannelID, shorttxid(txParams.TxID), cid, err)
		return nil, nil, nil, nil, err
    }
    ...
}
```
调用链码
```go
//fabric/core/endorser/endorser.go
// call specified chaincode (system or user)
func (e *Endorser) callChaincode(txParams *ccprovider.TransactionParams, version string, input *pb.ChaincodeInput, cid *pb.ChaincodeID) (*pb.Response, *pb.ChaincodeEvent, error) {
    ...
	// is this a system chaincode
    res, ccevent, err = e.s.Execute(txParams, txParams.ChannelID, cid.Name, version, txParams.TxID, txParams.SignedProp, txParams.Proposal, input)
    ...
	// per doc anything < 400 can be sent as TX.
	// fabric errors will always be >= 400 (ie, unambiguous errors )
	// "lscc" will respond with status 200 or 500 (ie, unambiguous OK or ERROR)
	if res.Status >= shim.ERRORTHRESHOLD {
		return res, nil, nil
	}
	// ----- BEGIN -  SECTION THAT MAY NEED TO BE DONE IN LSCC ------
	// if this a call to deploy a chaincode, We need a mechanism
	// to pass TxSimulator into LSCC. Till that is worked out this
	// special code does the actual deploy, upgrade here so as to collect
	// all state under one TxSimulator
	//
	// NOTE that if there's an error all simulation, including the chaincode
    // table changes in lscc will be thrown away
    //这里就是我们实例化的要看的具体位置了，lscc的deploy调用
	if cid.Name == "lscc" && len(input.Args) >= 3 && (string(input.Args[0]) == "deploy" || string(input.Args[0]) == "upgrade") {
		userCDS, err := putils.GetChaincodeDeploymentSpec(input.Args[2], e.PlatformRegistry)
		if err != nil {
			return nil, nil, err
        }
        //解析链码部署内容
		var cds *pb.ChaincodeDeploymentSpec
		cds, err = e.SanitizeUserCDS(userCDS)
		if err != nil {
			return nil, nil, err
        }
        //用户链码不能和系统链码重名
		// this should not be a system chaincode
		if e.s.IsSysCC(cds.ChaincodeSpec.ChaincodeId.Name) {
			return nil, nil, errors.Errorf("attempting to deploy a system chaincode %s/%s", cds.ChaincodeSpec.ChaincodeId.Name, txParams.ChannelID)
        }
        //执行后续执行的初始化，这后边就是链码容器的启动过程，
        //ExecuteLegacyInit是support接口，具体调用看调用者，这里明显是sys的，可以去peer node start部分看实例构造的内容,参考之前lscc的分析文章
		_, _, err = e.s.ExecuteLegacyInit(txParams, txParams.ChannelID, cds.ChaincodeSpec.ChaincodeId.Name, cds.ChaincodeSpec.ChaincodeId.Version, txParams.TxID, txParams.SignedProp, txParams.Proposal, cds)
		if err != nil {
			// increment the failure to indicate instantion/upgrade failures
			meterLabels := []string{
				"channel", txParams.ChannelID,
				"chaincode", cds.ChaincodeSpec.ChaincodeId.Name + ":" + cds.ChaincodeSpec.ChaincodeId.Version,
			}
			e.Metrics.InitFailed.With(meterLabels...).Add(1)
			return nil, nil, err
		}
	}
    // ----- END -------
    //完成调用
	return res, ccevent, err
}


ExecuteLegacyInit是Support接口中的一个，ChaincodeSupport实现了该接口，我们先看下在服务端启动时构造的ChaincodeSupport,方便我们理解插件化怎么处理docker和sys的（通过map[name]interfalce管理的）。

fabric原生支持sys和docker的，我们也可以增加其他的，本人最近就在做这块的内容。链码实例化主要是lscc系统链码，所以主要分析sys的controller。

```
peer node start初始化时构造器的构造，也就是上述链码具体"执行者"
```go
//fabric/peer/node/start.go
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
    ...
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
				dockercontroller.ContainerType: dockerProvider, //用户链码的docker
				inproccontroller.ContainerType: ipRegistry, //系统链码的内部控制器
			},
		),
		sccp,
		pr,
		peer.DefaultSupport,
		ops.Provider,
	)
	 ...
	pb.RegisterChaincodeSupportServer(grpcServer.Server(), ccSrv)
	return chaincodeSupport, ccp, sccp
}
```

链码容器启动最终交给了ChaincodeSupport.ExecuteLegacyInit进行,这里完成了具体的链码生命周期的管理。

```go
// ExecuteLegacyInit is a temporary method which should be removed once the old style lifecycle
// is entirely deprecated.  Ideally one release after the introduction of the new lifecycle.
// It does not attempt to start the chaincode based on the information from lifecycle, but instead
// accepts the container information directly in the form of a ChaincodeDeploymentSpec.
func (cs *ChaincodeSupport) ExecuteLegacyInit(txParams *ccprovider.TransactionParams, cccid *ccprovider.CCContext, spec *pb.ChaincodeDeploymentSpec) (*pb.Response, *pb.ChaincodeEvent, error) {
	ccci := ccprovider.DeploymentSpecToChaincodeContainerInfo(spec)
    ccci.Version = cccid.Version
    //检索是否已经存在，存在直接返回，不存在就进行启动注册
    err := cs.LaunchInit(ccci)
	if err != nil {
		return nil, nil, err
	}
    cname := ccci.Name + ":" + ccci.Version
    //再次从handler中检索name对应的handler,如果没有，则说明，启动失败
	h := cs.HandlerRegistry.Handler(cname)
	if h == nil {
		return nil, nil, errors.Wrapf(err, "[channel %s] claimed to start chaincode container for %s but could not find handler", txParams.ChannelID, cname)
    }
	resp, err := cs.execute(pb.ChaincodeMessage_INIT, txParams, cccid, spec.GetChaincodeSpec().Input, h)
	return processChaincodeExecutionResult(txParams.TxID, cccid.Name, resp, err)
}
// LaunchInit bypasses getting the chaincode spec from the LSCC table
// as in the case of v1.0-v1.2 lifecycle, the chaincode will not yet be
// defined in the LSCC table
func (cs *ChaincodeSupport) LaunchInit(ccci *ccprovider.ChaincodeContainerInfo) error {
    cname := ccci.Name + ":" + ccci.Version
    //从handler取出对应的实例
	if cs.HandlerRegistry.Handler(cname) != nil {
        //如果存在直接返回了
		return nil
    }
    //取不出，说明还没有注册过，没启动过，那进行启动，这就有Launcher进行了
    //这是下一步执行入口！！
	return cs.Launcher.Launch(ccci)
}
//这里构造了交易
// execute executes a transaction and waits for it to complete until a timeout value.
func (cs *ChaincodeSupport) execute(cctyp pb.ChaincodeMessage_Type, txParams *ccprovider.TransactionParams, cccid *ccprovider.CCContext, input *pb.ChaincodeInput, h *Handler) (*pb.ChaincodeMessage, error) {
	input.Decorations = txParams.ProposalDecorations
	ccMsg, err := createCCMessage(cctyp, txParams.ChannelID, txParams.TxID, input)
	if err != nil {
		return nil, errors.WithMessage(err, "failed to create chaincode message")
	}
	ccresp, err := h.Execute(txParams, cccid, ccMsg, cs.ExecuteTimeout)
	if err != nil {
		return nil, errors.WithMessage(err, fmt.Sprintf("error sending"))
	}
	return ccresp, nil
}
//再看下chaincodeSupport的内容，方便下边定位调用者
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
    //Launcher是runtime
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
进入到下一步执行入口看(RuntimerLauncher一层封装,负责启动链码的运行时)

```go
//fabric/core/chaincode/runtime_launcher.go
//注释说的很清楚，负责启动链码的运行时
// RuntimeLauncher is responsible for launching chaincode runtimes.
type RuntimeLauncher struct {
	Runtime         Runtime
	Registry        LaunchRegistry
	PackageProvider PackageProvider
	StartupTimeout  time.Duration
	Metrics         *LaunchMetrics
}
func (r *RuntimeLauncher) Launch(ccci *ccprovider.ChaincodeContainerInfo) error {
    //检测是否正在启动，防止多次调用命令，重复启动容器
	launchState, alreadyStarted := r.Registry.Launching(cname)
	if !alreadyStarted {
        //未启动则，启动新协程启动容器
		go func() {
            //启动链码容器运行的下一个入口
			if err := r.Runtime.Start(ccci, codePackage); err != nil {
				startFailCh <- errors.WithMessage(err, "error starting container")
				return
			}
            exitCode, err := r.Runtime.Wait(ccci)
            ...
			launchState.Notify(errors.Errorf("container exited with %d", exitCode))
		}()
    }
    //以下是最后返回的处理结果
	var err error
	select {
	case <-launchState.Done():
		err = errors.WithMessage(launchState.Err(), "chaincode registration failed")
	case err = <-startFailCh:
		launchState.Notify(err)
		r.Metrics.LaunchFailures.With("chaincode", cname).Add(1)
	case <-timeoutCh:
		err = errors.Errorf("timeout expired while starting chaincode %s for transaction", cname)
		launchState.Notify(err)
		r.Metrics.LaunchTimeouts.With("chaincode", cname).Add(1)
	}

	success := true
	if err != nil && !alreadyStarted {
		success = false
		chaincodeLogger.Debugf("stopping due to error while launching: %+v", err)
		defer r.Registry.Deregister(cname)
		if err := r.Runtime.Stop(ccci); err != nil {
			chaincodeLogger.Debugf("stop failed: %+v", err)
		}
    }
    //异步等待启动结果了
	r.Metrics.LaunchDuration.With(
		"chaincode", cname,
		"success", strconv.FormatBool(success),
	).Observe(time.Since(startTime).Seconds())

	return err
}
```

下一个入口：最后找到了链码启动的关键位置，docker容器最直接的启动就在这里，之前都是Fabric网络的逻辑处理
```go
//fabric/core/container_runtime.go
// Start launches chaincode in a runtime environment.
func (c *ContainerRuntime) Start(ccci *ccprovider.ChaincodeContainerInfo, codePackage []byte) error {
	cname := ccci.Name + ":" + ccci.Version
	lc, err := c.LaunchConfig(cname, ccci.Type)
	if err != nil {
		return err
    }
    //容器启动请求这是最后真正的启动
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
    //process就是对应具体controller实例的启动，docker的话，就是行docker daemon请求启动的过程，不再分析，需要，请看fabric/core/container/dockercontroller
    if err := c.Processor.Process(ccci.ContainerType, scr); err != nil {
		return errors.WithMessage(err, "error starting container")
	}

	return nil
}
```


这一路跟踪下来，完全是同步的，一步步走到启动容器运行时，怎么可能开始交给peer0.org1，最后链码启动由peer1.org1完成呢？

事实上，就是这样的，Fabric本身不会将随机分配到其他节点上，并且从cli客户端的一段注释也能说明白，实例化本身就只有一个背书客户端参与。
fabric peer instantiate的grpc客户端调用入口
```go
//instantiate the command via Endorser
func instantiate(cmd *cobra.Command, cf *ChaincodeCmdFactory) (*protcommon.Envelope, error) {
    ...
	// instantiate is currently only supported for one peer
    proposalResponse, err := cf.EndorserClients[0].ProcessProposal(context.Background(), signedProp)
    ...
}
```
那到底是怎么回事呢？以前也没遇到过。这就跟现在的部署环境有关了,以前测试直接用fabric-sample通过docker-compose直接跑在docker上，而本次测试部署在k8s上，peer通过deployment控制器部署，而集群内域名解析通过service进行，service和deployment之间通过label-selector进行关联映射。这时，忽然一想，大概知道是怎么回事了，k8s可以通过service实现对与其关联的后端实例进行简单的负载均衡，也就是会不会peer的部署文件写错了？会不会label-selector写成一样的了，这样，fabric客户端配置的是peer0.org1（service的name）,service通过label-selector关联到后端的实例，但是peer0.org1和peer1.org1两个实例的label是一样的，这样客户端通过peer0.org1建立的连接就可能被随机负载均衡到peer1.org1上。


peer0.org1的deployment和service配置
```bash
  2 apiVersion: extensions/v1beta1
  3 kind: Deployment
  4 metadata:
  5   namespace: org1
  6 #  name:    $podName
  7   name: peer0
  8 spec:
  9   replicas: 1
 10   template:
 11     metadata:
 12       creationTimestamp: null
 13       labels:
 14         app: hyperledger
 15     spec:
 16       hostname: peer0
...
---
115 ---
116 apiVersion: v1
117 kind: Service
118 metadata:
119   name: peer0
120   namespace: org1
121 spec:
122  selector:
123    app: hyperledger
```

peer1.org1的deployment和service配置
```yaml
  2 apiVersion: extensions/v1beta1
  3 kind: Deployment
  4 metadata:
  5   namespace: org1
  6 #  name:    $podName
  7   name: peer1
  8 spec:
  9   replicas: 1
 10   template:
 11     metadata:
 12       creationTimestamp: null
 13       labels:
 14         app: hyperledger  #(真一样！！！！)
 ...
117 ---
118 apiVersion: v1
119 kind: Service
120 metadata:
121    name: peer1
122    namespace: org1
123 spec:
124  selector:
125    app: hyperledger

```

这里贴出了peer的部署配置，果然label-selector配置成一摸一样了！！

fabric on k8s启动后的状态
```bash
➜  org1 git:(master) ✗ kubectl get pods -norg1  -owide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE             NOMINATED NODE   READINESS GATES
cli-744dfcd796-7mdjg     1/1     Running   0          21m   10.1.1.197   docker-desktop   <none>           <none>
peer0-78f655d959-xkwpc   1/1     Running   0          21m   10.1.1.195   docker-desktop   <none>           <none>
peer1-7dfb54487d-zt55h   1/1     Running   0          21m   10.1.1.196   docker-desktop   <none>           <none>
➜  org1 git:(master) ✗ kubectl get svc -norg1
NAME    TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                                        AGE
peer0   NodePort   10.110.106.10    <none>        7051:31051/TCP,7052:31052/TCP,7053:31053/TCP   21m
peer1   NodePort   10.108.138.148   <none>        7051:31151/TCP,7052:31152/TCP,7053:31153/TCP   21m
➜  org1 git:(master) ✗ kubectl get ep -norg1
NAME    ENDPOINTS                                                     AGE
peer0   10.1.1.195:7053,10.1.1.196:7053,10.1.1.195:7051 + 3 more...   21m
peer1   10.1.1.195:7053,10.1.1.196:7053,10.1.1.195:7051 + 3 more...   21m
➜  org1 git:(master) ✗
```
从endpoints建立的关联看到，svc peer0和peer1都连接到了pod peer0和peer1。这也解释了，测试的时候为什么安装链码经常出现:给peer1.org1安装链码，出错peer1.org1已经安装（第一次给peer0.org1安装，实际上被分配给了peer1.org1），并且多次测试后，可以返回安装成功消息（被分配到了peer0.org1上）。

---
至此，找到了指定peer0.org1实例化，却被peer1.org1执行的问题，解决办法就是修改peer0和peer1上的label和labelSelector即可。同时，也再次通过分析链码实例化的过程，确定了实例化的过程是在一个节点上一步步过来的，不是所猜疑的事件啊、异步啊这些。


---
Perfect!  
链码实例化是简单的串行的、简单的逻辑，只支持一个背书客户端进行相关操作。


---
参考：  
1. [源码分析-Fabric 1.4.2 lscc启动用户链码的过程-作者的知乎文章](https://zhuanlan.zhihu.com/p/88905883)   
2. [源码分析-Fabric 1.4.2 lscc启动用户链码的过程-作者的csdn博客](https://blog.csdn.net/scylhy/article/details/102782884)   
3. [5-ChainCode生命周期、分类及安装、实例化命令解析](https://zhuanlan.zhihu.com/p/35419439)   