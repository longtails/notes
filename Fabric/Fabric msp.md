## msp.mgmt

MSP memebership service provider

包内变量msp.MSP，通过LoadLocalMsp()创建，mspType通过```peer.localMspType```参数配置

可配置的类型:bccsp和idemix   
```go
//目前支持的msp ,默认配置bccspMSP
// The ProviderType of a member relative to the member API
const (
	FABRIC ProviderType = iota // MSP is of FABRIC type
	IDEMIX                     // MSP is of IDEMIX type
	OTHER                      // MSP is of OTHER TYPE

	// NOTE: as new types are added to this set,
	// the mspTypes array below must be extended
)

var mspTypeStrings []string = []string{"bccsp", "idemix"}
```

新建MSP会读取配置一系列的证书和签名文件，并验证成员的成员的身份。

通过证书链，验证证书

->具体验证过程分析






