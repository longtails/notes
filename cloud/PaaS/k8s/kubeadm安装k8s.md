### kubeadm安装k8s


之前的博客记录着断断续续的问题，有很多其实是理解上的问题，比如kubelet的配置管理，如果用kubeadm来管理，就应使用apt源的方式安装k8s tools，而不是手动下载二进制文件，否则kubelet的systemctl service就是空的需要手动配置很麻烦，再比如主机有多张网卡，需要通过apiserver-adverstied参数指定，公有云的虚拟主机没有公网ip的网卡，所以k8s就不能绑定公网ip而不能混合部署，若要混合部署则需要准备一块配置ip的网卡，而不是公有云的NAT IP。这次希望完整的记录用kubeadm安装k8s集群的过程。

---
环境:macos、virtualbox、ubuntu18.04
每个虚拟机配置两个网卡一个NAT用于访问公网、一个hostonly ip用于mac终端ssh连接vm，并用于集群之间的连接，相当于公有云下虚拟子网的私有IP。

架构安排,一个master一个slave节点，通信选择flannel插件

name|ip
---|---
master|192.168.99.111
slave1|192.168.99.121


---

架构安排,一个master一个slave节点，通信选择flannel插件

name|ip
---|---
master|192.168.99.111
slave1|192.168.99.121



安装Docker，如果速度太慢，也可以使用国内的镜像站点   

