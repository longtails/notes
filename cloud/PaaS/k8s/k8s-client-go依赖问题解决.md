### k8s client-go依赖问题解决

#### 记一次go mod依赖版本不一致的解决过程

克隆下client-go的工程，并checkout对应kubernetes版本上，可以直接使用example中的例子，但是在自定义开发时遇到了接口不一致问题，很明显这是依赖版本问题所致。


我们使用client-go/examples/create-update-delete-deployment的例子测试

测试环境
```bash
➜  k8s go version
go version go1.11.13 darwin/amd64
➜  k8s echo $GO111MODULE
on
```

测试流程

1. 将main.go复制到$GOPATH/src/test/k8s下
2. 在test/k8s中初始化mod,go mod init
    ```bash
    ➜  k8s go mod init
    go: creating new go.mod: module test/k8s
    ➜  k8s ls
    go.mod  main.go
    ```
3. 测试go run main.go，mod会自动下载依赖(需要开启代理)

    ```bash
    ➜  k8s go run main.go
    go: finding k8s.io/client-go/kubernetes latest
    go: finding k8s.io/client-go/util/homedir latest
    go: finding k8s.io/client-go/util/retry latest
    go: finding k8s.io/client-go/tools/clientcmd latest
    go: finding k8s.io/api/core latest
    go: finding k8s.io/api/apps latest
    go: finding k8s.io/client-go/util latest
    go: finding k8s.io/client-go/tools latest
    go: finding k8s.io/api latest
    go: finding k8s.io/apimachinery/pkg/apis/meta latest
    go: finding k8s.io/apimachinery/pkg/apis latest
    go: finding k8s.io/apimachinery/pkg latest
    go: finding k8s.io/apimachinery latest
    go: finding golang.org/x/time/rate latest
    go: finding golang.org/x/time latest
    go: finding golang.org/x/oauth2 latest
    go: finding k8s.io/utils/integer latest
    go: finding k8s.io/utils latest
    # k8s.io/client-go/rest
    ../../../pkg/mod/k8s.io/client-go@v11.0.0+incompatible/rest/request.go:598:31: not enough arguments in call to watch.NewStreamWatcher
        have (*versioned.Decoder)
        want (watch.Decoder, watch.Reporter)

    ```

测试结果

第3步，go run main.go 报出接口不一致，再看下载的依赖全是latest的。  
之前我们测试client-go时已经切换到tag kubernetes-1.14.6上，而go mod又拉取最先的依赖，这就造成了版本不一致。


解决依赖

查看client-go@kubernetes-1.14.6的go.mod下的依赖
```bash
➜  client-go git:(7e43eff7) ✗ cat go.mod
module k8s.io/client-go

require (
	cloud.google.com/go v0.0.0-20160913182117-3b1ae45394a2
	github.com/Azure/go-autorest v11.1.0+incompatible
	github.com/davecgh/go-spew v0.0.0-20170626231645-782f4967f2dc
	github.com/dgrijalva/jwt-go v0.0.0-20160705203006-01aeca54ebda
	github.com/docker/spdystream v0.0.0-20160310174837-449fdfce4d96
	github.com/evanphx/json-patch v4.2.0+incompatible
	github.com/gogo/protobuf v0.0.0-20171007142547-342cbe0a0415
	github.com/golang/groupcache v0.0.0-20160516000752-02826c3e7903
	github.com/golang/protobuf v1.1.0
	github.com/google/btree v0.0.0-20160524151835-7d79101e329e
	github.com/google/gofuzz v0.0.0-20170612174753-24818f796faf
	github.com/googleapis/gnostic v0.0.0-20170729233727-0c5108395e2d
	github.com/gophercloud/gophercloud v0.0.0-20190126172459-c818fa66e4c8
	github.com/gregjones/httpcache v0.0.0-20170728041850-787624de3eb7
	github.com/hashicorp/golang-lru v0.5.0
	github.com/imdario/mergo v0.3.5
	github.com/json-iterator/go v0.0.0-20180701071628-ab8a2e0c74be
	github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd
	github.com/modern-go/reflect2 v1.0.1
	github.com/peterbourgon/diskv v2.0.1+incompatible
	github.com/pmezard/go-difflib v0.0.0-20181226105442-5d4384ee4fb2
	github.com/spf13/pflag v1.0.1
	github.com/stretchr/testify v0.0.0-20180319223459-c679ae2cc0cb
	golang.org/x/crypto v0.0.0-20180808211826-de0752318171
	golang.org/x/net v0.0.0-20190812203447-cdfb69ac37fc
	golang.org/x/oauth2 v0.0.0-20170412232759-a6bd8cefa181
	golang.org/x/sys v0.0.0-20171031081856-95c657629925
	golang.org/x/text v0.0.0-20170810154203-b19bf474d317
	golang.org/x/time v0.0.0-20161028155119-f51c12702a4d
	gopkg.in/inf.v0 v0.9.1 // indirect
	gopkg.in/yaml.v2 v2.2.1
	k8s.io/api v0.0.0-20190816222004-e3a6b8045b0b
	k8s.io/apimachinery v0.0.0-20190816221834-a9f1d8a9c101
	k8s.io/klog v0.0.0-20190306015804-8e90cee79f82
	k8s.io/kube-openapi v0.0.0-20190228160746-b3a7cee44a30
	k8s.io/utils v0.0.0-20190221042446-c2654d5206da
	sigs.k8s.io/yaml v1.1.0
)
```

