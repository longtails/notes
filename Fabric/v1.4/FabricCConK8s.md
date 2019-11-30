### Fabric CC on K8s


----
第一步：测试K8s客户端，仅需Deployment控制部署即可。 ->已经解决
----
第二步：k8s镜像仓库的解决


构建Docker私有仓库，注意registry:5000解析地址，后续K8s使用，只需在镜像名字前加上registry:5000即可,这里没有加上认证信息
```
docker pull docker.io/registry 
docker run -d -p 5000:5000 --name=registry --restart=always --privileged=true  --log-driver=none -v /tmp/data/registrydata:/tmp/registry registry
```
注意：mac本地测试，在/etc/hosts追加 127.0.0.1 registry


这里解释一下为什么要使用私有仓库

我们在K8s上部署链码，一开始我们不知道具体部署在那个节点上，所以首先解决的是节点上的镜像构建的问题。我们使用K8s都是直接配置镜像名字的，对于我们自己构建的镜像怎么处理？自己构建的没法通过K8s的工具的方式直接使用，没地方拉取镜像，除非我们能够直接通过K8s把镜像打包到对应节点上，这个功能有没有还不清楚。从分析看，我们要解决的是怎么让K8s拉取我们本地编译的镜像，这是私有仓库，就出现了。我们可以先在本地编译好镜像，然后推送的私有仓库，最后让K8s从私有仓库拉取镜像。也就我我们在镜像name前加上私有仓库地址，这里不尽兴认证，仅仅做功能处理。

[删除镜像就不管了，比较复杂](http://qinghua.github.io/docker-registry-delete/)


测试K8s使用私有仓库

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
```
将K8s的Pod.Container的image改为私有仓库

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo
spec:
  containers:
  - image: registry:5000/hyperledger/fabric-peer
    imagePullPolicy: IfNotPresent
    name: web
    ports:
    - containerPort: 80
      name: http
      protocol: TCP
    resources: {}
  dnsPolicy: ClusterFirst
```


```bash
➜  ~ kubectl create -f demo.yaml
pod/demo created
➜  ~ kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
demo                               1/1     Running   0          3s
➜  ~ kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
demo-deployment-5fc8ffdb68-lp99v   1/1     Running   0          5h11m
demo-deployment-5fc8ffdb68-xhrgb   1/1     Running   0          5h11m
peer                               1/1     Running   0          5s
➜  ~

➜  ~ cat demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: peer
spec:
  containers:
  - image: registry:5000/hyperledger/fabric-peer
    imagePullPolicy: IfNotPresent
    name: fabric-peer
  dnsPolicy: ClusterFirst

```


http 接口
```bash


//获取images
curl --unix-socket /var/run/docker.sock\
  GET "http:/v1.24/images/json?digests=1"



//打tag
curl --unix-socket /var/run/docker.sock  -X POST "http:/v1.23/images/nginx:1.12/tag?repo="registry:5000/nginx":1.12&force=0"


//向私有仓库推送本地构建的镜像,没有设置仓库权限，将X-Registry-Auth设置为空即可
curl --unix-socket /var/run/docker.sock  -X POST "http:/v1.24/images/registry:5000/nginx:1.12/push?registry=127.0.0.1:5000"  -H X-Registry-Auth:{}
或者
curl --unix-socket /var/run/docker.sock  -X POST "http:/v1.24/images/registry:5000/nginx/push?registry=127.0.0.1:5000&tag=1.12"  -H X-Registry-Auth:{}
//或者,base64加密了{}，e30K={}
curl --unix-socket /var/run/docker.sock  -X POST "http:/v1.24/images/registry:5000/nginx/push?registry=127.0.0.1:5000&tag=1.12"  -H X-Registry-Auth:e30K


path and header: /images/registry:5000/nginx/push?registry=127.0.0.1%3A5000&tag=1.12 map[X-Registry-Auth:e30K]

//获取镜像仓库中的镜像
curl -X GET "http://registry:5000/v2/_catalog"

//获取指定镜像的tag列表
➜  ~ curl -X GET "http://registry:5000/v2/nginx/tags/list"
{"name":"nginx","tags":["1.12","latest","1.11"]}
➜  ~

```
query:

利用registry manifest完成镜像的检查
```bash
curl -X GET "http://registry:5000/v2/nginx/manifests/1.12"
```