1. [安装docker community](https://docs.docker.com/install/linux/docker-ce/ubuntu/)   
2. [不加 sudo 执行 Docker 命令](http://www.markjour.com/article/docker-no-root.html)   
3. 测试hello-world
    ```bash
    node@node:~$ docker run hello-world
    Unable to find image 'hello-world:latest' locally
    latest: Pulling from library/hello-world
    1b930d010525: Pull complete
    Digest: sha256:9572f7cdcee8591948c2963463447a53466950b3fc15a247fcad1917ca215a2f
    Status: Downloaded newer image for hello-world:latest

    Hello from Docker!
    ```
---

[安装kubeadm、kubelet、kubectl](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
务必使用apt的方式安装，否则还需要手动配置。

1. 国内访问不了```apt.kubernetes.io```,可以使用国内的镜像站点，[阿里云镜像站](https://developer.aliyun.com/mirror/)

    ***如果不是用root用户登陆的，记得先sudo su切换到root环境*** 

    ```bash
    node@node:~$ sudo su
    root@node:/home/node# apt-get update && apt-get install -y 
    Reading state information... Done
    apt-transport-https is already the newest version (1.6.12).
    0 upgraded, 0 newly installed, 0 to remove and 53 not upgraded.
    root@node:/home/node# curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    100   659  100   659    0     0   1426      0 --:--:-- --:--:-- --:--:--  1423
    OK
    root@node:/home/node# cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
    > deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
    > EOF
    root@node:/home/node# apt-get update
    Hit:1 http://mirrors.163.com/ubuntu bionic InRelease
    Hit:2 http://mirrors.163.com/ubuntu bionic-updates InRelease
    Hit:3 http://mirrors.163.com/ubuntu bionic-backports InRelease
    Hit:4 https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial InRelease
    Hit:5 http://mirrors.163.com/ubuntu bionic-security InRelease
    Hit:6 https://download.docker.com/linux/ubuntu bionic InRelease
    Reading package lists... Done
    root@node:/home/node# apt-get install -y kubelet kubeadm kubectl
    Reading package lists... Done
    Building dependency tree
    Reading state information... Done
    kubeadm is already the newest version (1.17.3-00).
    kubectl is already the newest version (1.17.3-00).
    kubelet is already the newest version (1.17.3-00).
    0 upgraded, 0 newly installed, 0 to remove and 53 not upgraded.
    root@node:/home/node#
    ```

2. 关闭swap
    ```bash
    node@node:~$ sudo swapoff -a
    ```
    但是重启机器后需要重新关闭，永久关闭,注释掉```/etc/fstab```中swap的一行
3.  下载k8s的docker镜像，aws提供了镜像代理
    ```bash
    k8s.gcr.io/kube-apiserver:v1.17.3
    k8s.gcr.io/kube-controller-manager:v1.17.3
    k8s.gcr.io/kube-scheduler:v1.17.3
    k8s.gcr.io/kube-proxy:v1.17.3
    k8s.gcr.io/pause:3.1
    k8s.gcr.io/etcd:3.4.3-0
    k8s.gcr.io/coredns:1.6.5
    ```
    使用工具从aws拉取镜像,[aws GCR Proxy Cache](http://mirror.azure.cn/help/gcr-proxy-cache.html)
    ```bash
    git clone https://github.com/longtails/docker_wrapper.git
    node@node:~$ cd docker_wrapper/
    node@node:~/docker_wrapper$ ls
    docker_wrapper.py  README.md
    node@node:~/docker_wrapper$ ./docker_wrapper.py
    Usage: ./docker_wrapper.py pull ${image}
    ```
4. 测试
    ```bash
    sudo kubeadm init --ignore-preflight-errors=NumCPU
    sudo mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    node@node:~$ kubectl get nodes
    NAME   STATUS     ROLES    AGE   VERSION
    node   NotReady   master   12m   v1.17.3
    node@node:~$
    ```
    当前master node状态notready，是因为没有安装CNI插件，master当前测试正常，先切换到需要用的1.14.6版本，按加入node节点，安装CNI
5. 切换到指定版本的k8s   
    查找对应的工具版本
    ```bash
    node@node:~$ apt-cache madison kubeadm |grep 1.14.6
    kubeadm |  1.14.6-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
    node@node:~$ apt-cache madison kubectl |grep 1.14.6
    kubectl |  1.14.6-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
    node@node:~$ apt-cache madison kubelet |grep 1.14.6
    kubelet |  1.14.6-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
    ```
    安装指定版本
    ```bash
    node@node:~$ sudo apt install kubeadm=1.14.6-00
    Setting up kubeadm (1.14.6-00) ...
    node@node:~$ sudo apt install kubelet=1.14.6-00
    Setting up kubelet (1.14.6-00) ...
    node@node:~$ sudo apt install kubectl=1.14.6-00
    Setting up kubectl (1.14.6-00) ...
    ```
    确认安装的版本
    ```bash
    node@node:~$ kubeadm version
    kubeadm version: &version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.6", GitCommit:"96fac5cd13a5dc064f7d9f4f23030a6aeface6cc", GitTreeState:"clean", BuildDate:"2019-08-19T11:11:07Z", GoVersion:"go1.12.9", Compiler:"gc", Platform:"linux/amd64"}
    node@node:~$ kubectl version
    Client Version: version.Info{Major:"1", Minor:"14", GitVersion:"v1.14.6", GitCommit:"96fac5cd13a5dc064f7d9f4f23030a6aeface6cc", GitTreeState:"clean", BuildDate:"2019-08-19T11:13:49Z", GoVersion:"go1.12.9", Compiler:"gc", Platform:"linux/amd64"}
    node@node:~$ kubelet --version
    Kubernetes v1.14.6
    ```

    拉取执行版本的镜像，在docker_wrapper里设置版本
    ```bash
    node@node:~/docker_wrapper$ ls
    docker_wrapper.py  pullimage.sh  README.md
    node@node:~/docker_wrapper$ cat pullimage.sh
    #!/bin/bash

    VERSION=v1.14.6
    ./docker_wrapper.py pull k8s.gcr.io/kube-apiserver:$VERSION
    ./docker_wrapper.py pull k8s.gcr.io/kube-controller-manager:$VERSION
    ./docker_wrapper.py pull k8s.gcr.io/kube-scheduler:$VERSION
    ./docker_wrapper.py pull k8s.gcr.io/kube-proxy:$VERSION

    ETCDVERSION=v3.3.10
    DNSVERSION=1.3.1
    ./docker_wrapper.py pull k8s.gcr.io/pause:3.1
    ./docker_wrapper.py pull k8s.gcr.io/etcd:$ETCDVERSION
    ./docker_wrapper.py pull k8s.gcr.io/coredns:$DNSVERSION

    ```
    再次安装测试,但是由于配置了双网卡，希望使用第二块网卡，所以需要指定apiserver参数
    ```bash
    node@node:~$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16  --apiserver-advertise-address=192.168.99.111 --ignore-preflight-errors=NumCPU
    ...
    Your Kubernetes control-plane has initialized successfully!

    To start using your cluster, you need to run the following as a regular user:

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    You should now deploy a pod network to the cluster.
    Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
    https://kubernetes.io/docs/concepts/cluster-administration/addons/

    Then you can join any number of worker nodes by running the following on each as root:

    kubeadm join 192.168.99.111:6443 --token l4c84d.z88frmt3xiy9fvqz \
    --discovery-token-ca-cert-hash sha256:c0cf9781a91ba75774a8c76138df3cad298864e982057696a8fce23ef6cf4b55

    node@node:~$ kubectl get nodes
    NAME   STATUS     ROLES    AGE   VERSION
    node   NotReady   master   98s   v1.14.6
    ```

6. node节点安装docker、kubelet、kubeproxy，过程同Master节点   

    在指定node ip，否则会报出```error: unable to upgrade connection: pod does not exist```的错误
    ```bash
    node@slave1:~$ cat /etc/default/kubelet
    KUBELET_EXTRA_ARGS="--node-ip=192.168.99.121" #指定node的ip
    ```

    ```bash
    node@slave1:~$ sudo kubeadm join 192.168.99.111:6443 --token l4c84d.z88frmt3xiy9fvqz     --discovery-token-ca-cert-hash sha256:c0cf9781a91ba75774a8c76138df3cad298864e982057696a8fce23ef6cf4b55  --ignore-preflight-errors=NumCPU  --apiserver-advertise-address=192.168.99.121 

    ...

    This node has joined the cluster:
    * Certificate signing request was sent to apiserver and a response was received.
    * The Kubelet was informed of the new secure connection details.

    Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

    ```
    在master上查看节点情况
    ```bash
    node@master1:~$ kubectl get nodes
    NAME      STATUS     ROLES    AGE     VERSION
    master1   NotReady   master   9m35s   v1.14.6
    slave1    NotReady   <none>   5m10s   v1.14.6
    node@master1:~$
    ```
7. 安装CNI插件，这里选用flannel
    kubelet拉取flannel很慢，这里先拉取代理镜像，再打tag
    ```bash
    docker pull quay-mirror.qiniu.com/coreos/flannel:v0.11.0-amd64
    docker tag quay-mirror.qiniu.com/coreos/flannel:v0.11.0-amd64 quay.io/coreos/flannel:v0.11.0-amd64
    docker rmi quay-mirror.qiniu.com/coreos/flannel:v0.11.0-amd64 
    ```
    安装flannel插件
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml
    ```
    稍等片刻,再看集群节点情况
    ```bash
    node@master1:~$ kubectl get nodes
    NAME      STATUS   ROLES    AGE   VERSION
    master1   Ready    master   89m   v1.14.6
    slave1    Ready    <none>   85m   v1.14.6
    ```
    查看kube-system namespace的情况，正常所有组件都running
    ```bash
    node@master1:~$ kubectl get pods -nkube-system
    NAME                              READY   STATUS    RESTARTS   AGE
    coredns-584795fc57-g6nq4          1/1     Running   0          60m
    coredns-584795fc57-wdpxx          1/1     Running   0          60m
    etcd-master1                      1/1     Running   0          59m
    kube-apiserver-master1            1/1     Running   0          59m
    kube-controller-manager-master1   1/1     Running   0          59m
    kube-flannel-ds-amd64-54fhn       1/1     Running   0          57m
    kube-flannel-ds-amd64-jvnjs       1/1     Running   0          57m
    kube-proxy-bffjr                  1/1     Running   0          60m
    kube-proxy-dvm95                  1/1     Running   0          59m
    kube-scheduler-master1            1/1     Running   0          59m
    node@master1:~$
    ```
8. 安装一个busybox测试

    ```bash
    node@master1:~$ cat busybox.yaml
    apiVersion: v1
    kind: Pod
      metadata:
      name: busybox
      namespace: default
    spec:
      containers:
      - name: busybox
        image: busybox:1.28
        command:
          - sleep
          - "3600"
        imagePullPolicy: IfNotPresent
      restartPolicy: Always
    node@master1:~$ kubectl create -f busybox.yaml
    pod/busybox created
    node@master1:~$ kubectl get pods
    NAME      READY   STATUS    RESTARTS   AGE
    busybox   1/1     Running   0          3s
    node@master1:~$ kubectl exec -it busybox -- ping baidu.com
    PING baidu.com (220.181.38.148): 56 data bytes
    64 bytes from 220.181.38.148: seq=0 ttl=61 time=66.296 ms
    ^C
    --- baidu.com ping statistics ---
    1 packets transmitted, 1 packets received, 0% packet loss
    round-trip min/avg/max = 66.296/66.296/66.296 ms
    node@master1:~$
    ```
    已经可以ping通百度


9. nginx+svc 测试   
   nginx的deployment和svc文件
    ```bash
    node@master1:~$ cat nginx.yaml
    apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
    kind: Deployment
    metadata:
      name: nginx-deployment
    spec:
      selector:
        matchLabels:
        app: nginx
    replicas: 2 # tells deployment to run 2 pods matching the template
    template:
      metadata:
        labels:
            app: nginx
      spec:
        containers:
        - name: nginx
          image: nginx:1.7.9
          ports:
          - containerPort: 80

    node@master1:~$ cat svc.yaml
    kind: Service
    apiVersion: v1
    metadata:
      name: nginx
    spec:
      type: NodePort  #nodeport,通过nodeport:31000访问
      selector:
        app: nginx
      ports:
        - port: 80
          targetPort: 80
          nodePort: 31000
    ---
    apiVersion: v1
    kind: Service  #clusterip，直接通过svc访问
    metadata: 
      name: ng
    spec:
      ports:
      - port: 80
        protocol: TCP
      selector:
        app: nginx
    ```

    安装nginx deployment、svc
    ```bash
    node@master1:~$ kubectl delete -f nginx.yaml
    deployment.apps "nginx-deployment" deleted
    node@master1:~$ kubectl create -f nginx.yaml
    deployment.apps/nginx-deployment created
    node@master1:~$ kubectl get pods
    NAME                               READY   STATUS        RESTARTS   AGE
    nginx-deployment-6dd86d77d-c88fh   1/1     Running       0          3s
    nginx-deployment-6dd86d77d-zx7px   1/1     Running       0          3s
    ```

    查看部署情况
    ```bash
    node@master1:~$ kubectl get pods
    NAME                               READY   STATUS    RESTARTS   AGE
    busybox                            1/1     Running   0          20m
    nginx-deployment-6dd86d77d-7bl6f   1/1     Running   0          2m31s
    nginx-deployment-6dd86d77d-q265m   1/1     Running   0          2m31s
    node@master1:~$ kubectl get svc
    NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
    kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        84m
    ng           ClusterIP   10.96.117.253    <none>        80/TCP         2m33s
    nginx        NodePort    10.107.214.212   <none>        80:31000/TCP   2m33s
    node@master1:~$ kubectl get endpoints
    NAME         ENDPOINTS                       AGE
    kubernetes   192.168.99.111:6443             84m
    ng           10.244.1.10:80,10.244.1.11:80   2m36s
    nginx        10.244.1.10:80,10.244.1.11:80   2m36s
    ```
    测试dns
    ```bash
    node@master1:~$ kubectl exec -it busybox -- nslookup ng
    Server:    10.96.0.10
    Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

    Name:      ng
    Address 1: 10.96.117.253 ng.default.svc.cluster.local
    node@master1:~$ kubectl exec -it busybox -- nslookup nginx
    Server:    10.96.0.10
    Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

    Name:      nginx
    Address 1: 10.107.214.212 nginx.default.svc.cluster.local
    ```
    通过service访问nginx
    ```bash
    node@master1:~$ kubectl exec -it busybox -- wget ng
    Connecting to ng (10.96.117.253:80)
    wget: can't open 'index.html': File exists
    command terminated with exit code 1
    node@master1:~$ kubectl exec -it busybox -- rm index.html
    node@master1:~$ kubectl exec -it busybox -- wget ng
    Connecting to ng (10.96.117.253:80)
    index.html           100% |*******************************|   612   0:00:00 ETA
    ```
    通过nodeIP:port访问nginx
    ```bash
    node@master1:~$ curl 192.168.99.121:31000
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    ```



参考:

1. [永久关闭交换空间](https://forum.ubuntu.com.cn/viewtopic.php?t=64604)   
2. [使用aws镜像站下载k8s docker镜像](https://github.com/longtails/docker_wrapper)  
3. [使用代理下载docker镜像](https://blog.csdn.net/StephenLu0422/article/details/78924694)  
4. [kubernetes-双网卡下，coredns,dashbord,metrics-server不能访问kube-apiserver](https://blog.csdn.net/kozazyh/article/details/88541533)  
5. [Creating a single master cluster with kubeadm](https://v1-14.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
6. [kubectl exec return error: unable to upgrade connection: pod does not exist /sig-contributor-experience-bugs #63702](https://github.com/kubernetes/kubernetes/issues/63702)
7. [addr: "cni0" already has an IP address different from 10.244.1.1/24](https://www.cnblogs.com/jiuchongxiao/p/8942080.html)
8. [linux终端代理配置](https://github.com/longtails/notes/blob/master/Linux/Linux%E7%BB%88%E7%AB%AFv2ray%E4%BB%A3%E7%90%86.md)