查看测试所需要的例子
```bash
➜  k8s cat go.mod
module test/k8s

require (
	github.com/imdario/mergo v0.3.8 // indirect
	golang.org/x/oauth2 v0.0.0-20191202225959-858c2ad4c8b6 // indirect
	golang.org/x/time v0.0.0-20191024005414-555d28b269f0 // indirect
	k8s.io/api v0.0.0-20191206001707-7edad22604e1 // indirect
	k8s.io/client-go v11.0.0+incompatible // indirect
	k8s.io/utils v0.0.0-20191114200735-6ca3b61696b6 // indirect
)
```


我们将例子中依赖的版本指定到client-go@kubernetes-v1.14.6相同的依赖的版本号上,这里主要针对k8s.io的依赖
```bash
k8s.io/api v0.0.0-20191206001707-7edad22604e1 // indirect
k8s.io/client-go v11.0.0+incompatible // indirect
k8s.io/utils v0.0.0-20191114200735-6ca3b61696b6 // indirect
```

go mod指定版本
```bash
go mod edit -require="k8s.io/client-go@kubernetes-v1.14.6"
go mod edit -require="k8s.io/api@v0.0.0-20190816222004-e3a6b8045b0b"
go mod edit -require="k8s.io/utils@v0.0.0-20190221042446-c2654d5206da"
```

再测试
```bash
➜  k8s go mod edit -require="k8s.io/client-go@kubernetes-1.14.6"
➜  k8s go mod edit -require="k8s.io/api@v0.0.0-20190816222004-e3a6b8045b0b"
➜  k8s go mod edit -require="k8s.io/utils@v0.0.0-20190221042446-c2654d5206da"
➜  k8s go run main.go
go: finding github.com/gogo/protobuf/sortkeys latest
go: finding github.com/gogo/protobuf/proto latest
go: finding k8s.io/apimachinery/pkg/runtime/serializer latest
go: finding k8s.io/apimachinery/pkg/util/clock latest
go: finding k8s.io/apimachinery/pkg/runtime latest
go: finding k8s.io/apimachinery/pkg/runtime/serializer/streaming latest
go: finding k8s.io/apimachinery/pkg/util/intstr latest
go: finding k8s.io/apimachinery/pkg/apis/meta latest
go: finding k8s.io/apimachinery/pkg/api/errors latest
go: finding k8s.io/apimachinery/pkg/watch latest
go: finding k8s.io/apimachinery/pkg/util latest
go: finding k8s.io/apimachinery/pkg latest
go: finding k8s.io/apimachinery/pkg/api latest
go: finding k8s.io/apimachinery/pkg/apis latest
go: finding k8s.io/apimachinery latest
go: finding k8s.io/apimachinery/pkg/conversion latest
go: finding k8s.io/apimachinery/pkg/types latest
go: finding k8s.io/apimachinery/pkg/version latest
go: finding k8s.io/apimachinery/pkg/util/wait latest
go: finding k8s.io/apimachinery/pkg/util/sets latest
go: finding k8s.io/apimachinery/pkg/api/resource latest
go: finding k8s.io/apimachinery/pkg/fields latest
go: finding k8s.io/apimachinery/pkg/runtime/schema latest
go: finding k8s.io/apimachinery/pkg/api/meta latest
go: finding k8s.io/apimachinery/pkg/util/validation latest
go: finding k8s.io/apimachinery/pkg/runtime/serializer/json latest
go: finding k8s.io/apimachinery/pkg/runtime/serializer/versioning latest
go: finding k8s.io/apimachinery/pkg/util/errors latest
go: finding github.com/googleapis/gnostic/OpenAPIv2 latest
go: finding github.com/davecgh/go-spew/spew latest
go: finding golang.org/x/crypto/ssh/terminal latest
go: finding golang.org/x/crypto/ssh latest
go: finding golang.org/x/crypto latest
# k8s.io/client-go/rest
../../../pkg/mod/k8s.io/client-go@v11.0.1-0.20190820062731-7e43eff7c80a+incompatible/rest/request.go:598:31: not enough arguments in call to watch.NewStreamWatcher
	have (*versioned.Decoder)
	want (watch.Decoder, watch.Reporter)

```

