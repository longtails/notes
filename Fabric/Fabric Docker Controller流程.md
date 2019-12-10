### Fabric Container Controller


fabric/peer/node/start.go/registryChaincodeSupport
```go
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
            //从这看，我们实现自己的controller就要实现对应的接口，VM
			map[string]container.VMProvider{
				dockercontroller.ContainerType: dockerProvider,//实现了NewVM()接口的controller
				inproccontroller.ContainerType: ipRegistry,
			},
		),
		sccp,
		pr,
		peer.DefaultSupport,
		ops.Provider,
    )
    ...
}
```

fabric/core/container/controller.go/NewVMController
```go
// NewVMController creates a new instance of VMController
func NewVMController(vmProviders map[string]VMProvider) *VMController {
	return &VMController{
		containerLocks: make(map[string]*refCountedLock),
		vmProviders:    vmProviders,
	}
}
```
再看对应NewChaincodeSupport内容  
fabric/core/chaincode/chaincode_support.go/NewChaincodeSupport
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
	processor Processor,//这是对应VMController的入口，即使实现Processor接口
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

fabric/core/chaincode/chaincode_support.go/Process接口，就一Process内容
```go
// Processor processes vm and container requests.
type Processor interface {
	Process(vmtype string, req container.VMCReq) error
}
```

至此我们找到了不同插件的管理入口
---

接下来我们看是如何处理不同类型的Controller的，相关内容，在fabric/core/container/controller.go

```go
func (vmc *VMController) Process(vmtype string, req VMCReq) error {
	v := vmc.newVM(vmtype)//根据controller类型，获取对应的controller实例
	ccid := req.GetCCID()
	id := ccid.GetName()

	vmc.lockContainer(id)
	defer vmc.unlockContainer(id)
	return req.Do(v) //不同类型的controller都要执行Do
}
func (vmc *VMController) newVM(typ string) VM {
	v, ok := vmc.vmProviders[typ]//从map中读取，就是我们在最开始container.NewVMController()创建的
	if !ok {
		vmLogger.Panicf("Programming error: unsupported VM type: %s", typ)
	}
	return v.NewVM()//这是所有Controller都要实现的接口
}


func (si StartContainerReq) Do(v VM) error {
    //具体是执行了Start接口，其他接口不再寻找
	return v.Start(si.CCID, si.Args, si.Env, si.FilesToUpload, si.Builder)
}
```
controller要实现的接口
```go
//VM is an abstract virtual image for supporting arbitrary virual machines
type VM interface {
	Start(ccid ccintf.CCID, args []string, env []string, filesToUpload map[string][]byte, builder Builder) error
	Stop(ccid ccintf.CCID, timeout uint, dontkill bool, dontremove bool) error
	Wait(ccid ccintf.CCID) (int, error)
	HealthCheck(context.Context) error
}
```

