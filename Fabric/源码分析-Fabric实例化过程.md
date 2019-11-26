## 源码分析-Fabric 1.4.2 lscc启动用户链码的过程


lscc负责管理链码的生命周期，其就是说链码容器的启动应该是lscc触发的。但是链码容器是如何从peer chaincode instantiate 触发实例化命令到peer服务完成链码的实例化，即链码容器的启动，看了一些网上的资料机会没有讲这块的。也因为又这块二次开发的需求，所以追踪了一下Fabric源码从lscc到用户链码容器启动的全过程，在此记录一下。


#### 客户端peer chaincode instantiate部分

fabric/peer/chaincode/instantiate.go
```go
func instantiate(cmd *cobra.Command, cf *ChaincodeCmdFactory) (*protcommon.Envelope, error) {
    ...
	// instantiate is currently only supported for one peer
    proposalResponse, err := cf.EndorserClients[0].ProcessProposal(context.Background(), signedProp
    /*
    EndorserClients[0]就是这个peer本身（但是这是在客户端里呀，配置中设置好的地址，详细看cli的配置 CORE_PEER_ADDRESS=peer0.org1.example.com:7051）
    ProcessProposal是grpc定义的函数，可以在peer.pb.go中看到定义的EndorserClient和EndorserServern内容，这里是客户端调用ProcessProposal把相关内容发送给Peer Server
    Peer chaincode instantiate是客户端，但客户端的endorseClient在哪里处理的？InitCmdFactory中
    */
    ...
}
```

