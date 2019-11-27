### 构建本地私有仓库以及通过Docker客户端交互

本文主要讲述，如何构建私有仓库，如何使用私有仓库，如何通过docker http接口和私有仓库交互，如何通过docker go客户端和私有仓库交互。


#### 第一步构建私有仓库

有较多的内容讲述这部分内容，不再赘述，详细见   
[私有仓库· Docker —— 从入门到实践 - yeasy](https://yeasy.gitbooks.io/docker_practice/repository/registry.html)   
[docker私有仓库搭建与使用实战](https://blog.csdn.net/boling_cavalry/article/details/78818462)


```bash
docker run --name registry -d -p 5000:5000 registry
```

#### 测试

测试方案，将一个镜像推送到私有仓库上，把本地镜像删除，然后再通过私有仓库拉取镜像

1. 选取一个本地一个镜像打上私有仓库地址的tag
```bash
➜  ~ docker pull nginx:1.11
1.11: Pulling from library/nginx
6d827a3ef358: Pull complete
f8f2e0556751: Pull complete
5c9972dca3fd: Pull complete
451b9524cb06: Pull complete
Digest: sha256:e6693c20186f837fc393390135d8a598a96a833917917789d63766cab6c59582
Status: Downloaded newer image for nginx:1.11
docker.io/library/nginx:1.11
➜  ~

```

将一个本地镜像推送到私有仓库
```bash
➜  ~ docker images
REPOSITORY                              TAG                              IMAGE ID            CREATED             SIZE
hyperledger/fabric-peer                 amd64-1.4.2-snapshot-c6cc550cb   137a46c497bf        3 weeks ago         179MB
➜  ~ docker tag hyperledger/fabric-peer registry:5000/hyperledger/fabric-peer
➜  ~ docker push registry:5000/hyperledger/fabric-peer
The push refers to repository [registry:5000/hyperledger/fabric-peer]
9f603ce25449: Layer already exists
b7cc5a6087af: Layer already exists
7f1d0137606c: Layer already exists
2bf772ac5a1f: Layer already exists
5ab07637602d: Layer already exists
297fd071ca2f: Layer already exists
2f0d1e8214b2: Layer already exists
7dd604ffa87f: Layer already exists
aa54c2bc1229: Layer already exists
latest: digest: sha256:aedf61525cffc15ef67f6f5cf439230201838400945ce5ae03e2eff0f4c832f6 size: 2198

➜  ~ docker images |grep nginx
nginx                                   1.11                             5766334bdaa0        2 years ago         183MB
➜  ~

将nginx:1.11打上私有仓库的地址
```bash
➜  ~ docker tag nginx:1.11 registry:5000/nginx:1.11
➜  ~ docker images |grep ngnix
➜  ~ docker images |grep nginx
registry:5000/nginx                     1.11                             5766334bdaa0        2 years ago         183MB
nginx                                   1.11                             5766334bdaa0        2 years ago         183MB
```

将registry:500/nginx:1.11推送到私有仓库

```bash
➜  ~ docker push registry:5000/nginx:1.11
The push refers to repository [registry:5000/nginx]
97b903fe0f6f: Pushed
31fc28b38091: Pushed
aca7b1f22e02: Pushed
5d6cbe0dbcf9: Pushed
1.11: digest: sha256:1deff3ebc773b5d89d20f232994fc81a355d13adac20f28cfde661099e3be8a8 size: 1156
```

删除本地registry:500/nginx:1.11镜像，从私有仓库重新拉取该镜像
```bash
➜  ~ docker rmi registry:5000/nginx:1.11
Untagged: registry:5000/nginx:1.11
Untagged: registry:5000/nginx@sha256:1deff3ebc773b5d89d20f232994fc81a355d13adac20f28cfde661099e3be8a8
➜  ~ docker pull registry:5000/nginx:1.11
1.11: Pulling from nginx
Digest: sha256:1deff3ebc773b5d89d20f232994fc81a355d13adac20f28cfde661099e3be8a8
Status: Downloaded newer image for registry:5000/nginx:1.11
registry:5000/nginx:1.11
➜  ~ docker images |grep nginx
nginx                                   1.11                             5766334bdaa0        2 years ago         183MB
registry:5000/nginx                     1.11                             5766334bdaa0        2 years ago         183MB
```




#### 使用Docker http接口测试

查看本地镜像
```bash
➜  ~ curl --unix-socket /var/run/docker.sock\
  GET "http:/v1.24/images/json?digests=1"

{"message":"page not found"}
......
"RepoTags":["nginx:1.11","registry:5000/nginx:1.11"],"SharedSize":-1,"Size":182526651,"VirtualSize":182526651}]
➜  ~
```


将本地镜像打上私有仓库镜像，并指定为latest版本，打tag
```bash
➜  ~ curl --unix-socket /var/run/docker.sock  -X POST "http:/v1.23/images/nginx:1.11/tag?repo="registry:5000/nginx":latest&force=0"

