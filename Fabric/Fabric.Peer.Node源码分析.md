###  Fabric.Peer.Node源码分析

start函数有400+行...

测试node下的start_test.go文件(fabric/peer/node/start_test.go)

func TestStartCmd(t *testing.T):
1. 首先设置peer的一些参数，包括peer.address,peer.listenAdderess,peer.chaincodeListenAddress,peer.fileSystemPath,chaincode.executetimeout,chaincode.mode,还有一些日志参数
2. 在启动前，获取MSP配置
3. 启动start函数，所有的逻辑都在这个400+行的函数里
4. 使用一个grpc客户端，探测了一下是否启动
```go
func TestStartCmd(t *testing.T) {
	defer viper.Reset()
	g := NewGomegaWithT(t)
	viper.Set("peer.address", "localhost:6051")
	viper.Set("peer.listenAddress", "0.0.0.0:6051")
	viper.Set("peer.chaincodeListenAddress", "0.0.0.0:6052")
	viper.Set("peer.fileSystemPath", "/tmp/hyperledger/test")
	viper.Set("chaincode.executetimeout", "30s")
	viper.Set("chaincode.mode", "dev")
    overrideLogModules := []string{"msp", "gossip", "ledger", "cauthdsl", "policies", "grpc"}
    ...
	msptesttools.LoadMSPSetupForTesting()
	go func() {
		cmd := startCmd()
		assert.NoError(t, cmd.Execute(), "expected to successfully start command")
    }()
    //启动了一个grpc客户端，探测peer 服务是否启动了
	g.Eventually(grpcProbe("localhost:6051")).Should(BeTrue())
}
//探测peer的grpc是否启动
func grpcProbe(addr string) bool {
	c, err := grpc.Dial(addr, grpc.WithBlock(), grpc.WithInsecure())
	if err == nil {
		c.Close()
		return true
	}
	return false
}
```

以下几个测试文件，主要是测试一些辅助函数，比如域名解析、配置文件解析等。

func TestAdminHasSeparateListener(t *testing.T) ,这个函数测试admin是否有单独的监听器，默认admin监听器的端口和peer 数据服务端口是一样的

```go
func TestAdminHasSeparateListener(t *testing.T) {
    //adminHasSeparateListener就是用来判断admin是否单独拥有一个监听器
	assert.False(t, adminHasSeparateListener("0.0.0.0:7051", ""))
	assert.Panics(t, func() {
		adminHasSeparateListener("foo", "blabla")
	})
	assert.Panics(t, func() {
		adminHasSeparateListener("0.0.0.0:7051", "blabla")
	})
	assert.False(t, adminHasSeparateListener("0.0.0.0:7051", "0.0.0.0:7051"))
	assert.False(t, adminHasSeparateListener("0.0.0.0:7051", "127.0.0.1:7051"))
	assert.True(t, adminHasSeparateListener("0.0.0.0:7051", "0.0.0.0:7055"))
}
```

func TestHandlerMap(t *testing.T),这是测试配置文件的分离是否正确，我们喜闻乐见的部分  

```go
func TestHandlerMap(t *testing.T) {
	config1 := `
  peer:
    handlers:
      authFilters:
        -
          name: filter1
          library: /opt/lib/filter1.so
        -
          name: filter2
    `
	viper.SetConfigType("yaml")
	err := viper.ReadConfig(bytes.NewBuffer([]byte(config1)))
	assert.NoError(t, err)

    libConf := library.Config{}
    //通过viperutil解析配置文件,viperutil是工程的组成部分，在fabric/common/viperutil/config_util.go下
    //感兴趣可以测试下
	err = viperutil.EnhancedExactUnmarshalKey("peer.handlers", &libConf)
	assert.NoError(t, err)
	assert.Len(t, libConf.AuthFilters, 2, "expected two filters")
	assert.Equal(t, "/opt/lib/filter1.so", libConf.AuthFilters[0].Library)
	assert.Equal(t, "filter2", libConf.AuthFilters[1].Name)
}
```

func TestComputeChaincodeEndpoint(t *testing.T) 测试ip地址解析功能，

computeChaincodeEndpoint(peerHostname string)读取配置的chaincodeAddrKey和chaincodeListenAddrKey，并检查配置的地址是否正确，返回ip:port,该函数的逻辑是:
1. 若设置了chaincodeAddrKey且不是0.0.0.0或::，则使用配置内容;   
2. 若未设置chaincodeAddrKey或为0.0.0.0和::,则使用peer address,同样不能是0.0.0.0或者::,则使用peer address;   
3. 若设置了chaincodeListenAddrKey且不是0.0.0.0或::,则使用配置内容;
4. 若未设置了chaincodeListenAddrKey或是0.0.0.0或::,传入的参数peerHostname进行解析;
5. 剩下的情况全不满足。

**从这个函数看，似乎在告诉我们可以将链码部署到其他节点上，而不仅只能和peer节点在一块。**这点待确认