ProcessProposal可以定位到grpc的定义，这是双方交互的接口  
fabric/protos/peer/peer.go
```proto
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

接下来，看下Endorser客户端是如何处理的，如何请求服务的。

先找到cf.EndorserClients是在哪里实例化的，定位到InitCmdFactory  
fabric/peer/chaincode/common.go
```go
// InitCmdFactory init the ChaincodeCmdFactory with default clients
func InitCmdFactory(cmdName string, isEndorserRequired, isOrdererRequired bool) (*ChaincodeCmdFactory, error) {
	var err error
	var endorserClients []pb.EndorserClient
	var deliverClients []api.PeerDeliverClient
	if isEndorserRequired {
		if err = validatePeerConnectionParameters(cmdName); err != nil {
			return nil, errors.WithMessage(err, "error validating peer connection parameters")
		}
		for i, address := range peerAddresses {
			var tlsRootCertFile string
			if tlsRootCertFiles != nil {
				tlsRootCertFile = tlsRootCertFiles[i]
			}
			//找到EndorserClient实例化的代码  
			endorserClient, err := common.GetEndorserClientFnc(address, tlsRootCertFile)
			//GetEndorserClientFnc的实例是在common/common.go/init()中构建
			if err != nil {
				return nil, errors.WithMessage(err, fmt.Sprintf("error getting endorser client for %s", cmdName))
			}
			endorserClients = append(endorserClients, endorserClient)
			deliverClient, err := common.GetPeerDeliverClientFnc(address, tlsRootCertFile)
			if err != nil {
				return nil, errors.WithMessage(err, fmt.Sprintf("error getting deliver client for %s", cmdName))
			}
			deliverClients = append(deliverClients, deliverClient)
		}
		if len(endorserClients) == 0 {
			return nil, errors.New("no endorser clients retrieved - this might indicate a bug")
		}
	}
	...
	return &ChaincodeCmdFactory{
		EndorserClients: endorserClients,
		DeliverClients:  deliverClients,
		Signer:          signer,
		BroadcastClient: broadcastClient,
		Certificate:     certificate,
	}, nil
}
```

通过GetEndorserClientFnc找到func GetEndorserClient(address, tlsRootCertFile string) (pb.EndorserClient, error)     
fabric/peer/common/peerclient.go

```go
// GetEndorserClient returns a new endorser client. If the both the address and
// tlsRootCertFile are not provided, the target values for the client are taken
// from the configuration settings for "peer.address" and
// "peer.tls.rootcert.file"
func GetEndorserClient(address, tlsRootCertFile string) (pb.EndorserClient, error) {
	var peerClient *PeerClient
	var err error
	if address != "" {
		peerClient, err = NewPeerClientForAddress(address, tlsRootCertFile)
	} else {
		peerClient, err = NewPeerClientFromEnv()
	}
	if err != nil {
		return nil, err
	}
	//又引出peerClient
	return peerClient.Endorser()
}
```
定位到peerclient.go，发现peerClient的许多方法，对应这不同的grpc客户端，这里是fabric中grpc客户端封装处理的地方，Endorser grpc客户端生成的方法func (pc *PeerClient) Endorser() (pb.EndorserClient, error)   
endorser grpc client实例,fabric/peer/common/peerclient.go
```go
// Endorser returns a client for the Endorser service
func (pc *PeerClient) Endorser() (pb.EndorserClient, error) {
	conn, err := pc.commonClient.NewConnection(pc.address, pc.sn)
	if err != nil {
		return nil, errors.WithMessage(err, fmt.Sprintf("endorser client failed to connect to %s", pc.address))
	}
	return pb.NewEndorserClient(conn), nil
}
```

到此，找到了endorser grpc客户端实例的创建，以及grpc的请求，调用接口ProcessProposal   
我们看到实例化是启动了背书的grpc,实际上其他交易也是启动背书过程，这是fabric，区块链的特性，大多数的处理都会在背书上，所以待会我们主要看服务端的背书处理上

peer chaincode instantiate 链码实例化客户端部分已经完成

----
### peer chaincode instantiate 链码实例化server端


服务端首先处理的是lscc的调用处理，就是lscc Invoke的地方，但如果继续看下去，就会发现，这里只是将作为参数的用户链码，存了起来，也就是说，将链码存储的是这里实现的。

fabric/core/scc/lscc/lscc.go/Invoke
```go
// Invoke implements lifecycle functions "deploy", "start", "stop", "upgrade".
// Deploy's arguments -  {[]byte("deploy"), []byte(<chainname>), <unmarshalled pb.ChaincodeDeploymentSpec>}
//
// Invoke also implements some query-like functions
// Get chaincode arguments -  {[]byte("getid"), []byte(<chainname>), []byte(<chaincodename>)}
func (lscc *LifeCycleSysCC) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	args := stub.GetArgs()
	if len(args) < 1 {
		return shim.Error(InvalidArgsLenErr(len(args)).Error())
	}

	function := string(args[0])

	// Handle ACL:
	// 1. get the signed proposal
	sp, err := stub.GetSignedProposal()
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed retrieving signed proposal on executing %s with error %s", function, err))
	}

	switch function {
	case INSTALL:
        ...
	case DEPLOY, UPGRADE:
		// we expect a minimum of 3 arguments, the function
		// name, the chain name and deployment spec
		if len(args) < 3 {
			return shim.Error(InvalidArgsLenErr(len(args)).Error())
		}

		// channel the chaincode should be associated with. It
		// should be created with a register call
		channel := string(args[1])

		if !lscc.isValidChannelName(channel) {
			return shim.Error(InvalidChannelNameErr(channel).Error())
		}

		ac, exists := lscc.SCCProvider.GetApplicationConfig(channel)
		if !exists {
			logger.Panicf("programming error, non-existent appplication config for channel '%s'", channel)
		}

		// the maximum number of arguments depends on the capability of the channel
		if !ac.Capabilities().PrivateChannelData() && len(args) > 6 {
			return shim.Error(PrivateChannelDataNotAvailable("").Error())
		}
		if ac.Capabilities().PrivateChannelData() && len(args) > 7 {
			return shim.Error(InvalidArgsLenErr(len(args)).Error())
		}

		depSpec := args[2]
		cds := &pb.ChaincodeDeploymentSpec{}
		err := proto.Unmarshal(depSpec, cds)
		if err != nil {
			return shim.Error(fmt.Sprintf("error unmarshaling ChaincodeDeploymentSpec: %s", err))
		}

		// optional arguments here (they can each be nil and may or may not be present)
		// args[3] is a marshalled SignaturePolicyEnvelope representing the endorsement policy
		// args[4] is the name of escc
		// args[5] is the name of vscc
		// args[6] is a marshalled CollectionConfigPackage struct
		var EP []byte
		if len(args) > 3 && len(args[3]) > 0 {
			EP = args[3]
		} else {
			p := cauthdsl.SignedByAnyMember(peer.GetMSPIDs(channel))
			EP, err = utils.Marshal(p)
			if err != nil {
				return shim.Error(err.Error())
			}
		}

		var escc []byte
		if len(args) > 4 && len(args[4]) > 0 {
			escc = args[4]
		} else {
			escc = []byte("escc")
		}

		var vscc []byte
		if len(args) > 5 && len(args[5]) > 0 {
			vscc = args[5]
		} else {
			vscc = []byte("vscc")
		}

		var collectionsConfig []byte
		// we proceed with a non-nil collection configuration only if
		// we Support the PrivateChannelData capability
		if ac.Capabilities().PrivateChannelData() && len(args) > 6 {
			collectionsConfig = args[6]
		}

		cd, err := lscc.executeDeployOrUpgrade(stub, channel, cds, EP, escc, vscc, collectionsConfig, function)
		if err != nil {
			return shim.Error(err.Error())
		}
		cdbytes, err := proto.Marshal(cd)
		if err != nil {
			return shim.Error(err.Error())
		}
		return shim.Success(cdbytes)
     ...
	}

	return shim.Error(InvalidFunctionErr(function).Error())
}
```

最后完成lscc的处理也是需要背书、模拟执行的，所以我们关心的链码容器启动不是在lscc的invoke上的，我们还是看背书的服务端吧。


peer服务端都是在peer node start中完成启动的，先找endorser   
peer node start中启动endorser grpc server: fabric/peer/chaincode/node/start.go/serve
```go
	pluginEndorser := endorser.NewPluginEndorser(&endorser.PluginSupport{
		ChannelStateRetriever:   channelStateRetriever,
		TransientStoreRetriever: peer.TransientStoreFactory,
		PluginMapper:            pluginMapper,
		SigningIdentityFetcher:  signingIdentityFetcher,
	})
	endorserSupport.PluginEndorser = pluginEndorser
	serverEndorser := endorser.NewEndorserServer(privDataDist, endorserSupport, pr, metricsProvider)