这时又报出k8s.io/apimachinery接口，再次指定相同版本
```bash
go mod edit -require="k8s.io/apimachinery@v0.0.0-20190816221834-a9f1d8a9c101"
```
测试
```bash
➜  k8s go run main.go
go: finding github.com/davecgh/go-spew/spew latest
build test/k8s: cannot find module for path sigs.k8s.io/yaml
```
报出sigs.k8s.io/yaml接口，继续指定相同版本
```bash
go mod edit -require="sigs.k8s.io/yaml@v1.1.0"
```

测试
```bash
➜  k8s go run main.go
Creating deployment...
panic: Post https://kubernetes.docker.internal:6443/apis/apps/v1/namespaces/default/deployments: EOF

goroutine 1 [running]:
main.main()
	/Users/liu/work/go/src/test/k8s2/main.go:105 +0xc80
exit status 2
➜  k8s stopvpn
取消代理
➜  k8s
➜  k8s go run main.go
Creating deployment...
Created deployment "demo-deployment".
-> Press Return key to continue.^Csignal: interrupt
➜  k8s kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
demo-deployment-5fc8ffdb68-cqqgd   1/1     Running   0          6s
demo-deployment-5fc8ffdb68-t74c7   1/1     Running   0          6s
```
因为之前下载依赖开启了镜像而又没有给k8s设置noproxy，所以出现了异常，取消代理，再测试，发现已经创建部署了demo-deployment，至此版本管理完成，client-go测试完成。


总结

测试环境
```bash
➜  ~ kubectl version
Client Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.6", GitCommit:"96fac5cd13a5dc064f7d9f4f23030a6aeface6cc", GitTreeState:"clean", BuildDate:"2019-08-19T11:13:49Z", GoVersion:"go1.12.9", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.6", GitCommit:"96fac5cd13a5dc064f7d9f4f23030a6aeface6cc", GitTreeState:"clean", BuildDate:"2019-08-19T11:05:16Z", GoVersion:"go1.12.9", Compiler:"gc", Platform:"linux/amd64"}
➜  ~ go version
go version go1.11.13 darwin/amd64
➜  ~ echo $GO111MODULE
on
```
测试demo，client-go@kubernetes-1.14.6/examples/create-update-delete-deployment/main.go  
所需指定版本的依赖（使用k8s-1.14.6的client-go可直接指定如下的依赖版本）
```bash
go mod edit -require="k8s.io/client-go@kubernetes-1.14.6"
go mod edit -require="k8s.io/api@v0.0.0-20190816222004-e3a6b8045b0b"
go mod edit -require="k8s.io/apimachinery@v0.0.0-20190816221834-a9f1d8a9c101"
go mod edit -require="k8s.io/utils@v0.0.0-20190221042446-c2654d5206da"
go mod edit -require="sigs.k8s.io/yaml@v1.1.0"
```


其他，go清理mod cache命令
```bash
go clean --modcache
```