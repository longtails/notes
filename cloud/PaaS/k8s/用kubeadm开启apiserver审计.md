### 用kubeadm开启apiserver审计日志


用kueadm搭建了k8s集群，但为了分析集群的工作请求，查看apiserver的日志，没有其他组件的请求信息，再查发现，分析集群请求需要为组件开启审计功能。本文，将通过kubeadm工具搭建集群并开启apiserver的审计功能。并记录一下所遇到的问题。



[开启Audit需要配置Audit Policy,这里直接使用官方的一个Example](https://raw.githubusercontent.com/kubernetes/website/master/content/en/examples/audit/audit-policy.yaml)


配置kubeadm conf文件
```bash
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: "v1.14.6"
controlPlaneEndpoint: "192.168.0.43:6443"
apiServer:
  extraArgs:
    #配置审计策略，在beta接口中审计功能是默认开启的
    audit-policy-file: "/etc/kubernetes/audit/audit-policy.yml"
    #logpath是将所有审计记录放到一个文件中
    audit-log-path: "/var/log/kubernetes/audit.log"
    audit-log-format: json
  #审计开启失败，大多是没有没有配置好volume
  extraVolumes:
  - name: "audit" #必须要为审计策略文件的位置
    hostPath: "/etc/kubernetes/audit"
    mountPath: "/etc/kubernetes/audit"
    pathType: DirectoryOrCreate
  - name: "auditlog" #审计日志输出位置
    hostPath: "/var/log/kubernetes"
    mountPath: "/var/log/kubernetes"
    pathType: DirectoryOrCreate
networking:
  podSubnet: 10.244.0.0/16
```


初始化Master
```bash
root@hw1:~# kubeadm init --config=kubeadm-conf.yaml
[init] Using Kubernetes version: v1.14.6
....
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

  kubeadm join 192.168.0.43:6443 --token d9145d.e0ycfthzgxcegj3c \
    --discovery-token-ca-cert-hash sha256:84f8386783c7e8231ca15b9ed4e34bb8370920be9538db50775fca7fcfa42dc5 \
    --experimental-control-plane

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.0.43:6443 --token d9145d.e0ycfthzgxcegj3c \
    --discovery-token-ca-cert-hash sha256:84f8386783c7e8231ca15b9ed4e34bb8370920be9538db50775fca7fcfa42dc5

```

查看一下生成的apiserver.yaml
```bash
root@hw1:~# cat /etc/kubernetes/manifests/kube-apiserver.yaml |grep audit -n3
13-    - kube-apiserver
14-    - --advertise-address=192.168.0.43
15-    - --allow-privileged=true
16:    - --audit-log-format=json
17:    - --audit-log-path=/var/log/kubernetes/audit.log
18:    - --audit-policy-file=/etc/kubernetes/audit/audit-policy.yml
19-    - --authorization-mode=Node,RBAC
20-    - --client-ca-file=/etc/kubernetes/pki/ca.crt
21-    - --enable-admission-plugins=NodeRestriction
--
56-      requests:
57-        cpu: 250m
58-    volumeMounts:
59:    - mountPath: /etc/kubernetes/audit
60:      name: audit
61-    - mountPath: /var/log/kubernetes
62:      name: auditlog
63-    - mountPath: /etc/ssl/certs
64-      name: ca-certs
65-      readOnly: true
--
82-  priorityClassName: system-cluster-critical
83-  volumes:
84-  - hostPath:
85:      path: /etc/kubernetes/audit
86-      type: DirectoryOrCreate
87:    name: audit
88-  - hostPath:
89-      path: /var/log/kubernetes
90-      type: DirectoryOrCreate
91:    name: auditlog
92-  - hostPath:
93-      path: /etc/ssl/certs
94-      type: DirectoryOrCreate
root@hw1:~#
```





查看审计日志,如下输出，审计功能开启成功

```bash
root@hw1:~# head -n3 /var/log/kubernetes/audit.log
{"kind":"Event","apiVersion":"audit.k8s.io/v1","level":"Request","auditID":"0e876456-b574-40e0-a8c4-aca6ebe91fea","stage":"ResponseComplete","requestURI":"/apis/storage.k8s.io/v1beta1/csidrivers?limit=500\u0026resourceVersion=0","verb":"list","user":{"username":"system:node:hw1","groups":["system:nodes","system:authenticated"]},"sourceIPs":["192.168.0.43"],"userAgent":"kubelet/v1.14.6 (linux/amd64) kubernetes/96fac5c","objectRef":{"resource":"csidrivers","apiGroup":"storage.k8s.io","apiVersion":"v1beta1"},"responseStatus":{"metadata":{},"code":200},"requestReceivedTimestamp":"2020-02-22T03:39:45.209504Z","stageTimestamp":"2020-02-22T03:39:45.209802Z","annotations":{"authorization.k8s.io/decision":"allow","authorization.k8s.io/reason":""}}
```


---

遇到的问题及解决办法

由于审计配置出错导致kubeadm没有把apiserver启动，导致kubeadm init失  

可以通过docker logs xxx查看apiserver容器的日志，看到启动失败的原因
```bash
root@hw1:~# docker logs 8f53ad315aa1
...
error: loading audit policy file: failed to read file path "/etc/kubernetes/audit-policy.yml": open /etc/kubernetes/audit-policy.yml: no such file or directory
```

看到输出，是因为又没audit-policy.yml，事实上是没有配置好，volume配置好了，但是audit-policy参数没更新到新改的volue path上。

---

参考

1. [推荐：kubeadm api,有config完整配置example](https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta1)  
2. [apiserver 启动参数](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)  
2. [Audit Policy Example](https://raw.githubusercontent.com/kubernetes/website/master/content/en/examples/audit/audit-policy.yaml)