➜  ~ docker images |grep nginx
nginx                                   1.11                             5766334bdaa0        2 years ago         183MB
registry:5000/nginx                     1.11                             5766334bdaa0        2 years ago         183MB
registry:5000/nginx                     latest                           5766334bdaa0        2 years ago         183MB
```

将registry:5000/nginx:latest推送到私有仓库

```bash
➜  ~ curl --unix-socket /var/run/docker.sock  -X POST "http:/v1.24/images/registry:5000/nginx:latest/push?registry=127.0.0.1:5000"  -H X-Registry-Auth:{}
{"status":"The push refers to repository [registry:5000/nginx]"}
{"status":"Preparing","progressDetail":{},"id":"97b903fe0f6f"}
{"status":"Preparing","progressDetail":{},"id":"31fc28b38091"}
{"status":"Preparing","progressDetail":{},"id":"aca7b1f22e02"}
{"status":"Preparing","progressDetail":{},"id":"5d6cbe0dbcf9"}
{"status":"Layer already exists","progressDetail":{},"id":"aca7b1f22e02"}
{"status":"Layer already exists","progressDetail":{},"id":"31fc28b38091"}
{"status":"Layer already exists","progressDetail":{},"id":"97b903fe0f6f"}
{"status":"Layer already exists","progressDetail":{},"id":"5d6cbe0dbcf9"}
{"status":"latest: digest: sha256:1deff3ebc773b5d89d20f232994fc81a355d13adac20f28cfde661099e3be8a8 size: 1156"}
{"progressDetail":{},"aux":{"Tag":"latest","Digest":"sha256:1deff3ebc773b5d89d20f232994fc81a355d13adac20f28cfde661099e3be8a8","Size":1156}}
➜  ~
```
补充：
```bash
//向私有仓库推送本地构建的镜像,没有设置仓库权限，将X-Registry-Auth设置为空即可
curl --unix-socket /var/run/docker.sock  -X POST "http:/v1.24/images/registry:5000/nginx:1.12/push?registry=127.0.0.1:5000"  -H X-Registry-Auth:{}
或者
curl --unix-socket /var/run/docker.sock  -X POST "http:/v1.24/images/registry:5000/nginx/push?registry=127.0.0.1:5000&tag=1.12"  -H X-Registry-Auth:{}
//或者,base64加密了{}，e30K={}
curl --unix-socket /var/run/docker.sock  -X POST "http:/v1.24/images/registry:5000/nginx/push?registry=127.0.0.1:5000&tag=1.12"  -H X-Registry-Auth:e30K
```


查看私有仓库中的镜像
//获取镜像仓库中的镜像
```bash
➜  ~ curl -X GET "http://registry:5000/v2/_catalog"
{"repositories":["hyperledger/fabric-peer","nginx","test"]}
```


#### 使用fsouza/go-dockerclient客户端类似



```go
package main

