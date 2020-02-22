### etcdam部署管理etcd集群初体验

kubeadm可以提供部署etcd集群的功能，但k8s不建议使用此项功能，并规划未来通过etcdadm来部署、管理etcd集群。
本文就测试etcdadm，来快速构建etcd集群。


在第一台服务器上编译etcdadm,etcdadm使用go module管理，建议go1.11以后的版本，这里使用go1.13

make过程中，会自动解析依赖
```bash
root@node2:~# cd /usr/local/etcdadm/
root@node2:/usr/local/etcdadm# ls
apis       docs          initsystem      pkg                service
binary     etcd          LICENSE         preflight          test
certs      git_utils.sh  main.go         README.md          util
cmd        go.mod        Makefile        ROADMAP.md         version.sh
constants  go.sum        OWNERS          scripts
demo.svg   hack          OWNERS_ALIASES  SECURITY_CONTACTS
root@node2:/usr/local/etcdadm# go version
go version go1.13.8 linux/amd64
root@node2:/usr/local/etcdadm# make  
GO111MODULE=on go build -ldflags "-X 'k8s.io/component-base/version.buildDate=2020-02-20T09:09:14Z' -X 'k8s.io/component-base/version.gitCommit=434af8125ac045985949fcfed9ed9d9f7397dc3e' -X 'k8s.io/component-base/version.gitTreeState=clean' -X 'k8s.io/component-base/version.gitVersion=v0.1.2-13+434af8125ac045' -X 'k8s.io/component-base/version.gitMajor=0' -X 'k8s.io/component-base/version.gitMinor=1+'"
root@node2:/usr/local/etcdadm#
```
可以看到etcdadm的使用方式和kubeadm类似
```bash
root@node2:/usr/local/etcdadm# cp etcdadm /usr/local/bin/
root@node2:/usr/local/etcdadm# etcdadm -h
Tool to bootstrap etcdadm on the host

Usage:
  etcdadm [command]

Available Commands:
  download    Download etcd binary
  help        Help about any command
  info        Information about the local etcd member
  init        Initialize a new etcd cluster
  join        Join an existing etcd cluster
  reset       Remove this etcd member from the cluster and uninstall etcd
  version     Print version information

Flags:
  -h, --help               help for etcdadm
  -l, --log-level string   set log level for output, permitted values debug, info, warn, error, fatal and panic (default "info")

Use "etcdadm [command] --help" for more information about a command.
root@node2:/usr/local/etcdadm#
```


```etcdadm init ```命令会初始化第一个etcd服务，但是需要下载etcd安装包，需要花费较长时间，可以提前下载，并放入到/var/cache/etcdadm/etcd/v3.3.8中

```bash
root@node2:~# etcdadm init #会初始化第一个etcd服务，并设置好证书信息
root@node2:~/etcdadm# ./etcdadm init
INFO[0000] [install] Removing existing data dir "/var/lib/etcd"
INFO[0000] [install] Artifact not found in cache. Trying to fetch from upstream: https://github.com/coreos/etcd/releases/download
INFO[0000] [install] Downloading & installing etcd https://github.com/coreos/etcd/releases/download from 3.3.8 to /var/cache/etcdadm/etcd/v3.3.8
INFO[0000] [install] downloading etcd from https://github.com/coreos/etcd/releases/download/v3.3.8/etcd-v3.3.8-linux-amd64.tar.gz to /var/cache/etcdadm/etcd/v3.3.8/etcd-v3.3.8-linux-amd64.tar.gz
######################################################################## 100.0%##O=#  #                                                                     ######################################################################## 100.0%#-#O=#  #                                                                    ^C#=#=- #   #
root@node2:~/etcdadm#

```
提前下载好etcd指定版本，然后复制到
```bash
root@node1:~# cp etcd-v3.3.8-linux-amd64.tar.gz /var/cache/etcdadm/etcd/v3.3.8/
root@node1:~#
```