...
	auth := authHandler.ChainFilters(serverEndorser, authFilters...)
...
```

通过NewEndorserServer定位到Endorser的server处理端ProcessProposal，从这里，我们将看到链码启动的完成过程,lscc启动链码的全过程  

fabric/core/endorser/endorser.go
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

	prop, hdrExt, chainID, txid := vr.prop, vr.hdrExt, vr.chainID, vr.txid

	// obtaining once the tx simulator for this proposal. This will be nil
	// for chainless proposals
	// Also obtain a history query executor for history queries, since tx simulator does not cover history
	var txsim ledger.TxSimulator
	var historyQueryExecutor ledger.HistoryQueryExecutor
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

	txParams := &ccprovider.TransactionParams{
		ChannelID:            chainID,
		TxID:                 txid,
		SignedProp:           signedProp,
		Proposal:             prop,
		TXSimulator:          txsim,
		HistoryQueryExecutor: historyQueryExecutor,
	}
	// this could be a request to a chainless SysCC

	// TODO: if the proposal has an extension, it will be of type ChaincodeAction;
	//       if it's present it means that no simulation is to be performed because
	//       we're trying to emulate a submitting peer. On the other hand, we need
	//       to validate the supplied action before endorsing it

	// 1 -- simulate
	//进入simulateproposal，我们可以看到，交易执行的过程，并且将遇到一个重要的处理函数callChaincode
	cd, res, simulationResult, ccevent, err := e.SimulateProposal(txParams, hdrExt.ChaincodeId)
	if err != nil {
		return &pb.ProposalResponse{Response: &pb.Response{Status: 500, Message: err.Error()}}, nil
	}
	if res != nil {
		if res.Status >= shim.ERROR {
			endorserLogger.Errorf("[%s][%s] simulateProposal() resulted in chaincode %s response status %d for txid: %s", chainID, shorttxid(txid), hdrExt.ChaincodeId, res.Status, txid)
			var cceventBytes []byte
			if ccevent != nil {
				cceventBytes, err = putils.GetBytesChaincodeEvent(ccevent)
				if err != nil {
					return nil, errors.Wrap(err, "failed to marshal event bytes")
				}
			}
			pResp, err := putils.CreateProposalResponseFailure(prop.Header, prop.Payload, res, simulationResult, cceventBytes, hdrExt.ChaincodeId, hdrExt.PayloadVisibility)
			if err != nil {
				return &pb.ProposalResponse{Response: &pb.Response{Status: 500, Message: err.Error()}}, nil
			}

			return pResp, nil
		}
	}

	// 2 -- endorse and get a marshalled ProposalResponse message ,这里在那时不关心
	var pResp *pb.ProposalResponse

	// TODO till we implement global ESCC, CSCC for system chaincodes
	// chainless proposals (such as CSCC) don't have to be endorsed
	if chainID == "" {
		pResp = &pb.ProposalResponse{Response: res}
	} else {
		// Note: To endorseProposal(), we pass the released txsim. Hence, an error would occur if we try to use this txsim
		pResp, err = e.endorseProposal(ctx, chainID, txid, signedProp, prop, res, simulationResult, ccevent, hdrExt.PayloadVisibility, hdrExt.ChaincodeId, txsim, cd)

		// if error, capture endorsement failure metric
		meterLabels := []string{
			"channel", chainID,
			"chaincode", hdrExt.ChaincodeId.Name + ":" + hdrExt.ChaincodeId.Version,
		}

		if err != nil {
			meterLabels = append(meterLabels, "chaincodeerror", strconv.FormatBool(false))
			e.Metrics.EndorsementsFailed.With(meterLabels...).Add(1)
			return &pb.ProposalResponse{Response: &pb.Response{Status: 500, Message: err.Error()}}, nil
		}
		if pResp.Response.Status >= shim.ERRORTHRESHOLD {
			// the default ESCC treats all status codes about threshold as errors and fails endorsement
			// useful to track this as a separate metric
			meterLabels = append(meterLabels, "chaincodeerror", strconv.FormatBool(true))
			e.Metrics.EndorsementsFailed.With(meterLabels...).Add(1)
			endorserLogger.Debugf("[%s][%s] endorseProposal() resulted in chaincode %s error for txid: %s", chainID, shorttxid(txid), hdrExt.ChaincodeId, txid)
			return pResp, nil
		}
	}

	// Set the proposal response payload - it
	// contains the "return value" from the
	// chaincode invocation
	pResp.Response = res

	// total failed proposals = ProposalsReceived-SuccessfulProposals
	e.Metrics.SuccessfulProposals.Add(1)
	success = true

	return pResp, nil
}
```

