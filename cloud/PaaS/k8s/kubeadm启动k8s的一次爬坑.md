### kubeadmV1.14.6启动k8s的一次爬坑

熟练的打开ubuntu上的代理，下载指定版本v1.14.6的k8s服务器的二进制包，设置好环境变量，kubeadm init启动。


以过往的经验，这没事问题的，况且我是从v1.11版本使用过来的。事实上呵呵。

---
kubelet要放到/usr/bin中！(看kubelet.service配置)

---

kubeadm init启动集群。

```bash
root@node1:~# kubeadm init --ignore-preflight-errors=NumCPU
I1213 19:59:41.984484    5948 version.go:96] could not fetch a Kubernetes version from the internet: unable to get URL "https://dl.k8s.io/release/stable-1.txt": Get https://dl.k8s.io/release/stable-1.txt: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
I1213 19:59:41.984589    5948 version.go:97] falling back to the local client version: v1.14.6
[init] Using Kubernetes version: v1.14.6
[preflight] Running pre-flight checks
	[WARNING NumCPU]: the number of available CPUs 1 is less than the required 2
	[WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Activating the kubelet service
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [node1 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 172.19.124.123]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [node1 localhost] and IPs [172.19.124.123 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [node1 localhost] and IPs [172.19.124.123 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[kubelet-check] Initial timeout of 40s passed.
[kubelet-check] It seems like the kubelet isn't running or healthy.
[kubelet-check] The HTTP call equal to 'curl -sSL http://localhost:10248/healthz' failed with error: Get http://localhost:10248/healthz: dial tcp 127.0.0.1:10248: connect: connection refused.
[kubelet-check] It seems like the kubelet isn't running or healthy.
[kubelet-check] The HTTP call equal to 'curl -sSL http://localhost:10248/healthz' failed with error: Get http://localhost:10248/healthz: dial tcp 127.0.0.1:10248: connect: connection refused.
[kubelet-check] It seems like the kubelet isn't running or healthy.
[kubelet-check] The HTTP call equal to 'curl -sSL http://localhost:10248/healthz' failed with error: Get http://localhost:10248/healthz: dial tcp 127.0.0.1:10248: connect: connection refused.
[kubelet-check] It seems like the kubelet isn't running or healthy.
[kubelet-check] The HTTP call equal to 'curl -sSL http://localhost:10248/healthz' failed with error: Get http://localhost:10248/healthz: dial tcp 127.0.0.1:10248: connect: connection refused.
[kubelet-check] It seems like the kubelet isn't running or healthy.
[kubelet-check] The HTTP call equal to 'curl -sSL http://localhost:10248/healthz' failed with error: Get http://localhost:10248/healthz: dial tcp 127.0.0.1:10248: connect: connection refused.

Unfortunately, an error has occurred:
	timed out waiting for the condition

This error is likely caused by:
	- The kubelet is not running
	- The kubelet is unhealthy due to a misconfiguration of the node in some way (required cgroups disabled)

If you are on a systemd-powered system, you can try to troubleshoot the error with the following commands:
	- 'systemctl status kubelet'
	- 'journalctl -xeu kubelet'

Additionally, a control plane component may have crashed or exited when started by the container runtime.
To troubleshoot, list all containers using your preferred container runtimes CLI, e.g. docker.
Here is one example how you may list all Kubernetes containers running in docker:
	- 'docker ps -a | grep kube | grep -v pause'
	Once you have found the failing container, you can inspect its logs with:
	- 'docker logs CONTAINERID'
error execution phase wait-control-plane: couldn't initialize a Kubernetes cluster

```

查看kubelet.service的状态
```bash
root@node1:~# systemctl status kubelet.service
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
  Drop-In: /etc/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: activating (auto-restart) (Result: exit-code) since Fri 2019-12-13 20:02:28 CST; 3s ago
     Docs: https://kubernetes.io/docs/home/
  Process: 6294 ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELE
 Main PID: 6294 (code=exited, status=203/EXEC)

Dec 13 20:02:28 node1 systemd[1]: Stopped kubelet: The Kubernetes Node Agent.
Dec 13 20:02:28 node1 systemd[1]: Started kubelet: The Kubernetes Node Agent.
Dec 13 20:02:28 node1 systemd[1]: kubelet.service: Main process exited, code=exited, status=203/EXEC
Dec 13 20:02:28 node1 systemd[1]: kubelet.service: Failed with result 'exit-code'.
root@node1:~#
```
似乎没看到啥报错日志。但看到最后**Main process exited, code=exited, status=203/EXEC**,详查发现，[203是没有找到可执行文件](https://www.cnblogs.com/xiaochina/p/11665893.html)！。。。

回想之前v1.15.0的k8s，所有的可执行文件被自己扔进/usr/bin中操作的。**难道？kubeadm解析不了环境变量？**
没错，配置k8s二进制文件到path中，并不能使kubelet被systemctl发现。  

测试，将k8s二进制文件复制到/usr/bin中，结果如下
```bash
...
[kubelet-check] Initial timeout of 40s passed.
[apiclient] All control plane components are healthy after 42.004682 seconds
[upload-config] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.14" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --experimental-upload-certs
[mark-control-plane] Marking the node node1 as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node node1 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: i9h27e.sgclmkyb9dt1elth
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.19.124.123:6443 --token i9h27e.sgclmkyb9dt1elth \
    --discovery-token-ca-cert-hash sha256:b90b42244775f1c54468f6c6019607de7b4db17be6cbe0d77707ce99f50cc4e6
```

**且测试发现，将kubelet放到/usr/local/bin也是不行的。**



---
总结，k8s的kubelet要放到/usr/bin下，才能被systemctl发现，否则报出status=203/EXEC的结果，其他二进制无所谓，除kubelet外其他组件都可以on K8s。  

另外,查资料的过程中，发现k8s的cgroups要和docker的cgroups一致。 

---
原因：kubelet.service配置kubelet的可执行路径为/usr/bin
```bash
root@node1:~# systemctl status kubelet.service
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
  Drop-In: /etc/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: active (running) since Fri 2019-12-13 23:00:50 CST; 1 day 12h ago
     Docs: https://kubernetes.io/docs/home/
 Main PID: 30472 (kubelet)
    Tasks: 15 (limit: 2340)
   CGroup: /system.slice/kubelet.service
           └─30472 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --cgroup-driver=cgroupfs --network-plugin=cni 
```
之前k8s已经安装过，后来安装新版版只是从github release上拉取最近的配置文件搞的，忽略了很多东西。比如kubelet.service等文件，如果直接下载kubeadm、kubelet等二进制文件，kubeadm init是需要我们自己配置的。[最直接的办法还是安装kubernetes镜像源](https://developer.aliyun.com/mirror/kubernetes?spm=a2c6h.13651102.0.0.53322f70Xoieri)，后直接apt install kubeadm、kubelet，会自动配置这些文件。

---
参考[修改Docker及kubelet的Cgroup Driver](https://blog.csdn.net/Andriy_dangli/article/details/85062983)
可在/etc/docker/daemon.json(不存在，创建一个)中设置
```bash
root@node1:~# cat /etc/docker/daemon.json
{
  "registry-mirrors": ["https://wge4v65y.mirror.aliyuncs.com"],
   "exec-opts": ["native.cgroupdriver=systemd"]
}
```


参考：

1. [main process exited, code=exited, status=203/EXEC](https://www.cnblogs.com/xiaochina/p/11665893.html)
2. [修改Docker及kubelet的Cgroup Driver](https://blog.csdn.net/Andriy_dangli/article/details/85062983)
[]()
