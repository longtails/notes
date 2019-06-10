#### peer源码分析1-chaincode

这部分，主要分析链码安装到实例化（启动容器）的过程。操作链码是通过```peer chaincode```命令进行的，这就是我们所谓的一个命令行的客户端，通过它我们就可以和fabric交互，注意Peer服务是通过```peer node start```启动的，即启动一个peer节点。  

以下是从e2e_cli/scripts/scripts.sh提取的安装、实例化链码的命令，注意该命令前，要先完成创建通道和加入通道。
```bash
peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd >&log.txt
peer chaincode instantiate -o orderer.example.com:7050 -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "AND ('O    rg1MSP.peer','Org2MSP.peer')" >&log.txt

```

#### cobra:一个用来实现cli的golang package

在阅读Fabric源码前，我们要对go package cobra有个基本的了解，这是一个命令行封装包，能够很方便的实现命令行，但是它的存在，对我们要分析的核心代码，进行了多层封装，又有Fabric的本地调试问题，无法很好的分析数据流，所以这是一个困扰，但熟悉之后会好很多。另外，Fabric使用大量的桩函数，包装函数，对我们分析源码也会造成一定的难度。

[Cobra官方地址](https://github.com/spf13/cobra),通过一个小demo，来了解cobra的基本内容。


先看下，cobra的demo,cobra初始化会创建cmd和main.go，我们在cobrademo下创建开发包simple,之后在cmd/root.go中导入，并做适当修改即可。
```bash
liudeMacBook-Pro:cobrademo liu$ cobra init cobrademo
Your Cobra application is ready at
/Users/liu/work/go/src/cobrademo

Give it a try by going there and running `go run main.go`.

liudeMacBook-Pro:src liu$ tree -L 2 cobrademo/
cobrademo/
├── LICENSE
├── cmd
│   └── root.go
├── main.go
└── simple
    └── show.go

2 directories, 4 files

```
在main.go只有一个命令行的执行操作，cmd是准备工作.
```bash
func main() {
	cmd.Execute()
}
```
simple是我们的开发包，创建了一个show函数，后边在cmd中绑定到命令行。
```bash
liudeMacBook-Pro:cobrademo liu$ cat simple/show.go 
package simple
import "fmt"
func Show(name string, age int) {
	fmt.Printf("My name is %s, my age is %d\n", name, age)
}
```
在cmd/root.go中创建了一个cobra.Command对象，我们的开发的show函数就绑定到这个对象的Run成员中。
```bash
var name string
var age int

var rootCmd = &cobra.Command{
	Use:   "cobrademo",
	Short: "A brief description of your application",
	Long: `A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	// Uncomment the following line if your bare application
	// has an action associated with it:
	//	Run: func(cmd *cobra.Command, args []string) { },
	Run: func(cmd *cobra.Command, args []string) {
		if len(name) == 0 {
			cmd.Help()
			return
		}
		simple.Show(name, age)
	},
}
```
之后，在通过设置Flags,就可以解析命令行参数，调用对应的函数。
```bash
rootCmd.Flags().StringVarP(&name, "name", "n", "", "persion's name")
rootCmd.Flags().IntVarP(&age, "age", "a", 0, "person's age")
```
在绑定函数，设置好参数Flags，通过```cmd.Execute()```进入了执行阶段，解析命令行参数，执行对应函数。
```bash
liudeMacBook-Pro:cobrademo liu$ go run main.go 
A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.

Usage:
  cobrademo [flags]

Flags:
  -a, --age int       person's age
  -h, --help          help for cobrademo
  -n, --name string   persion's name
liudeMacBook-Pro:cobrademo liu$ go run main.go -a 10 -n test
My name is test, my age is 10
liudeMacBook-Pro:cobrademo liu$ 
```

**注意：** cobra还可以通过AddCommand添加子命令，这个我们会经常遇到,例如peer/main.go中，添加各子命令。
```go
//添加子命令
mainCmd.AddCommand(version.Cmd())
mainCmd.AddCommand(node.Cmd())
mainCmd.AddCommand(chaincode.Cmd(nil))
mainCmd.AddCommand(clilogging.Cmd(nil))
mainCmd.AddCommand(channel.Cmd(nil))
```

#### peer chaincode源码分析（install & instantiate）

同时，阅读fabric/peer/chaincode源码，这部分是peer chaincode命令部分（**客户端部分**），安装链码在install.go及测试install_test.go，实例化链码在instantiate.go和instantiate_test.go。

```bash
liudeMacBook-Pro:chaincode liu$ pwd
/Users/liu/work/go/src/github.com/hyperledger/fabric/peer/chaincode
liudeMacBook-Pro:chaincode liu$ ls
api                 common_test.go      install_test.go     invoke.go           list.go             nojava.go           query.go            signpackage_test.go
chaincode.go        flags_test.go       instantiate.go      invoke_test.go      list_test.go        package.go          query_test.go       upgrade.go
common.go           install.go          instantiate_test.go java.go             mock                package_test.go     signpackage.go      upgrade_test.go
liudeMacBook-Pro:chaincode liu$ 