通过e.SimulateProposal(txParams, hdrExt.ChaincodeId),找到执行处理的代码callChaincode   
fabric/core/endorser/endorser.go
```go
// SimulateProposal simulates the proposal by calling the chaincode
func (e *Endorser) SimulateProposal(txParams *ccprovider.TransactionParams, cid *pb.ChaincodeID) (ccprovider.ChaincodeDefinition, *pb.Response, []byte, *pb.ChaincodeEvent, error) {
	// we do expect the payload to be a ChaincodeInvocationSpec
	// if we are supporting other payloads in future, this be glaringly point
	// as something that should change
	cis, err := putils.GetChaincodeInvocationSpec(txParams.Proposal)
	if err != nil {
		return nil, nil, nil, nil, err
	}

	var cdLedger ccprovider.ChaincodeDefinition
	var version string

	if !e.s.IsSysCC(cid.Name) {
		cdLedger, err = e.s.GetChaincodeDefinition(cid.Name, txParams.TXSimulator)
		if err != nil {
			return nil, nil, nil, nil, errors.WithMessage(err, fmt.Sprintf("make sure the chaincode %s has been successfully instantiated and try again", cid.Name))
		}
		version = cdLedger.CCVersion()

		err = e.s.CheckInstantiationPolicy(cid.Name, version, cdLedger)
		if err != nil {
			return nil, nil, nil, nil, err
		}
	} else {
		version = util.GetSysCCVersion()
	}

	// ---3. execute the proposal and get simulation results
	var simResult *ledger.TxSimulationResults
	var pubSimResBytes []byte
	var res *pb.Response
	var ccevent *pb.ChaincodeEvent
	//找到处理核心，调用链码的部分，lscc启动mycc也是在这里
	res, ccevent, err = e.callChaincode(txParams, version, cis.ChaincodeSpec.Input, cid)
	...
}

```