再次初始化
```bash
root@node2:~/etcdadm# ./etcdadm init
INFO[0000] [install] extracting etcd archive /var/cache/etcdadm/etcd/v3.3.8/etcd-v3.3.8-linux-amd64.tar.gz to /tmp/etcd278230031
INFO[0001] [install] verifying etcd 3.3.8 is installed in /opt/bin/
INFO[0001] [certificates] creating PKI assets
INFO[0001] creating a self signed etcd CA certificate and key files
[certificates] Generated ca certificate and key.
INFO[0001] creating a new server certificate and key files for etcd
[certificates] Generated server certificate and key.
[certificates] server serving cert is signed for DNS names [node1] and IPs [192.168.0.43 127.0.0.1]
INFO[0001] creating a new certificate and key files for etcd peering
[certificates] Generated peer certificate and key.
[certificates] peer serving cert is signed for DNS names [node1] and IPs [192.168.0.43]
INFO[0002] creating a new client certificate for the etcdctl
[certificates] Generated etcdctl-etcd-client certificate and key.
INFO[0002] creating a new client certificate for the apiserver calling etcd
[certificates] Generated apiserver-etcd-client certificate and key.
[certificates] valid certificates and keys now exist in "/etc/etcd/pki"
INFO[0005] [health] Checking local etcd endpoint health
INFO[0006] [health] Local etcd endpoint is healthy
INFO[0006] To add another member to the cluster, copy the CA cert/key to its certificate dir and run:
INFO[0006] 	etcdadm join https://192.168.0.43:2379
root@node2:~/etcdadm#

```


将ca证书和私钥同步的另外两台服务器上。
```bash
root@node2:~# rsync -avR /etc/etcd/pki/ca.* root@10.0.0.11:/
root@10.0.0.12's password:
sending incremental file list
/etc/etcd/
/etc/etcd/pki/
/etc/etcd/pki/ca.crt
/etc/etcd/pki/ca.key

root@node2:~# rsync -avR /etc/etcd/pki/ca.* root@10.0.0.12:/
root@10.0.0.12's password:
sending incremental file list
/etc/etcd/
/etc/etcd/pki/
/etc/etcd/pki/ca.crt
/etc/etcd/pki/ca.key
```

在11、12服务器上启动后续的etcd服务
```bash
root@hw2:~# etcdadm join https://192.168.0.43:2379
INFO[0000] [certificates] creating PKI assets
INFO[0000] creating a self signed etcd CA certificate and key files
[certificates] Using the existing ca certificate and key.
INFO[0000] creating a new server certificate and key files for etcd
[certificates] Using the existing server certificate and key.
INFO[0000] creating a new certificate and key files for etcd peering
[certificates] Using the existing peer certificate and key.
INFO[0000] creating a new client certificate for the etcdctl
[certificates] Using the existing etcdctl-etcd-client certificate and key.
INFO[0000] creating a new client certificate for the apiserver calling etcd
[certificates] Using the existing apiserver-etcd-client certificate and key.
[certificates] valid certificates and keys now exist in "/etc/etcd/pki"
INFO[0000] [membership] Checking if this member was added
INFO[0000] [membership] Member was added
INFO[0000] [membership] Checking if member was started
INFO[0000] [membership] Member was not started
INFO[0000] [membership] Removing existing data dir "/var/lib/etcd"
INFO[0000] [install] extracting etcd archive /var/cache/etcdadm/etcd/v3.3.8/etcd-v3.3.8-linux-amd64.tar.gz to /tmp/etcd455081098
INFO[0001] [install] verifying etcd 3.3.8 is installed in /opt/bin/
INFO[0002] [health] Checking local etcd endpoint health
INFO[0002] [health] Local etcd endpoint is healthy
```

如果遇到FATA[0006] [membership] Error checking membership: context deadline exceeded的错误，请先清理干净/etd/etcd/pki中的证书信息，可能是遗留的证书信息，同步时没有替换下来。


三台服务器都配置好了，使用etcdctl看一下
```bash
root@node2:~# /opt/bin/etcdctl  member list
client: etcd cluster is unavailable or misconfigured; error #0: net/http: HTTP/1.x transport connection broken: malformed HTTP response "\x15\x03\x01\x00\x02\x02"
; error #1: dial tcp 127.0.0.1:4001: getsockopt: connection refused

root@node2:~#
```

etcdadm配置的集群需要提供证书、私钥以及开放接口，这都不是默认的。