```

还记得上述添加的子命令吗，那将是我们寻找的各个子命令的入口，这里我们找Install和Instantiate入口。
```go
// Cmd returns the cobra command for Chaincode
func Cmd(cf *ChaincodeCmdFactory) *cobra.Command {
    addFlags(chaincodeCmd)
    //install
    chaincodeCmd.AddCommand(installCmd(cf))
    //instantiate
    chaincodeCmd.AddCommand(instantiateCmd(cf))
    chaincodeCmd.AddCommand(invokeCmd(cf))
    chaincodeCmd.AddCommand(packageCmd(cf, nil))
    chaincodeCmd.AddCommand(queryCmd(cf))
    chaincodeCmd.AddCommand(signpackageCmd(cf))
    chaincodeCmd.AddCommand(upgradeCmd(cf))
    chaincodeCmd.AddCommand(listCmd(cf))
    return chaincodeCmd
}
```
我们找到installCmd,寻找入口。
```go

// installCmd returns the cobra command for Chaincode Deploy
func installCmd(cf *ChaincodeCmdFactory) *cobra.Command {
    chaincodeInstallCmd = &cobra.Command{
        Use:       "install",
        Short:     fmt.Sprint(installDesc),
        Long:      fmt.Sprint(installDesc),
        ValidArgs: []string{"1"},
        RunE: func(cmd *cobra.Command, args []string) error {
            var ccpackfile string
            if len(args) > 0 {
                ccpackfile = args[0]
            }
            //绑定的处理函数，chaincodeInstall是Install的入口
            return chaincodeInstall(cmd, ccpackfile, cf)
        },
    }
    flagList := []string{
        "lang",
        "ctor",
        "path",
        "name",
        "version",
        "peerAddresses",
        "tlsRootCertFiles",
        "connectionProfile",
    }
    attachFlags(chaincodeInstallCmd, flagList)
    return chaincodeInstallCmd
}
```
同样Instantiate入口以同样的方式找到
```go
// instantiateCmd returns the cobra command for Chaincode Deploy
func instantiateCmd(cf *ChaincodeCmdFactory) *cobra.Command {
    chaincodeInstantiateCmd = &cobra.Command{
        Use:       instantiateCmdName,
        Short:     fmt.Sprint(instantiateDesc),
        Long:      fmt.Sprint(instantiateDesc),
        ValidArgs: []string{"1"},
        RunE: func(cmd *cobra.Command, args []string) error {
            //Instantiate的入口
            return chaincodeDeploy(cmd, args, cf)
        },
    }
    flagList := []string{
        "lang",
        "ctor",
        "name",
        "channelID",
        "version",
        "policy",
        "escc",
        "vscc",
        "collections-config",
        "peerAddresses",
        "tlsRootCertFiles",
        "connectionProfile",
    }
    attachFlags(chaincodeInstantiateCmd, flagList)
    return chaincodeInstantiateCmd
}
```


**Install** :先看链码安装做了什么，这部分可以通过install_test.go的数据流辅助分析，这里直接看install.go。

入口函数chaincodeInstall:
```go
// chaincodeInstall installs the chaincode. If remoteinstall, does it via a lscc call
func chaincodeInstall(cmd *cobra.Command, ccpackfile string, cf *ChaincodeCmdFactory) error {
    ...
    var ccpackmsg proto.Message
    //获取对链码的CCD格式的数据消息
    if ccpackfile == "" {
        ...
        //读取chaincode源码文件，并打包
        //genChaincodeDeploymentSpec creates ChaincodeDeploymentSpec as the package to install
        ccpackmsg, err = genChaincodeDeploymentSpec(cmd, chaincodeName, chaincodeVersion)
        ...
    } else {
        ...
        var cds *pb.ChaincodeDeploymentSpec
        //读取链码包
        //getPackageFromFile get the chaincode package from file and the extracted ChaincodeDeploymentSpec
        ccpackmsg, cds, err = getPackageFromFile(ccpackfile)
        ...
    }
    //调用install函数
    err = install(ccpackmsg, cf)
    return err
}
```
install将打包后的链码发送给peer服务
```go
//install the depspec to "peer.address"
func install(msg proto.Message, cf *ChaincodeCmdFactory) error {
    //将签名序列化
    creator, err := cf.Signer.Serialize()

    prop, _, err := utils.CreateInstallProposalFromCDS(msg, creator)

    var signedProp *pb.SignedProposal
    signedProp, err = utils.GetSignedProposal(prop, cf.Signer)
    //ProcessProposal是peer的一个Endorser service的客户端的api（grpc连接）
    // install is currently only supported for one peer
    proposalResponse, err := cf.EndorserClients[0].ProcessProposal(context.Background(), signedProp)

    if proposalResponse != nil {
        logger.Infof("Installed remotely %v", proposalResponse)
    }

    return nil
}
```
/fabric/protos/peer/peer.pb.go

```go
// Client API for Endorser service
type EndorserClient interface {
    ProcessProposal(ctx context.Context, in *SignedProposal, opts ...grpc.CallOption) (*ProposalResponse, error)
}
```

这就结束了，我们可能纳闷，怎么结束了，chaincode最后到哪了，怎么到的？我们再看上边的grpc的那个client api ProcessProposal,最后是由它将链码文件发送到了peer service上。注意我们操作的peer chaincode是命令行客户端。

**Instantiate:** 如果留意过链码容器的启动阶段，就会知道链码容器是在实例化时启动的，同时，我们安装实例化多个链码，便也会启动多个链码容器。

入口函数chaincodeDeploy:

```go
// chaincodeDeploy instantiates the chaincode. On success, the chaincode name
// (hash) is printed to STDOUT for use by subsequent chaincode-related CLI
// commands.
func chaincodeDeploy(cmd *cobra.Command, args []string, cf *ChaincodeCmdFactory) error {
    // Parsing of the command line is done so silence cmd usage
    cmd.SilenceUsage = true
    var err error
    if cf == nil {
        cf, err = InitCmdFactory(cmd.Name(), true, true)
    }
    defer cf.BroadcastClient.Close()
    //实例化
    env, err := instantiate(cmd, cf)
    if env != nil {
        //广播通知各客户端告知实例化完成
        err = cf.BroadcastClient.Send(env)
    }
    return err
}
```
instantiate实例化部分，读取链码的ccd数据对象，和实例化
```go
//instantiate the command via Endorser
func instantiate(cmd *cobra.Command, cf *ChaincodeCmdFactory) (*protcommon.Envelope, error) {
    // getChaincodeSpec get chaincode spec from the cli cmd pramameters
    spec, err := getChaincodeSpec(cmd)
    // getChaincodeDeploymentSpec get chaincode deployment spec given the chaincode spec
    cds, err := getChaincodeDeploymentSpec(spec, false)
    creator, err := cf.Signer.Serialize()
    // CreateDeployProposalFromCDS returns a deploy proposal given a serialized identity and a ChaincodeDeploymentSpec
    prop, _, err := utils.CreateDeployProposalFromCDS(channelID, cds, creator, policyMarshalled, []byte(escc), []byte(vscc), collectionConfigBytes)
    var signedProp *pb.SignedProposal
    signedProp, err = utils.GetSignedProposal(prop, cf.Signer)

    //向peer服务发送实例化背书交易
    // instantiate is currently only supported for one peer
    proposalResponse, err := cf.EndorserClients[0].ProcessProposal(context.Background(), signedProp)
    if proposalResponse != nil {
        // assemble a signed transaction (it's an Envelope message)
        env, err := utils.CreateSignedTx(prop, cf.Signer, proposalResponse)
        return env, nil
    }
    return nil, nil
}
```


以上的Install和Instantiate均是准备链码和初始化，最后通过以交易背书的方式将安装和实例化请求发送给peer 服务端，最后有peer服务端完成链码的安装和实例化（在peer端启动容器）。

---
上述部分是peer chaincode的命令行客户端部分处理，完整的链码安装和实例化，还需要看peer服务端的处理,待续。

