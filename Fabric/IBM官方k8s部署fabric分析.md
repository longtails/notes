### 分析IBM官方k8s部署fabric的方案分析

之前我们测试了IBM官方的k8s部署fabric的方案，比我们之间手动在k8s部署fabric要简洁与方便，所以，就想看看IBM究竟是怎么处理的。

我们之前，用k8s部署了fabric的各个组件，但是链码我们是直接运行在节点上的，并且是需要为每个节点的Docker配置k8s集群的DNS，所以还不能完全手动，也就是说这种部署方案，并没有将链码容器纳入到k8s的环境中。

需要注意的是，链码容器的启动是通过Docker API启动的，远程当然也可以，今天做阿里比赛的题目，想用Docker直接部署几个实例，查到maven可以远程部署，当然这里也可以，链码实例化启动容器是Peer完成的，查Peer参数，可以Docker地址参数，也就是说我们可以配置远程Docker地址，将链码容器启动在这个远程Docker中。

IBM的部署方案，就是上述的思路，进一步的它使用了Docker in Docker(dind)的方案，即K8s中运行一个Docker Pod，然后将链码在这个Docker环境中启动进程, 这样的好处是:我们所能看到的都在k8s环境中;dind在k8s环境，所以链码容器可以直接利用k8s的dns系统，无需再手动配置。缺点是:链码容器放在了dind中，k8s环境是无法直接管理链码容器的，不利于我们的外部监控;至于链码容器的存活，可以通过持久化存储实现dind重启后链码容器重启；还有一个最近比较关心的问题，链码增多，dind负担也将增加；最后dind成熟可靠了么？

(有个疑问？链码容器崩溃后，fabric感知不到链码的心跳，会重启链码容器吗？->文末测试，不会；同样dind pod挂掉重启后，链码容器也不会重启，由此看IBM这个仅仅是个测试方案)


在dind中运行链码容器还是存在较多问题的，主要是它仍没有完全纳入k8s环境，那我们能不能将dind接受的链码启动命令转化为k8s中pod创建命令，将链码部署到pod中，这样就将链码纳入到k8s环境中；这个改动有两个方向：1. fabric的链码实例化源码改动，让其支持k8s启动；2. 从dind入手，拦截创建链码容器的命令，然后通过k8s api创建pod，这其实相当于做了一个代理

其中代理方案，已经在国内某BaaS服务中看到相关影子，待研究。

我们看下IBM-BLOCKCHAIN-NETWORK-ON-K8S的链码部署流程

0. 正常的各组件启动
1. jobs:安装链码
2. jobs:实例化链码
3. Peer接收到实例化链码请求，共识通过后，连接CORE_VM_ENDPOINT参数配置的远程Docker(实际是dind)，发送部署链码容器消息
4. Docker in Docker(dind),启动链码容器


追踪一下在yaml文件中链码部署流：
1. 启动docker pod,(dind)
```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: docker  #docker的域名，k8s的dns可以将域名docker解析为ip
  labels:
    run: docker
spec:
  selector:
    name: docker
  ports:
  - protocol: TCP
    targetPort: 2375
    port: 2375
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: docker-dind
spec:
  replicas: 1
  template:
    metadata:
      labels:
        name: docker
    spec:
      volumes:
      - name: dockervolume
        persistentVolumeClaim:
          claimName: docker-pvc
      containers:
      - name: docker
        securityContext:
          privileged: true
        image: "docker:stable-dind"
        ports:
        - containerPort: 2375
        volumeMounts:
        - mountPath: /var/lib/docker
          name: dockervolume
```

2. 各组件，这里关系Peer,因为由他启动链码
```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: blockchain-org1peer1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        name: org1peer1
    spec:
      volumes:
      - name: sharedvolume
        persistentVolumeClaim:
          claimName: shared-pvc
      - name: dockersocket
        hostPath:
          path: /var/run/docker.sock
      containers:
      - name: org1peer1
        image: hyperledger/fabric-peer:1.4
        command: ["sh", "-c", "sleep 1 && while [ ! -f /shared/status_configtxgen_complete ]; do echo Waiting for configtxgen; sleep 1; done; peer node start"]
        env:
        - name: CORE_PEER_ADDRESSAUTODETECT
          value: "true"
        - name: CORE_PEER_NETWORKID
          value: nid1
        - name: CORE_PEER_ID
          value: org1peer1
        - name: CORE_PEER_ADDRESS
          value: blockchain-org1peer1:30110
        - name: CORE_PEER_LISTENADDRESS
          value: 0.0.0.0:30110
        ...
        - name: CORE_PEER_COMMITTER_ENABLED
          value: "true"
        - name: CORE_PEER_PROFILE_ENABLED
          value: "true"
        - name: CORE_VM_ENDPOINT   #重点是这里,接收到链码实例化请求，Peer向此地址的Docker发送启动链码容器命令/api调用
          value: tcp://docker:2375
        - name: CORE_PEER_LOCALMSPID
          value: Org1MSP
        - name: CORE_PEER_MSPCONFIGPATH
          value: /shared/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/
        - name: FABRIC_LOGGING_SPEC
          value: debug
        ...
```