etcdadm生成的可执行文件有一个etcdctl.sh脚本，它完成了对etcdctl和配置的封装
```bash
root@node2:/opt/bin# ls
etcd  etcdctl  etcdctl.sh
root@node2:/opt/bin#
root@node2:/opt/bin# cat etcdctl.sh
#!/usr/bin/env sh
if ! [ -r "/etc/etcd/etcdctl.env" ]; then
	echo "Unable to read the etcdctl environment file '/etc/etcd/etcdctl.env'. The file must exist, and this wrapper must be run as root."
	exit 1
fi
. "/etc/etcd/etcdctl.env"
"/opt/bin/etcdctl" "$@"
root@node2:/opt/bin#

```
使用etcdctl.sh查看集群情况
```bash
root@node2:/opt/bin# ./etcdctl.sh member list
51c9fc10a9d0072a, started, hw2, https://10.0.0.12:2380, https://10.0.0.12:2379
7d607507f758d043, started, node2, https://192.168.0.43:2380, https://192.168.0.43:2379
93fc1c0cac166cb8, started, hw3, https://10.0.0.13:2380, https://10.0.0.13:2379
root@node2:/opt/bin#
```

---
etcadm可以在arm64环境下编译，但是不支持部署管arm etcd。
```bash
root@hw1:~# etcdadm init
INFO[0000] [install] extracting etcd archive /var/cache/etcdadm/etcd/v3.3.8/etcd-v3.3.8-linux-amd64.tar.gz to /tmp/etcd264019782
INFO[0000] [install] verifying etcd 3.3.8 is installed in /opt/bin/
FATA[0000] [install] Error: command "/opt/bin/etcd" failed: "2020-02-20 17:14:19.025978 E | etcdmain: etcd on unsupported platform without ETCD_UNSUPPORTED_ARCH=arm64 set.\n"
root@hw1:~#
```
同时，在多网卡环境下希望指定网卡监听，但是发现不可以，当前etcdadm只监听默认网关地址，[在github上可有提出加上```listen-address```参数的PR](https://github.com/kubernetes-sigs/etcdadm/pull/94)

---

最后总结一下，etcdadm目前不支持arm64架构，不支持指定监听地址，当前会用默认网关地址作为将定地址，在多网卡场景受限制。

可以看到，etcdadm虽然可以快速构建etcdadm集群，但是还是处于初期，许多feature还要添加。

---
参考  
[kubernetes-sigs/etcdadm](https://github.com/kubernetes-sigs/etcdadm)    
[fix #77: add `--listen-address` and --advertise-address` #94](https://github.com/kubernetes-sigs/etcdadm/pull/94)  



---

[etcd查看集群状态,检查leader](https://github.com/etcd-io/etcd/issues/9417)

```etcdctl.sh --endpoints=https://192.168.0.43:2379,https://10.0.0.12:2379,https://10.0.0.13:2379  endpoint status -w table --cluster ```
```bash
root@node2:~# etcdctl.sh --endpoints=https://192.168.0.43:2379,https://10.0.0.12:2379,https://10.0.0.13:2379  member list
51c9fc10a9d0072a, started, hw2, https://10.0.0.12:2380, https://10.0.0.12:2379
7d607507f758d043, started, node2, https://192.168.0.43:2380, https://192.168.0.43:2379
93fc1c0cac166cb8, started, hw3, https://10.0.0.13:2380, https://10.0.0.13:2379
root@node2:~# etcdctl.sh --endpoints=https://192.168.0.43:2379,https://10.0.0.12:2379,https://10.0.0.13:2379  endpoint status -w table --cluster
+---------------------------+------------------+---------+---------+-----------+-----------+------------+
|         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
+---------------------------+------------------+---------+---------+-----------+-----------+------------+
|    https://10.0.0.12:2379 | 51c9fc10a9d0072a |   3.3.8 |   20 kB |     false |        19 |         15 |
| https://192.168.0.43:2379 | 7d607507f758d043 |   3.3.8 |   20 kB |     false |        19 |         15 |
|    https://10.0.0.13:2379 | 93fc1c0cac166cb8 |   3.3.8 |   20 kB |      true |        19 |         15 |
+---------------------------+------------------+---------+---------+-----------+-----------+------------+
root@node2:~#

```