我们找到了，**lscc启动用户链码的地方**  
fabric/core/endorser/endorser.go
```go
// call specified chaincode (system or user)
func (e *Endorser) callChaincode(txParams *ccprovider.TransactionParams, version string, input *pb.ChaincodeInput, cid *pb.ChaincodeID) (*pb.Response, *pb.ChaincodeEvent, error) {

	var err error
	var res *pb.Response
	var ccevent *pb.ChaincodeEvent

	//暂不关心
	// is this a system chaincode
	res, ccevent, err = e.s.Execute(txParams, txParams.ChannelID, cid.Name, version, txParams.TxID, txParams.SignedProp, txParams.Proposal, input)
	if err != nil {
		return nil, nil, err
	}

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
	if cid.Name == "lscc" && len(input.Args) >= 3 && (string(input.Args[0]) == "deploy" || string(input.Args[0]) == "upgrade") {
		//就是这里，判断lscc，并解析lscc链码的参数，因为参数中就是链码内容
		//userCDS就是我们要启动的链码
		userCDS, err := putils.GetChaincodeDeploymentSpec(input.Args[2], e.PlatformRegistry)
		if err != nil {
			return nil, nil, err
		}

		var cds *pb.ChaincodeDeploymentSpec
		cds, err = e.SanitizeUserCDS(userCDS)
		if err != nil {
			return nil, nil, err
		}

		// this should not be a system chaincode
		if e.s.IsSysCC(cds.ChaincodeSpec.ChaincodeId.Name) {
			return nil, nil, errors.Errorf("attempting to deploy a system chaincode %s/%s", cds.ChaincodeSpec.ChaincodeId.Name, txParams.ChannelID)
		}

		//启动链码，
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
		//用户链码启动结束
	}
	// ----- END -------
	return res, ccevent, err
}
```


**如果分析过fabric链码容器Start的过程，那接下来的部分就不用看了，我们看lscc启动链码容器，最关键的就是找到上边这个函数处理链码启动的地方。**


再定位到ExecuteLegacyInit  
fabric/core/chaincode/chaincode_support.go/ExecuteLegacyInit
```go
// ExecuteLegacyInit is a temporary method which should be removed once the old style lifecycle
// is entirely deprecated.  Ideally one release after the introduction of the new lifecycle.
// It does not attempt to start the chaincode based on the information from lifecycle, but instead
// accepts the container information directly in the form of a ChaincodeDeploymentSpec.
func (cs *ChaincodeSupport) ExecuteLegacyInit(txParams *ccprovider.TransactionParams, cccid *ccprovider.CCContext, spec *pb.ChaincodeDeploymentSpec) (*pb.Response, *pb.ChaincodeEvent, error) {
	ccci := ccprovider.DeploymentSpecToChaincodeContainerInfo(spec)
	ccci.Version = cccid.Version
	//启动链码的地方
	err := cs.LaunchInit(ccci)
	if err != nil {
		return nil, nil, err
	}
	//注册链码，就是添加个记录
	cname := ccci.Name + ":" + ccci.Version
	h := cs.HandlerRegistry.Handler(cname)
	if h == nil {
		return nil, nil, errors.Wrapf(err, "[channel %s] claimed to start chaincode container for %s but could not find handler", txParams.ChannelID, cname)
	}
	//这里暂不关心，其实还应该看链码的初始化的部分
	resp, err := cs.execute(pb.ChaincodeMessage_INIT, txParams, cccid, spec.GetChaincodeSpec().Input, h)
	return processChaincodeExecutionResult(txParams.TxID, cccid.Name, resp, err)
}
```
启动链码的地方LaunchInit  
fabric/core/chaincode/chaincode_support.go/LaunchInit
```go
// LaunchInit bypasses getting the chaincode spec from the LSCC table
// as in the case of v1.0-v1.2 lifecycle, the chaincode will not yet be
// defined in the LSCC table
func (cs *ChaincodeSupport) LaunchInit(ccci *ccprovider.ChaincodeContainerInfo) error {
	cname := ccci.Name + ":" + ccci.Version
	if cs.HandlerRegistry.Handler(cname) != nil {
		return nil
	}
	return cs.Launcher.Launch(ccci)//启动函数
}
```

