### client-go官方库安装测试

1. git clone 
```bash
 git clone https://github.com/kubernetes/client-go.git
```

2. 查看k8s版本
```bash
➜  ~ kubectl version
Client Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.6", GitCommit:"96fac5cd13a5dc064f7d9f4f23030a6aeface6cc", GitTreeState:"clean", BuildDate:"2019-08-19T11:13:49Z", GoVersion:"go1.12.9", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.6", GitCommit:"96fac5cd13a5dc064f7d9f4f23030a6aeface6cc", GitTreeState:"clean", BuildDate:"2019-08-19T11:05:16Z", GoVersion:"go1.12.9", Compiler:"gc", Platform:"linux/amd64"}
```

3. 切换client-go到指定版本上
(mac上k8s版本1.14.6，安装指定版本的client-go)
```bash
➜  client-go git:(master) git tag -l
➜  client-go git:(master) git checkout -f kubernetes-1.14.6
Note: checking out 'kubernetes-1.14.6'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by performing another checkout.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -b with the checkout command again. Example:

  git checkout -b <new-branch-name>

HEAD is now at 7e43eff7 Fix Godeps.json to point to kubernetes-1.14.6 tags
➜  client-go git:(7e43eff7)

```

注意,go get工具还不可用(go get k8s.io/client-go@kubernetes-1.14.6)
不切换到指定版本也能会发生API不匹配等的错误

官方(demo)[https://github.com/kubernetes-client/go],截至到2019.11.26，仅支持到k8s1.13,测试发现会遇到如下的问题。不建议使用该demo测试。
```bash
➜  create-update-delete-deployment git:(master) ✗ go run main.go
Creating deployment...
panic: Post https://kubernetes.docker.internal:6443/apis/apps/v1/namespaces/default/deployments: EOF

goroutine 1 [running]:
main.main()
	/Users/liu/work/go/src/k8s.io/client-go/examples/create-update-delete-deployment/main.go:105 +0xc8e
exit status 2
```


4. 测试(注意需要使用代理,使用client-go/example测试)
```bash
➜  create-update-delete-deployment git:(7e43eff7) ✗ go run main.go
go: finding github.com/Azure/go-autorest v11.1.0+incompatible
go: downloading k8s.io/apimachinery v0.0.0-20190816221834-a9f1d8a9c101
go: downloading k8s.io/api v0.0.0-20190816222004-e3a6b8045b0b
go: downloading golang.org/x/crypto v0.0.0-20180808211826-de0752318171
go: downloading k8s.io/utils v0.0.0-20190221042446-c2654d5206da
go: downloading github.com/gogo/protobuf v0.0.0-20171007142547-342cbe0a0415
go: downloading github.com/spf13/pflag v1.0.1
go: downloading k8s.io/klog v0.0.0-20190306015804-8e90cee79f82
go: downloading github.com/json-iterator/go v0.0.0-20180701071628-ab8a2e0c74be
go: downloading github.com/golang/protobuf v1.1.0
go: downloading golang.org/x/sys v0.0.0-20171031081856-95c657629925
go: downloading github.com/google/gofuzz v0.0.0-20170612174753-24818f796faf
go: downloading golang.org/x/text v0.0.0-20170810154203-b19bf474d317
go: downloading github.com/davecgh/go-spew v0.0.0-20170626231645-782f4967f2dc
go: downloading golang.org/x/oauth2 v0.0.0-20170412232759-a6bd8cefa181
Creating deployment...
Created deployment "demo-deployment".
-> Press Return key to continue.^Csignal: interrupt

```
查看启动的deploy
```bash
-> Press Return key to continue.^Csignal: interrupt
➜  create-update-delete-deployment git:(7e43eff7) ✗ kubectl get deploy
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
demo-deployment   2/2     2            2           7s
➜  create-update-delete-deployment git:(7e43eff7) ✗

```




### 需要解决一个问题，版本不匹配的问题

1. 将client-go切换到和kubernetes对应的版本
2. 测试client-go/example,并记录其go.mod下依赖版本
3. 将client-go/example复制到新package下测试,并将其依赖指定为client-go下的版本
4. 所有依赖指定正确后可以正常运行,操作k8s

详见《k8s-client-go依赖问题解决》