import (
	"bytes"
	"fmt"
	docker "github.com/fsouza/go-dockerclient"
)
func main(){
	client,err:=docker.NewClient("unix:///var/run/docker.sock")
	if err!=nil{
		fmt.Println(err)
		return
	}
	fmt.Println("----- image list -----")
	opts:=docker.ListImagesOptions{
		Filters: nil,
		All:     true,
		Digests: false,
		Filter:  "",
		Context: nil,
	}
	images,err:=client.ListImages(opts)
	if err!=nil{
		fmt.Println(err)
	}else{
		for a,b:=range images{
			fmt.Println(a,b)
		}
	}
	fmt.Println("----- tag -----")
	tagopts:=docker.TagImageOptions{
		Repo:    "registry:5000/nginx", //镜像名
		Tag:     "1.12", //标签
		Force:   false,
		Context: nil,
	}
	err=client.TagImage("nginx:1.12",tagopts)
	if err!=nil{
		fmt.Println(err)
		return
	}
	fmt.Println("----- push -----")
	outputbuf := bytes.NewBuffer(nil)
	pOpts:=docker.PushImageOptions{
		Name:              "registry:5000/nginx", //镜像名字，name前必须指定仓库名字，registry:5000/
		Tag:               "1.12",  //镜像tag
		Registry:          "127.0.0.1:5000", //仓库地址
		OutputStream:      outputbuf,
		RawJSONStream:     false,
		InactivityTimeout: 0,
		Context:           nil,
	}
	//auth没开，用空
	err=client.PushImage(pOpts,docker.AuthConfiguration{})
	if err!=nil{
		fmt.Println(err)
	}else{
		fmt.Println(outputbuf.String())
	}
}
```

测试,测试环境mac,goland
```bash
GOROOT=/usr/local/go #gosetup
GOPATH=/Users/liu/work/go #gosetup
/usr/local/go/bin/go build -o /private/var/folders/hf/lwx68wgn4cb40d25cgq7z7f80000gn/T/___go_build_github_com_hyperledger_fabric_core_container_k8scontroller_k8sclient github.com/hyperledger/fabric/core/container/k8scontroller/k8sclient #gosetup
/private/var/folders/hf/lwx68wgn4cb40d25cgq7z7f80000gn/T/___go_build_github_com_hyperledger_fabric_core_container_k8scontroller_k8sclient #gosetup
----- image list -----
0 {sha256:137a46c497bf779941702868ac194742018ae8dbc76e29a03129322740d4e7b8 [registry:5000/hyperledger/fabric-peer:latest] 1572399551 178525678 178525678  [registry:5000/hyperledger/fabric-peer@sha256:aedf61525cffc15ef67f6f5cf439230201838400945ce5ae03e2eff0f4c832f6] map[org.hyperledger.fabric.version:1.4.2 org.hyperledger.fabric.base.version:0.4.15]}
1 {sha256:a1caeace2c5c23fa5665f7b5f9451647e6b5e9b946a826acc9d62ecebf036f09 [hyperledger/fabric-tools:amd64-1.4.2-snapshot-c6cc550cb hyperledger/fabric-tools:amd64-latest hyperledger/fabric-tools:latest] 1572352789 1547708397 1547708397 sha256:ec2224d9cf3a048cf6bb0db1caccff67a3ffeb951962c2cb43671cdcdd874988 [] map[org.hyperledger.fabric.version:1.4.2 org.hyperledger.fabric.base.version:0.4.15]}
2 {sha256:ec2224d9cf3a048cf6bb0db1caccff67a3ffeb951962c2cb43671cdcdd874988 [<none>:<none>] 1572352789 1547708397 1547708397 sha256:ff3ca1d73c99eea190116b9c13436e0b076ef82997132a87b3fdf0ea987e7e8d [<none>@<none>] map[]}
3 {sha256:ff3ca1d73c99eea190116b9c13436e0b076ef82997132a87b3fdf0ea987e7e8d [<none>:<none>] 1572352788 1547633517 1547633517 sha256:a46a9191998c6cd73e1eb07b12e1cf054b3d5852e7cb6021a588c3cf6b26241f [<none>@<none>] map[]}
4 {sha256:ef0aacac7c0261726f9ad2bdf2fcca44d2983579ddb612be9401b39bd9178f78 [<none>:<none>] 1572352785 1418537085 1418537085 sha256:ae78d89527e529518f1b127ab0fc4f565f6f06eabb24e72c79e5ae8266a8205d [<none>@<none>] map[]}
5 {sha256:a46a9191998c6cd73e1eb07b12e1cf054b3d5852e7cb6021a588c3cf6b26241f [<none>:<none>] 1572352785 1418537085 1418537085 sha256:ef0aacac7c0261726f9ad2bdf2fcca44d2983579ddb612be9401b39bd9178f78 [<none>@<none>] map[]}
6 {sha256:ae78d89527e529518f1b127ab0fc4f565f6f06eabb24e72c79e5ae8266a8205d [<none>:<none>] 1572351882 1390320087 1390320087 sha256:c4c532c23a507db7fb745cd6e701190274a3449a22caddd6d9cf5f74b193f8bf [<none>@<none>] map[]}
7 {sha256:aece9f23c3b3aa18c747b14cd391749a3f26e5a40adf5fdc5c8404917c4a789c [hyperledger/fabric-baseimage:amd64-0.4.16 hyperledger/fabric-baseimage:latest] 1570189195 1285228485 1285228485  [hyperledger/fabric-baseimage@sha256:45955489461e6c14ff4556462a2967f1c4dec5fe05e5d90bbb2682ec0b2b1d95] map[]}
8 {sha256:f711d456dcc4b5a6e0187f5c3d1428feca26ec8f676f9e5d968375cb4d2c9b47 [hyperledger/fabric-baseos:amd64-0.4.16] 1570186956 80834955 80834955  [hyperledger/fabric-baseos@sha256:80639554c03b7362e9a0895557f3e2323917ef1ec80b78caa48d71402c78de8d] map[]}
9 {sha256:ed8adf767eeb15423c6f27849f621415b8bcea2635a92f7eb86e0d7f6b47656e [k8s.gcr.io/kube-proxy:v1.14.6] 1566214016 82106236 82106236  [] map[]}
10 {sha256:0e422c9884cfe4d3772e30a89842f3673e00e2fd585331869238bcedd6d57698 [k8s.gcr.io/kube-apiserver:v1.14.6] 1566214011 209433406 209433406  [] map[]}
11 {sha256:4bb274b1f2c3bbe336b33e74bf73929c50df527fcbd8fff679d322d6283f2342 [k8s.gcr.io/kube-controller-manager:v1.14.6] 1566214009 157458462 157458462  [] map[]}
12 {sha256:d27987bc993e30f8bd2bd1e8d4c9ea319014b18690b89ed852d212ab0dd54f83 [k8s.gcr.io/kube-scheduler:v1.14.6] 1566214009 81579742 81579742  [] map[]}
13 {sha256:1cd707531ce75329f1416f89869c91c8279fba528be97756623b0dd01abd85d3 [hyperledger/fabric-javaenv:1.4.2 hyperledger/fabric-javaenv:latest] 1563478007 1759987613 1759987613  [hyperledger/fabric-javaenv@sha256:b3cc1042b7b08607f2d781e036251cf3a5151b99e3d7aba8bf404ff94b2ec68e] map[]}
14 {sha256:f289675c98744ef4a8f504f5b82d1a0d26b61ee246441ee5096bb756052d54b4 [hyperledger/fabric-ca:1.4.2 hyperledger/fabric-ca:latest] 1563397291 252718505 252718505  [hyperledger/fabric-ca@sha256:6c89ec2b27849c02f71479742c79bf33260984ad391f39dd3fe25fc7adb535d0] map[]}
15 {sha256:0abc124a9400ea7d39031691d7fdcbbb7847ca1ee2cc04debd2da8ac7606845f [hyperledger/fabric-tools:1.4.2] 1563397081 1547304089 1547304089  [hyperledger/fabric-tools@sha256:a5c377e8587d4543685b474637ab1d4aed86988b893e5f176032129b620b6bf2] map[org.hyperledger.fabric.base.version:0.4.15 org.hyperledger.fabric.version:1.4.2]}
16 {sha256:fc0f502399a6cb6a84e6abc4e005044961341dd4bfb525f5cfa4b4ca4831bc97 [hyperledger/fabric-ccenv:1.4.2 hyperledger/fabric-ccenv:latest] 1563396930 1427806882 1427806882  [hyperledger/fabric-ccenv@sha256:9f047d427357350885f5dbc7f042c5fd52694ca74e6cf028faeae923ae7c9190] map[org.hyperledger.fabric.base.version:0.4.15 org.hyperledger.fabric.version:1.4.2]}
17 {sha256:3620219980030942b9231c389cf2b16f0e71ab8d94345713e29e0cd64d7e7095 [hyperledger/fabric-orderer:1.4.2 hyperledger/fabric-orderer:latest] 1563396884 172889206 172889206  [hyperledger/fabric-orderer@sha256:b07975809591de3c93d37f3d7a06406c1ce4cb775c322c2352513a253830bc36] map[org.hyperledger.fabric.base.version:0.4.15 org.hyperledger.fabric.version:1.4.2]}
18 {sha256:d79f2f4f3257fbab60006ae4e414c480abd022b08d1e1f66d072360c0f90aa59 [hyperledger/fabric-peer:1.4.2] 1563396862 178478462 178478462  [hyperledger/fabric-peer@sha256:b0f529295f9e970b18263671f2188f62f3bac9026747bfc8d0e9a605e91ff001] map[org.hyperledger.fabric.version:1.4.2 org.hyperledger.fabric.base.version:0.4.15]}
19 {sha256:a8c3d87a58e7710b2cf1a427d36b950478cfab17ad47561a8fe4ce3b2d814b85 [docker/kube-compose-controller:v0.4.23] 1559738193 35271598 35271598  [docker/kube-compose-controller@sha256:e15dad3aa71c0051e64831b145680f76f261f433bc6fc49987c45e43e039960b] map[]}
20 {sha256:f3591b2cb223941defc7083da460d210a16fbdae55f27d76619a6940ce2fca32 [docker/kube-compose-api-server:v0.4.23] 1559738188 49939182 49939182  [docker/kube-compose-api-server@sha256:035e674c761c8a9bffe25a4f7c552e617869d1c1bfb2f84074c3ee63f3018da4] map[]}
21 {sha256:20c6045930c851d1cbc22b41cebc18cb61c4f7077443c1cbd345f9394c8d6154 [hyperledger/fabric-zookeeper:0.4.15 hyperledger/fabric-zookeeper:latest] 1552943068 1434104006 1434104006  [hyperledger/fabric-zookeeper@sha256:180553e88d09167370aa62a41587a9a95b819b981ad74cad218689412b85f130] map[.base.version:amd64-0.4.15 .version:]}
22 {sha256:b4ab82bbaf2f5e777246a1d2762ddef57671cd9c932c0ebdf2be3e2449e23d7b [hyperledger/fabric-kafka:0.4.15 hyperledger/fabric-kafka:latest] 1552943042 1444120296 1444120296  [hyperledger/fabric-kafka@sha256:62418a885c291830510379d9eb09fbdd3d397052d916ed877a468b0e2026b9e3] map[.base.version:amd64-0.4.15 .version:]}
23 {sha256:8de128a5553958b9fcc8dca8d4253ad91ab490c8bb76647e35aca59f84c56d3f [hyperledger/fabric-couchdb:0.4.15 hyperledger/fabric-couchdb:latest] 1552943031 1497238982 1497238982  [hyperledger/fabric-couchdb@sha256:f6c724592abf9c2b35d2f4cd6a7afcde9c1052cfed61560b20ef9e2e927d1790] map[.base.version:amd64-0.4.15 .version:]}
24 {sha256:c4c532c23a507db7fb745cd6e701190274a3449a22caddd6d9cf5f74b193f8bf [hyperledger/fabric-baseimage:amd64-0.4.15] 1552942644 1390320087 1390320087  [hyperledger/fabric-baseimage@sha256:1570a4c4dbb5f1aeeef5125af5d9ed2b5b90a464718d76b48bf79c08e479ea71] map[]}
25 {sha256:9d6ec11c60ffa450b293ff604dc459d283df5e4869a105825ddaf03f8d9a421e [hyperledger/fabric-baseos:amd64-0.4.15] 1552941184 144741798 144741798  [hyperledger/fabric-baseos@sha256:a1281185d8e624930b634dfdb0fc3f63b369db79154d054d9da61abbc39c1dde] map[]}
26 {sha256:f32a97de94e13d29835a19851acd6cbc7979d1d50f703725541e44bb89a1ce91 [registry:latest] 1552013199 25779561 25779561  [registry@sha256:8004747f1e8cd820a148fb7499d71a76d45ff66bac6a29129bfdbfdc0154d146] map[]}
27 {sha256:eb516548c180f8a6e0235034ccee2428027896af16a509786da13022fe95fe8c [k8s.gcr.io/coredns:1.3.1] 1547391212 40303560 40303560  [] map[]}
28 {sha256:2c4adeb21b4ff8ed3309d0e42b6b4ae39872399f7b37e0856e673b13c4aba13d [k8s.gcr.io/etcd:3.3.10] 1543604850 258116302 258116302  [] map[]}
29 {sha256:4037a5562b030fd80ec889bb885405587a52cfef898ffb7402649005dfda75ff [nginx:1.12 registry:5000/nginx:1.12] 1525096632 108382637 108382637  [nginx@sha256:72daaf46f11cc753c4eab981cbf869919bd1fee3d2170a2adeac12400f494728] map[maintainer:NGINX Docker Maintainers <docker-maint@nginx.com>]}
30 {sha256:ae513a47849c895a155ddfb868d6ba247f60240ec8495482eca74c4a2c13a881 [test:1.2 registry:5000/test:1.2] 1525096545 108958610 108958610  [registry:5000/nginx@sha256:e4f0474a75c510f40b37b6b7dc2516241ffa8bde5a442bde3d372c9519c84d90 registry:5000/test@sha256:e4f0474a75c510f40b37b6b7dc2516241ffa8bde5a442bde3d372c9519c84d90] map[maintainer:NGINX Docker Maintainers <docker-maint@nginx.com>]}
31 {sha256:da86e6ba6ca197bf6bc5e9d900febd906b133eaa4750e6bed647b0fbe50ed43e [k8s.gcr.io/pause:3.1] 1513805449 742472 742472  [] map[]}
32 {sha256:5766334bdaa0bc37f1f0c02cb94c351f9b076bcffa042d6ce811b0fd9bc31f3b [nginx:1.11 registry:5000/nginx:1.11 registry:5000/nginx:latest] 1491496131 182526651 182526651  [nginx@sha256:e6693c20186f837fc393390135d8a598a96a833917917789d63766cab6c59582 registry:5000/nginx@sha256:1deff3ebc773b5d89d20f232994fc81a355d13adac20f28cfde661099e3be8a8] map[]}
----- tag -----
----- push -----
The push refers to repository [registry:5000/nginx]
4258832b2570: Preparing
683a28d1d7fd: Preparing
d626a8ad97a1: Preparing
d626a8ad97a1: Layer already exists
4258832b2570: Pushed
683a28d1d7fd: Pushed
1.12: digest: sha256:09e210fe1e7f54647344d278a8d0dee8a4f59f275b72280e8b5a7c18c560057f size: 948


Process finished with exit code 0

```