定位cs.Launcher.Launch(ccci)//启动函数  
fabric/core/chaincode/runtime_supoort.go/Launch
```go

func (r *RuntimeLauncher) Launch(ccci *ccprovider.ChaincodeContainerInfo) error {
	var startFailCh chan error
	var timeoutCh <-chan time.Time

	startTime := time.Now()
	cname := ccci.Name + ":" + ccci.Version
	launchState, alreadyStarted := r.Registry.Launching(cname)
	if !alreadyStarted {
		...
		go func() {
			//启动的地方
			if err := r.Runtime.Start(ccci, codePackage); err != nil {
				startFailCh <- errors.WithMessage(err, "error starting container")
				return
			}
			exitCode, err := r.Runtime.Wait(ccci)
			if err != nil {
				launchState.Notify(errors.Wrap(err, "failed to wait on container exit"))
			}
			launchState.Notify(errors.Errorf("container exited with %d", exitCode))
		}()
	}
	//阻塞，等待启动完成
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
	...
}

```

定位Runtime.Start  
fabric/core/chaincode/container_runtime.go
```go
// Start launches chaincode in a runtime environment.
func (c *ContainerRuntime) Start(ccci *ccprovider.ChaincodeContainerInfo, codePackage []byte) error {
	cname := ccci.Name + ":" + ccci.Version
	//读取peer的配置文件，关于docker engine的
	lc, err := c.LaunchConfig(cname, ccci.Type)
	if err != nil {
		return err
	}
	...
	//这里是设置容器的启动配置
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
	//启动的地方，ccci.ContainerType又两种sys和docker,用户链码是docker启动，接下来会构造docker client向docker engine请求启动容器
	if err := c.Processor.Process(ccci.ContainerType, scr); err != nil {
		return errors.WithMessage(err, "error starting container")
	}
	return nil
}
```

定位到Processor，是个接口，我们通过ChaincodeSupport的实例化的时候的配置，找到Processor的实例化  
fabric/core/chaincode/container_runtime.go
```go
// Processor processes vm and container requests.
type Processor interface {
	Process(vmtype string, req container.VMCReq) error
}
```

定位到Controller  
fabric/conre/container/controller.go
```go
func (vmc *VMController) Process(vmtype string, req VMCReq) error {
	v := vmc.newVM(vmtype)
	ccid := req.GetCCID()
	id := ccid.GetName()

	vmc.lockContainer(id)
	defer vmc.unlockContainer(id)
	return req.Do(v)
}
```

VMCReq也是接口，这里又两个实现，一个是Start，一个是Stop，都是通过Do完成相关操作的,这里我们就看Start的  
fabric/conre/container/controller.go
```go
type VMCReq interface {
	Do(v VM) error
	GetCCID() ccintf.CCID
}
//StartContainerReq - properties for starting a container.
type StartContainerReq struct {
	ccintf.CCID
	Builder       Builder
	Args          []string
	Env           []string
	FilesToUpload map[string][]byte
}

func (si StartContainerReq) Do(v VM) error {
	//通过v启动了start,我们看VMcontroller.Proccess中v的实例
	return v.Start(si.CCID, si.Args, si.Env, si.FilesToUpload, si.Builder)
}
```


看实例化VM的函数  
fabric/conre/container/controller.go
```go
func (vmc *VMController) newVM(typ string) VM {
	//通过map得到了一个实例，我们找到最初定义chaincodeSupport的地方看实例了哪几个vm
	v, ok := vmc.vmProviders[typ]
	if !ok {
		vmLogger.Panicf("Programming error: unsupported VM type: %s", typ)
	}
	return v.NewVM()
}
```
回看vm实例  
fabric/peer/node/start.go/serve
```go
	chaincodeSupport := NewChaincodeSupport(
		config,
		"0.0.0.0:7052",
		true,
		ca.CertBytes(),
		certGenerator,
		&ccprovider.CCInfoFSImpl{},
		lsccImpl,
		mockAclProvider,
		container.NewVMController(
			map[string]container.VMProvider{
				//const ContainerType = "DOCKER"
				//第一个dockercontroller，这是我们需要的用户链码执行环境
				dockercontroller.ContainerType: dockercontroller.NewProvider("", "", &disabled.Provider{}),
				//const ContainerType = "SYSTEM"
				//这就是sys的执行环境
				inproccontroller.ContainerType: ipRegistry,
			},
		),
		sccp,
		pr,
		peer.DefaultSupport,
		&disabled.Provider{},
	)
```