3. 链码安装，实例化，我们关系实例化部分,从下边的yaml文件，可以看到链码实例化并没有什么特殊，因为它仅仅是个Peer的客户端，真正的处理在Peer服务端，也就是上一步

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: chaincodeinstantiate
spec:
  backoffLimit: 1
  template:
    metadata:
      name: chaincodeinstantiate
    spec:
      restartPolicy: "Never"
      volumes:
      - name: sharedvolume
        persistentVolumeClaim:
          claimName: shared-pvc

      containers:
      - name: chaincodeinstantiate
        image: hyperledger/fabric-tools:1.4
        imagePullPolicy: Always
        command: ["sh", "-c", "peer chaincode instantiate -o blockchain-orderer:31010 -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} -v ${CHAINCODE_VERSION} -c '{\"Args\":[\"init\",\"a\",\"100\",\"b\",\"200\"]}'"]
        env:
        - name: CHANNEL_NAME
          value: channel1
        - name: CHAINCODE_NAME
          value: "cc"
        - name: CHAINCODE_VERSION
          value: "1.0"
        - name: FABRIC_CFG_PATH
          value: /etc/hyperledger/fabric
        - name: CORE_PEER_MSPCONFIGPATH
          value: /shared/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
        - name: CORE_PEER_LOCALMSPID
          value: Org1MSP
        - name: CORE_PEER_ADDRESS
          value: blockchain-org1peer1:30110
        - name: GODEBUG
          value: "netdns=go"
        volumeMounts:
        - mountPath: /shared
          name: sharedvolume

```


实例化部分简图：

```bash
+---------------------------------------+     +-------------------------------+
| job:chaincodeinstantiate(peer client) | --> | deploy:org1peer1(Peer server) |
+---------------------------------------+     +-------------------------------+
                                                |
                                                |
                                                v
+---------------------------------------+     +-------------------------------+
|   run chaincode container in docker   | <-- |      deploy:docker(dind)      |
+---------------------------------------+     +-------------------------------+

```



启动IBM提供的部署脚本，测试网络搭建成功后，链码也实例化完成，这时我们进入dind,通过docker ps可以看到启动的链码容器，接入标准输出，可以看到初始化的日志。并且可以可看到containerd-shim启动了链码容器。
```bash
root@node1:~/blockchain-network-on-kubernetes# ls
artifacts  configFiles  CONTRIBUTING.md  DEBUGGING.md  deleteNetwork.sh  images  LICENSE  MAINTAINERS.md  README-cn.md  README-ko.md  README.md  setup_blockchainNetwork_v1.sh  setup_blockchainNetwork_v2.sh
root@node1:~/blockchain-network-on-kubernetes# ./setup_blockchainNetwork_v2.sh 
...
Create Channel Completed Successfully
Join Channel Completed Successfully
Chaincode Install Completed Successfully
Chaincode Instantiation Completed Successfully

Network Setup Completed !!

root@node1:~/blockchain-network-on-kubernetes# kubectl get pods
NAME                                    READY   STATUS      RESTARTS   AGE
blockchain-ca-7cddd64d7f-qdhm8          1/1     Running     0          71s
blockchain-orderer-dcc8fcf96-4tg4s      1/1     Running     0          71s
blockchain-org1peer1-58f6894d5d-g7vbz   1/1     Running     0          70s
blockchain-org2peer1-8446b47ccc-cnbjc   1/1     Running     0          70s
blockchain-org3peer1-56fcfc89-xclxx     1/1     Running     0          70s
blockchain-org4peer1-68fbfc5c85-9btn8   1/1     Running     0          70s
busybox                                 1/1     Running     26         26h
chaincodeinstall-4phgb                  0/4     Completed   0          37s
chaincodeinstantiate-h7zdw              0/1     Completed   0          27s
copyartifacts-h96wb                     0/1     Completed   0          103s
createchannel-2cwf9                     0/2     Completed   0          53s
docker-dind-b6bfb4558-c9tz6             1/1     Running     0          114s
joinchannel-tzzqf                       0/4     Completed   0          46s
utils-5kqnz                             0/2     Completed   0          79s
root@node1:~# kubectl exec -it docker-dind-b6bfb4558-c9tz6 sh
/ # ps
PID   USER     TIME  COMMAND
    1 root      0:01 dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375
   15 root      0:04 containerd --config /var/run/docker/containerd/containerd.toml --log-level info
  172 root      0:00 containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/e3d8ab168d01528bd2a9024319edc86d9e5a4b5ad757db034eedb433eed8a0bb -address /var/run/docker/containerd/co
  190 root      0:00 chaincode -peer.address=10.244.0.43:7052
  233 root      0:00 sh
  238 root      0:00 ps
