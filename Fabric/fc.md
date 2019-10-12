### fc

1. chaincode被部署后是作为客户端向peer建立链接的。  peer.address用于此。  



CGO_CFLAGS=" " go build -tags "" -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=1.2.1 -X github.com/hyperledger/fabric/common/metadata.CommitSHA=aabf3a632 -X github.com/hyperledger/fabric/common/metadata.BaseVersion=0.4.10 -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger -X github.com/hyperledger/fabric/common/metadata.Experimental=false" github.com/hyperledger/fabric/peer



peer  chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}' --logging-level info


peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc  --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 -c '{"Args":["invoke","a","b","20"]}' 

peer chaincode install -n mycc2 -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd
peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n mycc1 -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "AND ('Org1MSP.peer','Org2MSP.peer')"


peer/chaincode/common.go



launching chaincode!
execute proposal!!!!!!!!!!!!!!!!!!!!!!!!!!!!






aaaa
pb.ChaincodeInvocationSpec
launching chaincode!
launching chaincode!



```go
 37 // server is used to implement helloworld.GreeterServer.
 38 type server struct{}
 39 
 40 // SayHello implements helloworld.GreeterServer
 41 func (s *server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
 42     log.Printf("Received: %v", in.Name)
 43     return &pb.HelloReply{Message: "Hello " + in.Name}, nil
 44 }
 45 func (s *server) SayHelloAgain(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
 46     log.Printf("Received: %v", in.Name)
 47     return &pb.HelloReply{Message: "Hello again " + in.Name}, nil
 48 }
 49 
 50 func main() {
 51     lis, err := net.Listen("tcp", port)
 52     if err != nil {
 53         log.Fatalf("failed to listen: %v", err)
 54     }
 55     s := grpc.NewServer()
 56     pb.RegisterGreeterServer(s, &server{})
 57     if err := s.Serve(lis); err != nil {
 58         log.Fatalf("failed to serve: %v", err)
 59     }
 60 }
 ```


要改的代码在这里 chaincode_support.og  214
 ```go
 / Invoke will invoke chaincode and return the message containing the response.
// The chaincode will be launched if it is not already running.
func (cs *ChaincodeSupport) Invoke(ctxt context.Context, cccid *ccprovider.CCContext, spec ccprovider.ChaincodeSpecGetter) (*pb.ChaincodeMessage, error) {
	var cctyp pb.ChaincodeMessage_Type
	switch spec.(type) {
	case *pb.ChaincodeDeploymentSpec:
		cctyp = pb.ChaincodeMessage_INIT
	case *pb.ChaincodeInvocationSpec:
		cctyp = pb.ChaincodeMessage_TRANSACTION
	default:
		return nil, errors.New("a deployment or invocation spec is required")
	}

	chaincodeSpec := spec.GetChaincodeSpec()
	if chaincodeSpec == nil {
		return nil, errors.New("chaincode spec is nil")
	}

	//在这启动的吧
	fmt.Println("chaincode_support,launch\n\n\n\n\n\n\n" )
	err := cs.Launch(ctxt, cccid, spec)
	//所以也可以利用该方式关闭链码
	if err != nil {
		return nil, err
	}

	input := chaincodeSpec.Input
	input.Decorations = cccid.ProposalDecorations
	ccMsg, err := createCCMessage(cctyp, cccid.ChainID, cccid.TxID, input)
	if err != nil {
		return nil, errors.WithMessage(err, "failed to create chaincode message")
	}

	return cs.execute(ctxt, cccid, ccMsg)
}
 ```



1. 完成任务，所站用的cpu时间
 时间统计办法；  

 长时间的可以用docker top统计，在一段时间内容占用的所有cpu时间  

 短暂的统计


2. 客户端完成invoke/query完成的时间

这个用time就可以完成


docker ps --format "table {{.ID}}\t {{.Names}}"


docker ps --format "table {{.ID}}\t {{.Names}}" -f="name=cli"

SF

query
1次

real	0m1.482s
user	0m0.060s
sys	    0m0.030s

查询10次的时间

real	0m23.351s
user	0m0.670s
sys	0m0.280s

50 

real	2m7.775s
user	0m4.040s
sys	0m1.350s

100次

real	3m59.374s
user	0m7.020s
sys	0m2.730s





invoke 1times

real	0m3.904s
user	0m0.060s
sys	0m0.060s

10times:

real	0m56.517s
user	0m1.090s
sys	0m0.640s


50times:  



real	4m12.917s
user	0m4.720s
sys	0m2.090s

100times:

real	8m12.788s
user	0m8.170s
sys	0m3.110s


-----------
query 1

real	0m0.234s
user	0m0.040s
sys	0m0.060s

query 10 

real	0m1.939s
user	0m0.750s
sys	0m0.280s

query 50 

real	0m12.350s
user	0m3.490s
sys	0m1.640s


query 100

real	0m22.018s
user	0m7.840s
sys	0m3.500s

invoke 1

real	0m0.250s
user	0m0.080s
sys	0m0.030s

invoke 10

real	0m3.674s
user	0m0.820s
sys	0m1.340s

invoke 50

real	0m15.579s
user	0m4.200s
sys	0m1.980s

invoke 100

real	0m34.681s
user	0m8.800s
sys	0m5.790s




----


cscc：configuration system chaincode
lscc：lifecycle system chaincode
escc：endorser system chaincode
vscc：validator system chaincode
qscc：querier system chaincode