我们看实现了VM接口的controller   

```go
type VMProvider interface {
	NewVM() VM
}
//fabric/core/contaner/dockercontroller/dockercontroller.go  docker
// NewVM creates a new DockerVM instance
func (p *Provider) NewVM() container.VM {
	return NewDockerVM(p.PeerID, p.NetworkID, p.BuildMetrics)
}
//fabric/core/contaner/dockercontroller/inproccontroller.go     sys
// NewVM creates an inproc VM instance
func (r *Registry) NewVM() container.VM {
	return NewInprocVM(r)
}

```

我们关心用户链码的启动，我们直接看Dockercontroller,
func (vm *DockerVM) Start(ccid ccintf.CCID, args, env []string, filesToUpload map[string][]byte, builder container.Builder)其实就是docker cleint向docker server请求启动容器的具体过程了
fabric/core/contaner/dockercontroller/dockercontroller.go  
```go
// Start starts a container using a previously created docker image
func (vm *DockerVM) Start(ccid ccintf.CCID, args, env []string, filesToUpload map[string][]byte, builder container.Builder) error {
	imageName, err := vm.GetVMNameForDocker(ccid)
	if err != nil {
		return err
	}
	containerName := vm.GetVMName(ccid)
	logger := dockerLogger.With("imageName", imageName, "containerName", containerName)
	//获取docker client
	client, err := vm.getClientFnc()
	...
	vm.stopInternal(client, containerName, 0, false, false)
	...
	err = vm.createContainer(client, imageName, containerName, args, env, attachStdout)
	...
	// upload specified files to the container before starting it
	// this can be used for configurations such as TLS key and certs
	if len(filesToUpload) != 0 {
		// the docker upload API takes a tar file, so we need to first
		// consolidate the file entries to a tar
		payload := bytes.NewBuffer(nil)
		gw := gzip.NewWriter(payload)
		tw := tar.NewWriter(gw)

		for path, fileToUpload := range filesToUpload {
			cutil.WriteBytesToPackage(path, fileToUpload, tw)
		}

		// Write the tar file out
		if err := tw.Close(); err != nil {
			return fmt.Errorf("Error writing files to upload to Docker instance into a temporary tar blob: %s", err)
		}

		gw.Close()
		...
		err := client.UploadToContainer(containerName, docker.UploadToContainerOptions{
			InputStream:          bytes.NewReader(payload.Bytes()),
			Path:                 "/",
			NoOverwriteDirNonDir: false,
		})
		if err != nil {
			return fmt.Errorf("Error uploading files to the container instance %s: %s", containerName, err)
		}
	}

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

可以再看下getDockerClient  
fabric/core/chaincode/container_runtime.go
```go
func getDockerClient() (dockerClient, error) {
	return cutil.NewDockerClient()
}
```
读取peer关于链码容器的配置，构建docker客户端   
fabric/core/container/util/dokcerutil.go  
```go
func NewDockerClient() (client *docker.Client, err error) {
	endpoint := viper.GetString("vm.endpoint")
	tlsenabled := viper.GetBool("vm.docker.tls.enabled")
	if tlsenabled {
		cert := config.GetPath("vm.docker.tls.cert.file")
		key := config.GetPath("vm.docker.tls.key.file")
		ca := config.GetPath("vm.docker.tls.ca.file")
		client, err = docker.NewTLSClient(endpoint, cert, key, ca)
	} else {
		client, err = docker.NewClient(endpoint)
	}
	return
}
```


至此，Peer chaincode instantiate服务端链码启动的过程我们也分析完了。这里我们主要对lscc invoke启动链码容器的过程进行了分析，并没有对lscc完整的交易流程分析，但是交易流程分析也大体是这个过程，不再描述。