/ # docker ps
CONTAINER ID        IMAGE                                                                                    COMMAND                  CREATED             STATUS              PORTS               NAMES
e3d8ab168d01        nid1-org1peer1-cc-1.0-bb7b63f343a13a21a9c1a0d74aa7d87a88fe40f093e1c77941b4fc795223f3b4   "chaincode -peer.add…"   31 minutes ago      Up 31 minutes                           nid1-org1peer1-cc-1.0
/ # docker logs -f e3d8ab168d01 
ex02 Init
Aval = 100, Bval = 200

```





----
测试链码容器挂掉后，Peer能够重新启动链码容器实例，从实验结果来看，没有！测试IBM方案dind Pod挂掉重启后能够正常启动链码，结果显示没有！

进入dind pod杀死链码容器，等待许久的结果若下，并没有恢复！
```bash
并没有恢复链码容器
root@node1:~# kubectl exec -it docker-dind-b6bfb4558-c9tz6 sh
/ # ps
PID   USER     TIME  COMMAND
    1 root      0:02 dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375
   15 root      0:05 containerd --config /var/run/docker/containerd/containerd.toml --log-level info
  308 root      0:00 sh
  313 root      0:00 ps
/ # docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
/ # exit


root@node1:~# kubectl get pods
NAME                                    READY   STATUS      RESTARTS   AGE
blockchain-ca-7cddd64d7f-qdhm8          1/1     Running     0          39m
blockchain-orderer-dcc8fcf96-4tg4s      1/1     Running     0          39m
blockchain-org1peer1-58f6894d5d-g7vbz   1/1     Running     0          39m
blockchain-org2peer1-8446b47ccc-cnbjc   1/1     Running     0          39m
blockchain-org3peer1-56fcfc89-xclxx     1/1     Running     0          39m
blockchain-org4peer1-68fbfc5c85-9btn8   1/1     Running     0          39m
busybox                                 1/1     Running     27         27h
chaincodeinstall-4phgb                  0/4     Completed   0          39m
chaincodeinstantiate-h7zdw              0/1     Completed   0          38m
copyartifacts-h96wb                     0/1     Completed   0          40m
createchannel-2cwf9                     0/2     Completed   0          39m
docker-dind-b6bfb4558-c9tz6             1/1     Running     0          40m
joinchannel-tzzqf                       0/4     Completed   0          39m
utils-5kqnz                             0/2     Completed   0          39m
root@node1:~# kubectl delete pod docker-dind-b6bfb4558-c9tz6 
pod "docker-dind-b6bfb4558-c9tz6" deleted
root@node1:~# kubectl get pods --watch
NAME                                    READY   STATUS      RESTARTS   AGE
blockchain-ca-7cddd64d7f-qdhm8          1/1     Running     0          40m
blockchain-orderer-dcc8fcf96-4tg4s      1/1     Running     0          40m
blockchain-org1peer1-58f6894d5d-g7vbz   1/1     Running     0          40m
blockchain-org2peer1-8446b47ccc-cnbjc   1/1     Running     0          40m
blockchain-org3peer1-56fcfc89-xclxx     1/1     Running     0          40m
blockchain-org4peer1-68fbfc5c85-9btn8   1/1     Running     0          40m
busybox                                 1/1     Running     27         27h
chaincodeinstall-4phgb                  0/4     Completed   0          39m
chaincodeinstantiate-h7zdw              0/1     Completed   0          39m
copyartifacts-h96wb                     0/1     Completed   0          40m
createchannel-2cwf9                     0/2     Completed   0          39m
docker-dind-b6bfb4558-cjr2w             1/1     Running     0          12s
joinchannel-tzzqf                       0/4     Completed   0          39m
utils-5kqnz                             0/2     Completed   0          40m

重启pod后，也没有重启链码容器
root@node1:~# kubectl exec -it docker-dind-b6bfb4558-cjr2w sh
/ # ps
PID   USER     TIME  COMMAND
    1 root      0:00 dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375
   14 root      0:00 containerd --config /var/run/docker/containerd/containerd.toml --log-level info
  167 root      0:00 sh
  172 root      0:00 ps
/ # docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
/ # 
```

---
graph-easy
```
[job:chaincodeinstantiate(peer client)]--> [deploy:org1peer1(Peer server)] {flow:south;}
[deploy:org1peer1(Peer server)] -> [deploy:docker(dind)] {flow:west;}
[deploy:docker(dind)] ->[run chaincode container in docker] 
```