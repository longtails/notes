### k8s部署fabric-kafka


```bash
root@hw2:~# kubectl version --short 
Client Version: v1.14.2
Server Version: v1.14.2
root@hw2:~# 
root@hw2:~# kubectl get pods -nkube-system -owide
NAME                          READY   STATUS    RESTARTS   AGE     IP              NODE   NOMINATED NODE   READINESS GATES
coredns-fb8b8dccf-lgr8p       1/1     Running   0          4h22m   10.244.1.3      hw2    <none>           <none>
coredns-fb8b8dccf-vx8lv       1/1     Running   0          4h22m   10.244.1.2      hw2    <none>           <none>
etcd-hw1                      1/1     Running   0          4h21m   192.168.0.109   hw1    <none>           <none>
kube-apiserver-hw1            1/1     Running   0          4h21m   192.168.0.109   hw1    <none>           <none>
kube-controller-manager-hw1   1/1     Running   0          4h21m   192.168.0.109   hw1    <none>           <none>
kube-flannel-ds-amd64-r57jp   1/1     Running   0          4h20m   192.168.0.109   hw1    <none>           <none>
kube-flannel-ds-amd64-vfxks   1/1     Running   0          4h20m   192.168.0.105   hw2    <none>           <none>
kube-proxy-4t268              1/1     Running   0          4h22m   192.168.0.109   hw1    <none>           <none>
kube-proxy-x4xhs              1/1     Running   0          4h22m   192.168.0.105   hw2    <none>           <none>
kube-scheduler-hw1            1/1     Running   0          4h21m   192.168.0.109   hw1    <none>           <none>
root@hw2:~# 
```


节点分布
```bash
root@hw2:~# kubectl get pods -owide
NAME                READY   STATUS    RESTARTS   AGE    IP            NODE   NOMINATED NODE   READINESS GATES
busybox             1/1     Running   2          157m   10.244.1.18   hw2    <none>           <none>
kafka-0             1/1     Running   0          44m    10.244.0.21   hw1    <none>           <none>
kafka-1             1/1     Running   0          44m    10.244.0.23   hw1    <none>           <none>
kafka-2             1/1     Running   0          43m    10.244.0.24   hw1    <none>           <none>
kafka-test-client   1/1     Running   0          44m    10.244.0.22   hw1    <none>           <none>
zk-0                1/1     Running   0          45m    10.244.0.18   hw1    <none>           <none>
zk-1                1/1     Running   0          45m    10.244.0.19   hw1    <none>           <none>
zk-2                1/1     Running   0          45m    10.244.0.20   hw1    <none>           <none>
root@hw2:~# kubectl get pods -nord -owide
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE   NOMINATED NODE   READINESS GATES
orderer-7787cc9d7d-d855h   1/1     Running   0          14m   10.244.1.23   hw2    <none>           <none>
root@hw2:~# kubectl get pods -norg1 -owide
NAME                     READY   STATUS    RESTARTS   AGE   IP            NODE   NOMINATED NODE   READINESS GATES
cli-7b57bbffcf-dnhpd     1/1     Running   0          12m   10.244.1.26   hw2    <none>           <none>
peer0-777dd85f9b-4kv9b   1/1     Running   0          13m   10.244.1.24   hw2    <none>           <none>
peer1-864697ffd5-8vvrm   1/1     Running   0          13m   10.244.1.25   hw2    <none>           <none>
root@hw2:~# 
```


运行状况

```bash
root@cli-7b57bbffcf-dnhpd:/opt/gopath/src/github.com/hyperledger/fabric/peer# ./scripts/script.sh

 ____    _____      _      ____    _____           _____   ____    _____ 
/ ___|  |_   _|    / \    |  _ \  |_   _|         | ____| |___ \  | ____|
\___ \    | |     / _ \   | |_) |   | |    _____  |  _|     __) | |  _|  
 ___) |   | |    / ___ \  |  _ <    | |   |_____| | |___   / __/  | |___ 
|____/    |_|   /_/   \_\ |_| \_\   |_|           |_____| |_____| |_____|

Channel name : mychannel

2019-05-17 12:50:07.354 UTC [channelCmd] InitCmdFactory -> INFO 003 Endorser and orderer connections initialized
2019-05-17 12:50:07.360 UTC [cli.common] readBlock -> INFO 004 Received block: 0
===================== Ordering Service is up and running ===================== 

2019-05-17 12:50:36.863 UTC [channelCmd] InitCmdFactory -> INFO 003 Endorser and orderer connections initialized
2019-05-17 12:50:36.901 UTC [cli.common] readBlock -> INFO 004 Got status: &{NOT_FOUND}
2019-05-17 12:50:36.906 UTC [channelCmd] InitCmdFactory -> INFO 005 Endorser and orderer connections initialized
2019-05-17 12:50:37.107 UTC [cli.common] readBlock -> INFO 006 Got status: &{SERVICE_UNAVAILABLE}
2019-05-17 12:50:37.110 UTC [channelCmd] InitCmdFactory -> INFO 007 Endorser and orderer connections initialized
2019-05-17 12:50:37.312 UTC [cli.common] readBlock -> INFO 008 Received block: 0
===================== Channel 'mychannel' created ===================== 

2019-05-17 12:50:51.718 UTC [channelCmd] InitCmdFactory -> INFO 003 Endorser and orderer connections initialized
2019-05-17 12:50:51.808 UTC [channelCmd] executeJoin -> INFO 004 Successfully submitted proposal to join channel
===================== peer0.org1 joined channel 'mychannel' ===================== 

2019-05-17 12:50:53.866 UTC [channelCmd] InitCmdFactory -> INFO 003 Endorser and orderer connections initialized
2019-05-17 12:50:53.937 UTC [channelCmd] executeJoin -> INFO 004 Successfully submitted proposal to join channel
===================== peer1.org1 joined channel 'mychannel' ===================== 

2019-05-17 12:51:08.487 UTC [channelCmd] InitCmdFactory -> INFO 003 Endorser and orderer connections initialized
2019-05-17 12:51:08.605 UTC [channelCmd] update -> INFO 004 Successfully submitted channel update
===================== Anchor peers updated for org 'Org1MSP' on channel 'mychannel' ===================== 

2019-05-17 12:54:23.884 UTC [chaincodeCmd] install -> INFO 005 Installed remotely response:<status:200 payload:"OK" > 
===================== Chaincode is installed on peer0.org1 ===================== 

===================== Chaincode is instantiated on peer0.org1 on channel 'mychannel' ===================== 

===================== Querying on peer0.org1 on channel 'mychannel'... ===================== 
Attempting to Query peer0.org1 ...3 secs

value is 100
===================== Query successful on peer0.org1 on channel 'mychannel' ===================== 
# exit

```