```go
func TestComputeChaincodeEndpoint(t *testing.T) {
    /*** Scenario 1: chaincodeAddress and chaincodeListenAddress are not set ***/
    viper.Set(chaincodeAddrKey, nil)
    viper.Set(chaincodeListenAddrKey, nil)
    // Scenario 1.1: peer address is 0.0.0.0
    // computeChaincodeEndpoint will return error
    peerAddress0 := "0.0.0.0"
    ccEndpoint, err := computeChaincodeEndpoint(peerAddress0)  //ERROR，ip 不能是0.0.0.0或::
    assert.Error(t, err)
    assert.Equal(t, "", ccEndpoint)
    // Scenario 1.2: peer address is not 0.0.0.0
    // chaincodeEndpoint will be peerAddress:7052
    peerAddress := "127.0.0.1"
    ccEndpoint, err = computeChaincodeEndpoint(peerAddress)
    //正确输出 127.0.0.1:7075，使用默认端口7075
    assert.NoError(t, err)
    assert.Equal(t, peerAddress+":7052", ccEndpoint)

    /*** Scenario 2: set up chaincodeListenAddress only ***/
    // Scenario 2.1: chaincodeListenAddress is 0.0.0.0
    chaincodeListenPort := "8052"
    settingChaincodeListenAddress0 := "0.0.0.0:" + chaincodeListenPort
    viper.Set(chaincodeListenAddrKey, settingChaincodeListenAddress0)
    viper.Set(chaincodeAddrKey, nil)
    //peer address ip为0.0.0.0不可用
    // Scenario 2.1.1: peer address is 0.0.0.0
    // computeChaincodeEndpoint will return error
    ccEndpoint, err = computeChaincodeEndpoint(peerAddress0)
    assert.Error(t, err)
    assert.Equal(t, "", ccEndpoint)
    //配置不可用，使用传入的参数，解析可用。
    // Scenario 2.1.2: peer address is not 0.0.0.0
    // chaincodeEndpoint will be peerAddress:chaincodeListenPort
    ccEndpoint, err = computeChaincodeEndpoint(peerAddress)
    assert.NoError(t, err)
    assert.Equal(t, peerAddress+":"+chaincodeListenPort, ccEndpoint)
    // Scenario 2.2: chaincodeListenAddress is not 0.0.0.0
    // chaincodeEndpoint will be chaincodeListenAddress
    settingChaincodeListenAddress := "127.0.0.1:" + chaincodeListenPort
    viper.Set(chaincodeListenAddrKey, settingChaincodeListenAddress)
    viper.Set(chaincodeAddrKey, nil)
    ccEndpoint, err = computeChaincodeEndpoint(peerAddress)
    assert.NoError(t, err)
    assert.Equal(t, settingChaincodeListenAddress, ccEndpoint)
    // Scenario 2.3: chaincodeListenAddress is invalid
    // computeChaincodeEndpoint will return error
    settingChaincodeListenAddressInvalid := "abc"
    viper.Set(chaincodeListenAddrKey, settingChaincodeListenAddressInvalid)
    viper.Set(chaincodeAddrKey, nil)
    ccEndpoint, err = computeChaincodeEndpoint(peerAddress)
    assert.Error(t, err)
    assert.Equal(t, "", ccEndpoint)

    /*** Scenario 3: set up chaincodeAddress only ***/
    // Scenario 3.1: chaincodeAddress is 0.0.0.0
    // computeChaincodeEndpoint will return error
    chaincodeAddressPort := "9052"
    settingChaincodeAddress0 := "0.0.0.0:" + chaincodeAddressPort
    viper.Set(chaincodeListenAddrKey, nil)
    viper.Set(chaincodeAddrKey, settingChaincodeAddress0)
    ccEndpoint, err = computeChaincodeEndpoint(peerAddress)
    assert.Error(t, err)
    assert.Equal(t, "", ccEndpoint)
    //使用配置变量chaincodeAddress
    // Scenario 3.2: chaincodeAddress is not 0.0.0.0
    // chaincodeEndpoint will be chaincodeAddress
    settingChaincodeAddress := "127.0.0.2:" + chaincodeAddressPort
    viper.Set(chaincodeListenAddrKey, nil)
    viper.Set(chaincodeAddrKey, settingChaincodeAddress)
    ccEndpoint, err = computeChaincodeEndpoint(peerAddress)
    assert.NoError(t, err)
    assert.Equal(t, settingChaincodeAddress, ccEndpoint)
    //配置的ip不合法
    // Scenario 3.3: chaincodeAddress is invalid
    // computeChaincodeEndpoint will return error
    settingChaincodeAddressInvalid := "bcd"
    viper.Set(chaincodeListenAddrKey, nil)
    viper.Set(chaincodeAddrKey, settingChaincodeAddressInvalid)
    ccEndpoint, err = computeChaincodeEndpoint(peerAddress)
    assert.Error(t, err)
    assert.Equal(t, "", ccEndpoint)
    //同时配置两个变量
    /*** Scenario 4: set up both chaincodeAddress and chaincodeListenAddress ***/
    // This scenario will be the same to scenarios 3: set up chaincodeAddress only.
}

```

---
接下来，分析peer node start函数的具体逻辑，这里的功能逻辑就比较多了






