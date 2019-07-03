## k8s复习笔记


面向k8s管理员的认证项目，考核日常运维k8s集群所需的知识、技能、熟练度。

---

### 第一课

基础概念，调度，网络，存储，问题排查，安全，日志、监控与应用管理，集群安装运维与安装配置


#### k8s整体架构：master-slave

master: scheduler->apiserver(一大堆控制器，Endpoints、node、repulicate)-> etcd

slave: kubelet(负责pod被调度之后完整的生命周期)、kube-proxy(负责service和endpoints的生命周期，负责loadbalance的规则)

![k8s](../images/20190702-k8s.png)

工作原理，本质上是list-wath的工作方式，可以认为一种消息通知的方式
![k8s-watch-list](../images/20190702-k8s-watch-list.png)

不同的组件对象，处理的是不同的api对象，或者某个对象不同的生命周期,所有组件与apiserver交互屏蔽了与底层的etcd的接触，每次接收到的变化都存到etcd中去

创建对象：  

0. 集群启动，各个组件controller-manager、scheduler、kubelet都会和API-server发起watch请求，建立连接
1. kubectl创建ReplicaSet，请求发送到api-server
2. api-server将变化存到etcd中，etcd上报RS创建事件到api-server
3. api-server发布rs创建的事件，controller-manager中replicaSet controller订阅了该事件，所以会收到rc创建事件
4. controller-manager，replicatSet controller会创建实例Pod,并将创建pod的事件发送到api-server
5. api-server将创建pod消息存储到etcd中
6. etcd上报pod创建事件到api-server,api-server发布pod创建事件，scheduler组件会处理没有被调度的pod，destNode="" ,它的处理就是更新pod，为每个pod绑定一个节点，所以输出就是为pod添加node,将结果返回给api-server,更新etcd中pod
7. etcd上报pod bound到api-server,api-server发布pod更新事件，kubelet会收到这些更细事件，通过过滤可以发现调度到自己所在node的pod，之后会负责这些pod的容器创建、网络、存储等准备。    


组件| controller-manager|scheduler|kubelet
---|---|---|---
watch内容|watch各类set,处理生命周期事件；定理list做同步处理，保证最终一致|list&watch集群中的node,供调度时使用；watch未调度的pod,进行多策略调度|watch被调度到本节点的pod,执行生命周期动作





#### k8s基本概念

pod:
1. 一组功能相关的container的封装
2. 共享存储和Network namespace
3. k8s调度和作业运行的基本单位(scheduler调度，kubelet运行)
4. 容易“走失”，需要workload和service的“呵护”(pod 不是持久化对象)

workload(deployment,statefulSet,daemonSet,job...): 一组功能相关的pod的封装

service: pod“防失联“；给一组pod设置反向代理

label-selector


k8s api对象的基本构成：  
typeMeta(对象类型的表示);objectMeta（最基础对象基本属性，name,label）；spec(期望状态);status(实际状态)。

最重要的部分spec和status,对于workload来说，有个显著特点，因为它都是一组pod的封装，所以spec.template下就是一个pod的定义；spec.selector是一个通用的字段，调度是要通过selector进行的；


kubectl explain,查看对象名，比如kubectl edit relicaset  
kubectl edit 使用系统编辑器编辑资源，kubectl deploy/foo

kubectl expose, 为deployment、pod创建service  
kubectl run, 运行一个特殊的镜像
kubectl set, 指定一个字段

kubectl describe 查看资源详情，trouble shooting
kubectl apply 从文件或stdin创建、更新资源

kubectl completion 获取shell自动补全脚本,source <(kubectl completion bash)   
kubectl label 给资源设置label
kubectl annotate 给资源设置annotation

生成yaml模版: kubectl run --image=nginx my-deploy -o yaml --dry-run >my-deploy.yaml

用get命令导出: kubectl get statefulset/foo -o=yaml --export >new.yaml

pod亲和性下面字段的拼写忘记时: kubectl explain pod.spec.affinity.podAffinity

作业：
1. 通过命令行，使用nginx镜像创建一个pod
2. 通过单个命令创建一个deployment并暴露service,replicas=2


1. 获取k8s二进制文件、安装docker

2. swapoff -a

3. kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU

4. kubeadm config images pull
---

### 第二课

理解资源限制对Pod调度的影响，使用label selector调度pod，手动调度Pod,理解DaemonSet,调度失败分析原因，使用多调度器，俩节调度器的配置

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: busybox:1.28
    imagePullPolicy: IfNotPresent
    name: busybox
    resources: {}
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-wxhvp
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: node1
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: default-token-wxhvp
    secret:
      defaultMode: 420
      secretName: default-token-wxhvp
```
scheduling:为pod找到一个合适的Node，调度后，为配置文件填充NodeName

node可分配资源量:  
allocatable:cpu,memory,pods;   
capacity:cpu,memory,pods;  
在生产时，要预留部分资源给k8s组件，一般capacity>allocatable

#### pod:  
一组containers的组合，spec.containers;    
resources:requests(memory,cpu),limits(memory,cpu);   
requests是资源调度依据，limits是给kubelet使用的,用于限制pods是哟哦那个多少资源      

schedulerName: default-scheduler指定调度器   
nodeName: node1,保存调度结果  
高级调度策略：nodeSelector,affinity,tolerations


#### k8s调度器的资源分配机制：  
基于Pod中容器request资源“宗和”调度：
1. resources.limits影响pod的运行资源上线，不影响调度
2. initContainer取最大值，container取累加值，最后取大者，Max(Max(initContainers.requests),Sum(containers.requests))，预处理操作可以放在initContainer 
3. 未指定request资源时，按0资源需要进行调度



基于资源声名量的调度，而非实际占用：
1. 不依赖监控，系统不会过于敏感
2. 能否调度成功：pod.request < node.allocatable-node.requested



k8s node资源的盒子模型:

node Capacity - kube-reserved - system-reserved - hard eviction = node allocatable

资源分配相关算法：
1. GeneralPredicates(主要是PodFitsResources)，检查cpu,mem,磁盘的余量，余量不足直接排序不满足的节点
2. LeastRequestedPriority，排序算法，平衡节点对调度器调度的次数，每次取最少调度的节点，保证节点上的pod数量均衡
3. BalancedResourceAllocation,排序算法，平衡cpu/mem的消耗比例,看pod使用的cpu/mem比例是否和node剩余的cpu/mem比例相近


Pod所需资源的计算：
InitContainers:逐个运行并推出，之后才拉起containers,资源需求取单个容器的最大值；Containers:同时运行，资源需求为所有容器累加;最后取两个阶段的最大值，作为所需资源。

 

#### k8s中的高级调度及用法

nodeSelector: 将Pod调度到特定的Node上：  
语法格式：map[string]string;作用：匹配node.labels,排序不包含nodeSelector中指定label的所有node;匹配机制-完全匹配。

```yaml
...
spec:
    nodeSelector:
        disktypeL ssd  #key
        node-flavor: s3.large.2  #value
```

nodeAffinity: nodeSelector升级版  
与nodeSelector关键差异：
1. 引入运算符：In,NotIn(labelselector语法)
2. 支持枚举label可能的取值，如zone in[az1,az2,...]
3. 支持硬性过滤和软性评分
4. 硬性过滤规则支持指定多条件之间的逻辑或运算
5. 软性评分规则支持设置条件权重值

硬性过滤：排除不具备指定label的node   
软性评分：不具备指定label的node打低分，降低node被选中的几率

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-node-affinity
spec:
  affinity:
    nodeAffinity:  #节点亲和
      requiredDuringSchedulingIgnoredDuringExecution: #必须满足
        nodeSelectorTerms: # matchExpressions之间是逻辑或的关系
        - matchExpressions: # matchExpressions内的key是逻辑与的关系
          - key: kubernetes.io/e2e-az-name
            operator: In
            values:
            - e2e-az1
            - e2e-az2
      preferredDuringSchedulingIgnoredDuringExecution:  #优先满足
      - weight: 1  #权重
        preference:
          matchExpressions:
          - key: another-node-label-key
            operator: In
            values:
            - another-node-label-value
  containers:
  - name: with-node-affinity
    image: k8s.gcr.io/pause:2.0
```


#### podAffinity: 让某些pod分布在同一组Node上
与nodeAffinity的关键差异:
1. 定义在PodSpec中，亲和与反亲和规则具有对称性
2. labelSelector的匹配对象为pod
3. 对node分组，依据label-key=topologyKey,每个label-value取值为一组
4. 影响过滤规则，条件间只有逻辑与运算

硬性过滤：排除不具备指定pod的node组   
软性评分：不具备指定pod的node组打低粉，降低该组node被选中的几率


#### podAntiAffinity:避免某些Pod分布在同一组Node上
与podAffinity的差异：
1. 匹配过程相同
2. 最终处理调度结果时取反
即：
1. podAffinity中可调度节点，在podAntiAffinity中为不可调度
2. podAffinity中高分节点，在podAntiAffinity中为低分



```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-pod-affinity
spec:
  affinity:
    podAffinity: #亲和性
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:  #只有逻辑与，没有或
          matchExpressions:
          - key: security
            operator: In
            values:
            - S1
        topologyKey: failure-domain.beta.kubernetes.io/zone  #目标pod和当前pod的关系是在一个什么样的级别，比如同一个区域，一个机架，或者自定义的node分组;这里指的是node上的label
    podAntiAffinity: #反亲和
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm: 
          labelSelector:
            matchExpressions:
            - key: security
              operator: In
              values:
              - S2
          topologyKey: failure-domain.beta.kubernetes.io/zone
  containers:
  - name: with-pod-affinity
    image: k8s.gcr.io/pause:2.0
```


#### 手动调度Pod（不经过调度器）

使用场景：
1. 调度器不工作时，临时救急
2. 封装实现自定义调度器

实现，直接在创建Pod时指定nodeName，这样就不会经过调度器，直接部署到对应的node上。

小故事：
1. 过去几个版本的DaemonSet都是由controller直接指定pod的运行节点，不经过调度器
2. 带来的问题是，这样DaemonSet调度的pod跟默认调度器这些的pod在分布上会有些分裂
3. 直到1.11版本，DaemonSet的pod由scheduler调度才作为alpha特性引入 

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: busybox:1.28
    imagePullPolicy: IfNotPresent
    name: busybox
  nodeName: node1
```


#### DaemonSet:每个节点来一份

1. 每个node上部署一个相同的pod
2. 通常用来部署集群中的agent，例如网络插件
3. 等价于配置了节点级别反亲和的Deployment,实例数要和node数相等

```yaml
apiVersion: v1/beta2 # For Kubernetes version 1.9 and later, use apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  selector:
      matchLabels:
        name: fluentd # Label selector that determines which Pods belong to the DaemonSet
  template:
    metadata:
      labels:
        name: fluentd # Pod template's label selector
    spec:
      nodeSelector:
        type: prod 
      containers:
      - name: fluentd
        image: gcr.io/google-containers/fluentd-elasticsearch:1.20
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
```


#### Taints: 避免Pod调度到特定的Node上

1. 带effect的特殊label,对Pod有排斥性：
    1. 硬性排斥NoSchedule
    2. 软性排斥PreferNoSchedule
2. 系统创建的taint附带时间戳：
    1. effect为NoExecute
    2. 便于触发对Pod的超时驱逐
3. 典型用法：预留特殊节点做特殊用途

```bash
#给node增加taint:
kubectl taint node node1 foo=bar:NoSchedule
#删除taint
kubectl taint node node1 foo:NoSchedule-
```
```yaml
apiVersion: v1
kind: Node
metadata:
  annotations:
    node.alpha.kubernetes.io/ttl: "0"
  creationTimestamp: "2019-06-29T07:57:49Z"
  labels:
    kubernetes.io/os: linux
  name: node1
spec:
  podCIDR: 10.244.0.0/24
  taints:
  - effect: NoSchedule  #由node-Controller,kubelet处理的
    key: foo
    value: bar
```


#### Tolerations:允许Pod调度到有特定taints的Node上


tolerations指定key后，可以无视node上配置的taints,

1. 完全匹配：key=value:effect，opertator:equal,value和effect都是要进行匹配的
2. 匹配任意taint value:
    1. opertator为exists,value为空
    2. 例: key:effect

3. 匹配任意taint effect:
    1. effect为空
    2. 例子:key=value 

4. 多个taints,要配多个tolerations，或者使用通配符的形式


```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: busybox:1.28
    imagePullPolicy: IfNotPresent
    name: busybox
    resources: {}
  nodeName: node1
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  tolerations:
  - effect: NoExecute
    key: foo
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
```

#### 调度失败原因分析

1. 查看调度结果：kubectl get pod [podname] -owide
2. 查看调度失败原因： kubectl describe pods [podname],有调度失败事件
3. 调度失败列表,看k8s源码的error.go文件，有error列表


#### 多调度器

1. 适用场景：集群中存在多个调度器，分别处理不同类型的作业调度
2. 使用限制：建议对node做资源池划分，避免调度结果写入冲突

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - command:
    - sleep
    - "3600"
    image: busybox:1.28
    imagePullPolicy: IfNotPresent
    name: busybox
    resources: {}
  nodeName: node1
  schedulerName: default-scheduler
```

#### 自定义调度器配置

kube-scheduler --policy-config-file自定义调度器加载的算法，或者调整排序算法权重
```json
{
"kind" : "Policy",
"apiVersion" : "v1",
"predicates" : [
    {"name" : "PodFitsHostPorts"},
    {"name" : "PodFitsResources"},
    {"name" : "NoDiskConflict"},
    {"name" : "MatchNodeSelector"},
    {"name" : "HostName"}
    ],
"priorities" : [
    {"name" : "LeastRequestedPriority", "weight" : 1},
    {"name" : "BalancedResourceAllocation", "weight" : 1},
    {"name" : "ServiceSpreadingPriority", "weight" : 1},
    {"name" : "EqualPriority", "weight" : 1}
    ],
"extenders":[
    {
        "urlPrefix": "http://127.0.0.1:12346/scheduler",
        "apiVersion": "v1beta1",
        "filterVerb": "filter",
        "prioritizeVerb": "prioritize",
        "weight": 5,
        "enableHttps": false,
        "nodeCacheCapable": false
    }
    ]
}
```

执行kube-scheduler --help查看更多调度器配置项
```bash
root@node1:~# kubectl exec -it  kube-scheduler-node1 -n kube-system sh
# kube-scheduler --help
The Kubernetes scheduler is a policy-rich, topology-aware,
workload-specific function that significantly impacts availability, performance,
and capacity. The scheduler needs to take into account individual and collective
resource requirements, quality of service requirements, hardware/software/policy
constraints, affinity and anti-affinity specifications, data locality, inter-workload
interference, deadlines, and so on. Workload-specific requirements will be exposed
through the API as necessary.

Usage:
  kube-scheduler [flags]
...
      --policy-config-file string                                                                      
                DEPRECATED: file with scheduler policy configuration. This file is used if policy ConfigMap is not provided or --use-legacy-policy-config=true

```

---
### 第三课

监控集群组件，监控应用，管理组件日志，管理应用日志，Deployment升级和回滚，配置应用的不同方法，应用弹性伸缩，应用自恢复。

#### 监控组件

监控集群状态：  
kubectl cluster-info

更多集群信息：   
kubectl cluster-info dump

通过插件部署：  
kubectl get pods etcd -n kube-system  
kubectl describe pod kube-apiserver -n kube-system  

组件metrics:   
curl localhost:10250/stts/summary

组件健康状况：   
curl localhost:10250/healthz

Heapster+cAdvisor监控集群组件  

cAdvisor既能手机容器cpu、内存、文件系统和网络使用统计信息，还能采集节点资源使用情况；cAdvisor和Heapster都不能进行数据存储、趋势分析和报警，因此还需要将数据推送到influxDB,Grafana等后端进行存储和图形化展示；Heapster即将倍metrics-server替代。

对接heapster或metrics-server后展示Node CPU/内存/存储资源消耗:   
kubectl top node {node name}

监控应用：  
kubectl describe pod  

对接了heapster或metrics-server后，展示Pod CPU/内存/存储资源消耗：   
kubectl top pod {pod name}    
kubectl get pods {pod name} --watch


#### 管理k8s组件日志:   
/var/log/kube-xxx.log

使用systemd管理：   
journalctl -u kubelet

使用k8s插件部署：  
kubectl logs -f kube-proxy  

#### 管理k8s应用日志：

从容器标准输出截获：  
kubectl logs -f {pod name} -c {container name}  
docker logs -f {docker name}  

进入容器内查看日志:  
kubectl exec -it {pod} -c {container}  /bin/sh   
docker exec -it {container}  /bin/sh

#### Deployment升级与回滚

创建Deployment:  
kubectl run {deployment} --image={image}  --replicas={rep}  

升级Deployment:   
kubectl set image deployment deployment/ng nginx=nginx:1.9.1  
kubectl set resources deployment/ng -c=ng --limits=cpu=200m,memory=512Mi

升级策略：  
```yaml
minReadySeconds:5
strategy:
  type:RollingUpdate #滚动升级
  rollingUpdate:
    maxSurge: 1 #默认25%，最多多出来几个pods
    maxUnavailable: 1 #默认25%，最多几个不可用
```

暂停升级：  
kubectl rollout pause deployment/ng  
暂停后，之后的操作都不会记录到日志中  

恢复:   
kubectl rollout resume deployment/ng
恢复后，操作会记录到日志

查询升级状态：  
kubectl rollout status deployment/ng  

查询升级历史:  
kubectl rollout history deploy/ng  
kubectl rollout history deploy/ng --revision=2  

回滚：  
kubectl rollout undo deployment/ng --to-revision=2

应用弹性伸缩：  
kubectl scale deployment ng --replicas=10  

对接了heapster,和HPA联动后：  
kubectl autoscale deployment ng --min=10 --max=15 --cpu-percent=80  

应用自恢复：restartPolicy+livenessProbe  

Pod Restart Policy:Always,OnFailure,Never  
livenessProbe: http/https Get,shell exec,tcpSocket  

tpc socket的liveness探针+always restart例子

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: goproxy
  labels:
    app: goproxy
spec:
  restartPolicy: Always
  containers:
  - name: goproxy
    image: k8s.gcr.io/goproxy:0.1
    ports:
    - containerPort: 8080
    readinessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
    livenessProbe: #k8s定期检查tcp socket
      tcpSocket:
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 20  #时间间隔，20s
```

作业：
1. 通过Deployment方式，使用redis镜像创建1个Pod，通过kubectl获得redis启动日志
2. 通过命令行，创建1个deployment,副本数为3，镜像为nginx:latest,然后滚动升级到nginx:1.9.1

---
### 第四课

Pod网络、CNI、Service概念、部署和配置网络load balancer、Ingress概念、配置和使用集群DNS


#### Pod网络:
1. 一个pod一个ip:
  1. 每个pod独立ip,pod内所有容器共享网络namespaces(同一个ip)
  2. 容器之间直接通信，不需要NAT
  3. Node和容器直接通信，不需要NAT
  4. 其他容器和容器自身看到IP是一样

2. 集群内访问走Service,集群外访问走Ingress
3. CNI(container network interface)用于配置pod网络：不支持docker网络


k8s master创建pod,kubelet watch到pod创建并调度到node上，kubelet调用cri接口（dockershim,containerd)创建两个容器（conatainer和pause),初始化pause容器、网络namespace,containerA加入pause容器网络namespaces;
kubelet调用network driver(kubenet,CNI),CNI(default pugin:p2p,bridge,基础的通信，第三方pugin:flannel,calico,解决容器跨机通信)

CNI: container network interface
1.容器网络的标准化
2. 使用json来描述网络配置
3. 两类接口：
  1. 配置网络--创建容器时调用(AddNetwork(net NetworkConfig,rt RuntimeConf)(types.Result,error))
  2. 清理网络--删除容器时调用DelNetwork(net NetworkConfig,rt RuntimeConf) 

CNI插件：host-local+bridge

配置：/etc/cni/net.d/*.configlist
```bash
{  
  "name": "cbr0",
  "ipam": {
      "type": "host-local",
      "subnet": "10.10.0.0/16"
    }
}
```
CNI plugin二进制文件：
```bash
root@node1:/opt/cni/bin# ls
bridge  dhcp  flannel  host-device  host-local  ipvlan  loopback  macvlan  portmap  ptp  sample  tuning  vlan
```


#### K8S service

service：虚拟ip+port,一个抽象的中间层，通过label-selector机制选中后端pod，后端pod当running且ready会成为endpoints对象，k8s会为service和pod ip在dns中形成一个记录。

pod是A记录:< ip >:< port >,service可以是A记录可以是SRV记录。


分类：cluster-ip,node-port,load-balance,headless(没有cluster ip)，external-name

service
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    run: ng
  name: ng
  namespace: default
spec:
  clusterIP: 10.102.120.102   #虚ip
  ports:
  - port: 8080   #service port
    protocol: TCP
    targetPort: 80  #pod容器port
  selector:
    run: ng
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
```

endpoints
```yaml
apiVersion: v1
kind: Endpoints
metadata:
  labels:
    run: ng
  name: ng
  namespace: default
subsets:
- addresses: 
  - ip: 10.244.0.4   #pod容器ip
    nodeName: node1
    targetRef:
      kind: Pod
      name: ng-6446bb48cb-cf7md
      namespace: default
  ports:  #对应service的target port
  - port: 80
    protocol: TCP
```


LoadBalancer类型service:
1. 同时是cluster ip类型
2. 需要跑在特定的cloud provider上：
    1. service controller自动创建一个外部LB并配置安全组
    2. 对集群内访问，kube-proxy用iptables或ipvs实现了云服务提供商LB的部分功能：L4转发，安全组规则等

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ng
spec:
  clusterIP: 10.102.120.102
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 80
  selector:
    run: ng
  type: LoadBalancer
  loadBalancerIP: 78.11.24.19 #外部ip
```


#### Ingress:
1. Ingress是授权入站连接到达集群服务的规则集合:
    1. 支持通过URL方式将Service暴露给k8s集群外，Service之上的L7访问入口,路由
    2. 支持自定义Service的访问策略
    3. 提供按域名访问的虚拟主机功能
    4. 支持TLS
  
2. 具体转发有Ing Controller实现，需要配置好控制器，才能实现分流
```bash
    internet
        |
   [ Ingress ]
   --|-----|--
   [ Services ]
```


```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: simple-fanout-example
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: foo.bar.com
    http:
      paths:
      - path: /foo  #分流
        backend:
          serviceName: service1
          servicePort: 4200
      - path: /bar
        backend:
          serviceName: service2
          servicePort: 8080
```
```bash
kubectl describe ingress simple-fanout-example

Name:             simple-fanout-example
Namespace:        default
Address:          178.91.123.132
Default backend:  default-http-backend:80 (10.8.2.3:8080)
Rules:
  Host         Path  Backends
  ----         ----  --------
  foo.bar.com
               /foo   service1:4200 (10.8.0.90:4200)
               /bar   service2:8080 (10.8.0.91:8080)
Annotations:
  nginx.ingress.kubernetes.io/rewrite-target:  /
Events:
  Type     Reason  Age                From                     Message
  ----     ------  ----               ----                     -------
  Normal   ADD     22s                loadbalancer-controller  default/test

```


#### k8s DNS

1. 解析Pod和Service的域名，k8s集群内Pod使用,(kubelet配置 --cluster-dns把DNS的静态IP传递给每个容器)
2. kube-dns（淘汰）和coreDNS
3. 对service:
    1. A记录：   
    普通service: my-svc.my-namespace.svc.cluster.local ->cluaster ip     （cluster.local kubelet --cluster-domain配置伪域名）    
    headless service: my-svc.my-namespace.svc.cluster.local ->后端pod ip列表
    2. SRV记录（查后端端口用的）：  
    my-port-name.my-port-protocal.my-svc.my-namespace.svc.cluaster.local-> service port

4. 对pod（只支持A记录）：
    1. A记录：  
      pod-ip.my-namespace.pod.cluster.local -> pod ip (pod-ip:1-2-3-4)
    2. 在pod spec指定hostname和subdomain:   
      hostname.subdomain.my-namespace.pod.cluster.local -> pod ip

kubelet在容器启动时，将cluster-dns 静态ip写到每个容器的resov.conf文件，需要解析域名时，访问resov.conf配置的DNS服务器

headless service没有cluster-ip,但是它可以通过label-selector选中后端pod,查到后端pod的IP列表，所以statefulSet需要使用headless service；SRV服务记录，查后端端口用的。

pod的DNS通过pod name查，可以配置subdomain。


课后作业：
1. 创建1一个service和1个pod作为其后端，通过kubectl desribe获得该service和对应Endpoints信息
2. 创建一个Service和1个pod作为其后端，通过nslookup查询该service的pod域名信息

```bash
root@node1:~# kubectl create svc clusterip my-svc-ng --tcp=80:8080 #type clusterip
service/my-svc-ng created
root@node1:~# kubectl get svc -owide
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE     SELECTOR
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP    2d18h   <none>
my-svc-ng    ClusterIP   10.105.75.216    <none>        80/TCP     9s      app=my-svc-ng

root@node1:~# curl  10.105.75.216:80
curl: (7) Failed to connect to 10.105.75.216 port 80: Connection refused

root@node1:~# kubectl describe svc my-svc-ng  #没有后端pod
Name:              my-svc-ng 
Namespace:         default
Labels:            app=my-svc-ng
Annotations:       <none>
Selector:          app=my-svc-ng
Type:              ClusterIP
IP:                10.105.75.216
Port:              80-8080  80/TCP
TargetPort:        8080/TCP
Endpoints:         <none>
Session Affinity:  None
Events:            <none>

root@node1:~# kubectl create svc nodeport my-svc-np --tcp=1234:80
service/my-svc-np created
root@node1:~# kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP          2d19h
my-svc-ng    ClusterIP   10.105.75.216    <none>        80/TCP           5m6s
my-svc-np    NodePort    10.108.22.156    <none>        1234:30678/TCP   6s  #特殊之处在于有个大端口 30678


root@node1:~# curl 172.19.124.123:30678  #可以通过主机ip访问，如果
curl: (7) Failed to connect to 172.19.124.123 port 30678: Connection refused

root@node1:~# kubectl create svc clusterip my-svc-headless --clusterip="None"  #headless svc
service/my-svc-headless created
root@node1:~# kubectl get pods
NAME                  READY   STATUS    RESTARTS   AGE
busybox               1/1     Running   68         2d20h
ng-6446bb48cb-cf7md   1/1     Running   0          2d20h
root@node1:~# kubectl get svc
NAME              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
kubernetes        ClusterIP   10.96.0.1        <none>        443/TCP          2d20h
my-svc-headless   ClusterIP   None             <none>        <none>           5s
my-svc-ng         ClusterIP   10.105.75.216    <none>        80/TCP           90m
my-svc-np         NodePort    10.108.22.156    <none>        1234:30678/TCP   85m

 
root@node1:~# kubectl run hello-nginx --image=nginx
kubectl run --generator=deployment/apps.v1 is DEPRECATED and will be removed in a future version. Use kubectl run --generator=run-pod/v1 or kubectl create instead.
deployment.apps/hello-nginx created

root@node1:~# kubectl expose deployment hello-nginx --type=ClusterIP --name=my-nginx --port=8090 --target-port=80
service/my-nginx exposed

root@node1:~# kubectl get svc
NAME              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
kubernetes        ClusterIP   10.96.0.1        <none>        443/TCP          2d20h
my-nginx          ClusterIP   10.108.29.143    <none>        8090/TCP         6s
my-svc-headless   ClusterIP   None             <none>        <none>           3m5s
my-svc-ng         ClusterIP   10.105.75.216    <none>        80/TCP           93m
my-svc-np         NodePort    10.108.22.156    <none>        1234:30678/TCP   88m

root@node1:~# curl 10.108.29.143:8090
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

root@node1:~# kubectl get endpoints
NAME              ENDPOINTS             AGE
kubernetes        172.19.124.123:6443   2d20h
my-nginx          10.244.0.6:80         61s
my-svc-headless   <none>                4m
my-svc-ng         <none>                94m
my-svc-np         <none>                89m

root@node1:~# kubectl get pods -owide
NAME                           READY   STATUS    RESTARTS   AGE     IP           NODE    NOMINATED NODE   READINESS GATES
hello-nginx-64974c45df-hz4wv   1/1     Running   0          3m15s   10.244.0.6   node1   <none>           <none>

root@node1:~# kubectl exec -it busybox -- nslookup my-nginx
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      my-nginx
Address 1: 10.108.29.143 my-nginx.default.svc.cluster.local

root@node1:~# cat ng.yaml    #为pod添加hostname和subdomain,subdomain就是一个service，svc通过label-selector找到pods
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: hello-nginx
  name: hello-nginx
spec:
  containers:
  - image: nginx
    name: hello-nginx
  restartPolicy: Always
  hostname: hello-nginx
  subdomain: my-svc-headless

root@node1:~# kubectl get svc ng-pods -oyaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: ng-pods
  name: ng-pods
  namespace: default
spec:
  clusterIP: 10.101.41.59
  ports:
  - name: 80-8899
    port: 80
    protocol: TCP
    targetPort: 8899
  selector:   #label-selector关联到后端的pods
    run: hello-nginx
  type: ClusterIP

root@node1:~# kubectl exec -it busybox -- nslookup my-svc-headless
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      my-svc-headless
Address 1: 10.244.0.12 10-244-0-12.my-nginx.default.svc.cluster.local
Address 2: 10.244.0.9 10-244-0-9.my-nginx.default.svc.cluster.local
root@node1:~# kubectl exec -it busybox -- nslookup hello-nginx.my-svc-headless
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      hello-nginx.my-svc-headless
Address 1: 10.244.0.12 10-244-0-12.my-nginx.default.svc.cluster.local
root@node1:~# 
```


---
### 第五课

为何需要存储卷？，普通存储卷，应用中使用普通卷，持久化存储卷（PV),持久化存储卷声明（PVC),应用中使用持久化卷


#### 为什么需要存储卷？

容器部署过程中一般有一下三种数据：
1. 启动时需要的初始数据，可以是配置文件
2. 启动过程中产生的临时数据，该临时数据需要多个容器共享
3. 启动过程中产生的持久化数据

以上三种数据都不希望在容器重启时就消失，存储卷由此而来，它可以根据不同场景提供不能类型的存储能力

valume:hostPath,emptyDir,NFS,Cloud

普通存储卷：没有单独资源对象，与Pod的声明周期一起
  1. 容器启动时依赖数据：configmap,secret;
  2. 临时数据存储：emptyDir,hostPath
  3. 持久化数据存储：nfs,cephfs,GlusterFS,Cloud,...

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: nginx
    name: test-container
    volumeMounts:
    - mountPath: /test-pd
      name: test-volume
    - mountPath: /config-vol
      name: config-vol
    - mountPath: /cache
      name: cache-volume
    - mountPath: /my-secret
      name: foo
  volumes:
  - name: test-volume
    hostPath:
      # directory location on host
      path: /data
      # this field is optional
      type: Directory
  - name: config-vol
    configMap:
      name: log-config #configMap obj name
      items:
        - key: log_level
          path: log_level
  - name: cache-volume
    emptyDir: {}
  - name: foo
    secret:
      secretName: mysecret
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: log-config
  namespace: default
data:
  log_level : debug
---
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  username: YWRtaW4=
  password: MWYyZDFlMmU2N2Rm

```

```bash
root@test-pd:/# ls
bin  boot  cache  config-vol  dev  etc	home  lib  lib64  media  mnt  my-secret  opt  proc  root  run  sbin  srv  sys  test-pd	tmp  usr  var
root@test-pd:/# cat config-vol/log_level 
debugroot@test-pd:/# cat my-secret/
..2019_07_02_13_18_50.321562962/ ..data/                          password                         username                         
root@test-pd:/# cat my-secret/username 
adminroot@test-pd:/# cat my-secret/password  
1f2d1e2e67dfroot@test-pd:/# exit
exit

```


#### 持久化存储卷

存储系统与应用系统区分开，单独资源对象，它不直接和pod发生关系，通过另一个资源对象PVC来绑定关联

PV的生命周期：   
Static/Dynamic: Provisioning->Binding->Using->Releasing->Reclaiming ->Retain/Delete/Recycle   
Available -> Bound -> Released -> Failed


Provisioning: PV的预制创建有两种模式：静态模式和动态模式

静态模式：除创建PVC外，还需要手动创建PV
1. 运维人员预先创建PV，形成PV pool
2. 用户创建PVC，从PV pool找到最适合的



动态模式：只需创建PVC,系统根据PVC自动创建PV

支持的自动创建存储类型，StorageClass,之后用户只需关系PVC，创建工作有系统完成

自动创建本地可以测试吗？是依赖厂商的吧！当创建PVC之后，系统会通过provisioner的存储驱动创建PV 

PsersistentVolumeClaim:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:  #存储访问方式，依赖于存储厂商能力
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 8Gi  #存储大小
  storageClassName: local-class #存储类型
```

StorageClass:
```yaml
# Only create this for K8s 1.9+
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-class
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
# Supported policies: Delete, Retain
reclaimPolicy: Delete
```



作业：
1. 部署一个deployment应用，使用secret普通卷，该应用启动依赖此secret
2. 部署一个statefulset应用，使用持久化卷，通过pvc声明所需要的存储大小10G及访问模式为RWX


---

### 第六课

安全全景图，认证和鉴权，Admissions与安全的持久化保存键值(etcd),Pod SecurityContext(安全上下文)，Network Policy


#### 安全全景


部署态的安全控制：认证、鉴权、Admission(准入控制)、Pod SecurityContext   
运行态的安全控制：Network Policy


#### 认证、鉴权：

```
-->联合认证 --UserInfo-->联合鉴权-->     
     |                    |
     +->401               +->403
```
认证支持多种方式，其中一种认证方式认证通过即通过，输出userinfo;   
基于认证输出的userinfo进行鉴权，鉴权也支持多种方式，常用方式为RBAC;

#### 认证方式：X509、service account、Authenticating Proxy、WebHook、username/passowrd...

常用认证
X509：
1. kube-apiserver的启动参数'--client-ca-file=ca.crt'指定x509根证书，请求中需带由该根证书签名的证书，才能认证通过
2. 客户端签署的证书里含有user、group信息，具体为证书的subject.CommonName(username)以及subject.Organization(group)


```
 -->request-->kube-apiserver X509签名校验-->UserInfo(Name:subject.CommonName,Groups:subject.Orgnization)
```

Service Account:
1. kube-apiserver的启动参数'--service-account-key-file=key.pem'指定pem文件，用以生成bearer token:'--service-account-lookup=true/false'表示在删除service account后其token是否倍吊销
2. service account Admission默认给pod打上service account，当然用户也可以自行指定所需要的service account

 
Token Controller和ServiceAccount Controller

SA controller:list-watch监听命名空间的创建，然后创建一个default service account;
TC: 根据创建的service account,然后创建一个带有token的secret,以vol的方式挂载到pod上；

ServiceAccount Admission给pod默认加上defalut sa对应token secret，挂在到pod上， 也就是在pod内一个路径上保存了token,就可以访问k8s api，即系统资源。

#### 鉴权：RBAC、ABAC、Node以及Webhook

RBAC:Role、RoleBinding、ClusterRole、ClusterRoleBinding


Role和RoleBinding必须是同一个namespace下，Role中定义了可以访问资源的权限，RoleBinding可以bind Role,将认证之后的UserInfo跟刚才的Role绑定起来。RoleBinding也可以根ClusterRole绑定，不过这样是作用于RoleBinding的namespace

ClusterRole和ClusterRoleBinding操作类似于Role和RoleBinding，但作用域集群

Admission(PodSecurityPolicy)
1. kube-apiserver的启动参数‘--admission-control=PodSecurityPolicy‘新增PodSecurityPolicy admission
2. Admin窗户创建PodSecurityPolicy策略，决定能创建什么样的Pod
3. 创建Pod的用户也必须赋予它能使用PodSecurityPolicy策略的权限


#### 安全持久化保存键值(etcd)
1. etcd支持备份回复机制，防止数据倍删除导致数据丢失
2. 用户敏感信息建议存放在secret类型的资源中，该类型资源是加密存储在etcd中
3. etcd支持https,kube-apiserver访问etcd使用https协议

client->server,server->server: 支持tls协议加密，服务端认证客户端证书是否是受信任CA签发，系统自动生成证书

#### 安全上下文


1. 分为Pod级别和容器界别，容器界别的会覆盖Pod界别的相同设置
2. 在有PodSecurityPolicy策略的情况下，两者需要配合使用

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    priviledged: false #是否使用特权容器
    runAsUser: 1000  #指定容器启动UID
    runAsGroup: 3000 #指定Pod中容器文件所属组GID
    fsGroup: 2000
  volumes:
  - name: sec-ctx-vol
    emptyDir: {}
  containers:
  - name: sec-ctx-demo
    image: busybox
    command: [ "sh", "-c", "sleep 1h" ]
    volumeMounts:
    - name: sec-ctx-vol
      mountPath: /data/demo
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: false  #容器的文件系统是否是只读,是否能写挂在的存储，容器本身是只读的
      runAsUser: 1001
      priviledged: false
      capabilities:   #容器系统调用能力配置
        add: ["NET_ADMIN","SYS_TIME"]
        drop: ["SYS_BOOT"]
```


#### Network Policy

本身只是一个接口，实现需要CNI的插件;   
分为Ingress和Egress策略控制，都为白名单：
1. Ingress入口请求控制
2. Egress为出口请求控制

这和Ingress Router不是一个东西，Ingress Router是路由管理，而这里是访问权限名单系统


```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:  #规则匹配器，选择匹配的Pod
      role: db
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:  #远端(访问端)IP白名单开放
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24
    - namespaceSelector: #远端(访问端)namespace白名单开放
        matchLabels:
          project: myproject
    - podSelector:  #远端（访问端）pod白名单开放
        matchLabels:
          role: frontend
    ports:  #本端（被访问端）允许被访问的端口和协议
    - protocol: TCP
      port: 6379
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/24
    ports:
    - protocol: TCP
      port: 5978
```

一些特殊配置
```yaml
# 禁止所有入口请求
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# 允许所有入口请求
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:  #多出来这个，表示任意匹配
  - {}
---
# 禁止所有出口请求
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Egress
---
# 允许所有出口请求
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:  #表示任意匹配
  - {}
```




#### 操作: 
1. Service Account认证方式：
```bash
root@node1:~# kubectl create sa tmp  
serviceaccount/tmp created

root@node1:~# kubectl get sa
NAME      SECRETS   AGE
default   1         3d18h
tmp       1         5s
#创建sa后，自动创建的secret
root@node1:~# kubectl get secret
NAME                  TYPE                                  DATA   AGE
default-token-wxhvp   kubernetes.io/service-account-token   3      3d18h
tmp-token-kzbcr       kubernetes.io/service-account-token   3      73s

root@node1:~# kubectl describe sa tmp
Name:                tmp
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   tmp-token-kzbcr
Tokens:              tmp-token-kzbcr
Events:              <none>

#创建测试用namespace cka
root@node1:~# kubectl create ns cka
namespace/cka created
root@node1:~# kubectl get ns
NAME              STATUS   AGE
cka               Active   4s
default           Active   3d18h
kube-node-lease   Active   3d18h
kube-public       Active   3d18h
kube-system       Active   3d18h
root@node1:~# 

#创建在cka namespace下只读pod的role
root@node1:~# cat role.yaml 
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: cka
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch

#设置user
root@node1:~# kubectl config set-credentials tmp --token=$(kubectl get secret pod-reader-token-gb8qc -ncka -oyaml |grep token:|awk '{print $2}'|base64 -d)
User "tmp" set.
root@node1:~# kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://172.19.124.123:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
- context:
    cluster: internalCluster
    user: tmp
  name: tmp
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: tmp
  user:
    token: eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJja2EiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoicG9kLXJlYWRlci10b2tlbi1nYjhxYyIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJwb2QtcmVhZGVyIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiOGU3NmJkNjctMTMxNC00NDllLTg1NjItODY2YzVhODliYWViIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmNrYTpwb2QtcmVhZGVyIn0.ov6Ddwj-aVo3z6hXWq1vGwBulEHL-3wfBoK65Ef1rlFZ7qgrtVQoI-y_ZDPQavmtCZlj36Oi26GJME_4dXtDA3opgvkcTr-OPcbIS_BGseE24m5SRcceAcQkWfHKf_dmPhch748G7UKWrKBoZe_0c4-Uc3-o-zAOhqSlcQuRWP0UK7aRIZLEKaDWLNWo3blGHAJIiwdlExb2BS9KOOmf0kcPphp571x7fuHRll4AHELgY8FpNxyPMU4VUshOCB4PXNJ53p__NCwprcf5InIyqkjp5s-AtkBxv9nOUSxX5TOI00DHhPQw55PUMVPfYizwr1TqI5hzkW8NuKICDHtccQ

# 切换context否则还是admin权限
# 为tmp设置context，cluster设置成和amdmin一样的，负责无法访问k8s api
root@node1:~# kubectl config set-context tmp --cluster=kubernetes --user=tmp
Context "tmp" modified.
root@node1:~# kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://172.19.124.123:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
- context:
    cluster: kubernetes
    user: tmp
  name: tmp
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: tmp
...

root@node1:~# kubectl config use-context tmp
Switched to context "tmp".
root@node1:~# kubectl get pods
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:cka:pod-reader" cannot list resource "pods" in API group "" in the namespace "default"
root@node1:~# kubectl get pods -ncka
No resources found.
root@node1:~# 
```

2. security context:
```bash
# securityContext设置
root@node1:~# cat scdemo.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  volumes:
  - name: sec-ctx-vol
    emptyDir: {}
  containers:
  - name: sec-ctx-demo
    image: busybox
    command: [ "sh", "-c", "sleep 1h" ]
    volumeMounts:
    - name: sec-ctx-vol
      mountPath: /data/demo
    securityContext:
      privileged: true

root@node1:~# kubectl exec -it security-context-demo   sh
/ # 
#写数据
/ # sysctl -w net.netfilter.nf_conntrack_tcp_timeout_syn_recv=70
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 70
/ # sysctl -a |grep recv
sysctl: error reading key 'net.ipv6.conf.all.stable_secret': Input/output error
sysctl: error reading key 'net.ipv6.conf.default.stable_secret': Input/output error
sysctl: error reading key 'net.ipv6.conf.eth0.stable_secret': Input/output error
sysctl: error reading key 'net.ipv6.conf.lo.stable_secret': Input/output error
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 70

#将容器改为非特权，用具进行为1000，将pod进程设置为1001
root@node1:~# cat scdemo.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  volumes:
  - name: sec-ctx-vol
    emptyDir: {}
  securityContext:
     runAsUser: 1001
     fsGroup: 2000
  containers:
  - name: sec-ctx-demo
    image: busybox
    command: [ "sh", "-c", "sleep 1h" ]
    volumeMounts:
    - name: sec-ctx-vol
      mountPath: /data/demo
    securityContext:
      privileged: false
      runAsUser: 1000
#将priviledged改为false,可以看到只读了
/ $ sysctl -w $(sysctl -a |grep recv|awk '{print $1}')=70
sysctl: error setting key 'net.netfilter.nf_conntrack_tcp_timeout_syn_recv': Read-only file system
#设置pod和容器的用户进程，可以看到容器用户进程覆盖了pod的设置
/ $ ps -ef 
PID   USER     TIME  COMMAND
    1 1000      0:00 sleep 1h
    6 1000      0:00 sh
   23 1000      0:00 ps -ef
#查看挂载的文件，GID为2000
/ $ ls -l /data
total 4
drwxrwsrwx    2 root     2000          4096 Jul  3 05:23 demo
/ $ 
```

3. network policy:  
网络策略通过网络插件来实现，所以用户必须使用支持 NetworkPolicy 的网络解决方案 - 简单地创建资源对象，而没有控制器来使它生效的话，是没有任何作用的。
flaneel不支持networkPolicy这里就不完整演示了


```bash
root@node1:~# cat net.yaml 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 80
root@node1:~# kubectl exec -it busybox sh
/ # ls
bin   dev   etc   home  proc  root  sys   tmp   usr   var
/ # wget 10.244.0.35:80
Connecting to 10.244.0.35:80 (10.244.0.35:80)
index.html           100% |*******************************************************************************************************************************************************************************************|   612   0:00:00 ETA
/ # ls
bin         dev         etc         home        index.html  proc        root        sys         tmp         usr         var
/ # exit
command terminated with exit code 1
root@node1:~# 

#打上标签绑定network policy
root@node1:~# kubectl label pods nginx role=db
pod/nginx labeled
root@node1:~# kubectl label pods nginx --list
role=db
#而busybox并没有role=frontend标签，应该是访问不道的
root@node1:~# kubectl label pod busybox  --list
root@node1:~# 
#但还是访问到了，因为flannel不支持networkpolicy
root@node1:~# kubectl exec -it busybox sh
/ # wget 10.244.0.35:80
Connecting to 10.244.0.35:80 (10.244.0.35:80)
index.html           100% |*******************************************************************************************************************************************************************************************|   612   0:00:00 ETA
/ # exit
command terminated with exit code 1

root@node1:~# 
#为busybox搭上role=frontend标签
root@node1:~# kubectl label pod busybox role=frontend
pod/busybox labeled
root@node1:~# kubectl label pod busybox --list
role=frontend
root@node1:~# kubectl exec -it busybox sh
/ # wget 10.244.0.35:80
Connecting to 10.244.0.35:80 (10.244.0.35:80)
index.html           100% |*******************************************************************************************************************************************************************************************|   612   0:00:00 ETA
/ # exit
command terminated with exit code 1
root@node1:~# 
```
作业：
1. 创建一个Role（只有cka namespace下pods的所有操作权限）和RoleBinding（使用serviceaccount认证鉴权），使用对应serviceaccount作为认证信息对cka namespace下的pod进行操作以及对default namespace下的pods进行操作
2. 部署三个deployment应用(a,b,c),允许a访问b，但不允许c访问b。

---

### 第七课

集群部署及安全配置、节点证书签发、安装network插件、高可用集群、集群升级与备份恢复、E2E测试及结果分析


#### 集群部署及安全配置

Master节点：负责整个集群的管理和控制
1. etcd:存储k8s的资源对象
2. kube-apiserver:作为k8s入口，完成认证鉴权，业务请求的处理
3. kube-controller-manager:应用模型的处理，deployment升级，rs副本个数的管理等
4. kube-scheduler: 给pod选择合适的node节点

Node节点：
1. kubelet: 对apiserver watch-list,监控pod，由运行时启动容器
2. kube-proxy: service这道东西，解决cluster ip互访问题
3. docker: 容器运行时
4. cni插件：打通节点之间的网络，给节点上的pod分配ip


kubelet manifest部署控制节点组件

manifest方式拉起管理面组件，Liveness、Readiness配置组件健康检查

kubelet进程通过systemd进行管理,之后其他组件都可以以mainfest的方式定义，并有kubelet通过容器拉起来。

Static pod，kubelet会一直watch静态pod文件位置，能够感知到manifests变化，然后通过容器运行时启动这些静态pod，manifest启动其他组件方式，就是通过静态pod实现的。


Systemd管理:Docker和kubelet
Kubelet管理：kube-proxy,CNI插件,等
DaemonSet方式部署插件


部署过程：
1. 安装docker、kubectl、kubeadm、kubelet
2. kubeadm init
3. kubelet watch到static pod manifest，然后会拉取镜像，启动这些组件

    配置文件/var/lib/kubelet/config.yaml，找到static pod位置，可以看到这里的其他组件
    ```bash
    root@node1:/etc/kubernetes/manifests# ls
    etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml
    ```
4. 用于node节点加入:kubeadm join --token=0iha3k.dhbclxlqj40qrx6e
    ```bash
    #获取cluster token
    root@node1:/etc/kubernetes/manifests# kubeadm token list
    TOKEN                     TTL         EXPIRES                     USAGES                   DESCRIPTION                                                EXTRA GROUPS
    0iha3k.dhbclxlqj40qrx6e   <invalid>   2019-06-30T15:57:53+08:00   authentication,signing   The default bootstrap token generated by 'kubeadm init'.   system:bootstrappers:kubeadm:default-node-token
    root@node1:/etc/kubernetes/manifests# 
    ```
5. 安装cni,这里选择flannel,之后集群便可以正常使用了
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml
    ```


  
集群中各组件是如何交互的:

Master:
1. kube-apiserver通过etcd-ca、cetcd-certfile、etcd-key访问etcd
2. k8s集群中的组件(kube-proxy、scheduler、kubelet、cm等)是通过kubecfg文件提供client端的认证凭据来访问kube-apiserver

kubecfg:
```bash
root@node1:~# kubectl config view
apiVersion: v1
clusters: #集群的访问方式
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://172.19.124.123:6443  #集群访问地址
  name: kubernetes
contexts: #将集群和客户端认证凭据绑定在一起
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes  #默认访问哪个集群用那个客户端凭据
kind: Config
preferences: {}
users:  #客户端的访问凭据
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
```


生成kubecfg文件


#### tls bootstrap与节点证书签发:
1. kubelet启动时使用低权限token, 向kube-apiserver发送csr请求(证书签发请求)
2. RBAC允许的CRS请求类型，ClusterRole：
    1. nodeclient:签发证书 （kubelet带token启动，只能请求该api）
    2. selfnodeclient: 更新证书
    3. selfnodeserver: 更新kubelet server证书
3. kube-controller-manager根据看到的 请求自动签发证书
4. kubelet使用签发的证书、私钥访问kube-apisever

![bootstrap](../images/20190702-k8s-bootstrap.png)
kubelet 和 kube-apiserver之间的约定token如何配置：
1. kubelet侧通过bootstrap、kubeconfig参数写进去的；
2. api-server使用--enable-bootstrap-token-auth=true 通过secret完成鉴权 或者 通过token-authfile文件，把token写在文件里；鉴权通过clusterrole和clusterrolebinding完成 
```bash
root@node1:~# root@node1:~# kubectl get clusterrole |grep nodeclient
system:certificates.k8s.io:certificatesigningrequests:nodeclient       4d
system:certificates.k8s.io:certificatesigningrequests:selfnodeclient   4d
root@node1:~# kubectl get clusterrolebinding |grep approve
kubeadm:node-autoapprove-bootstrap                     4d
kubeadm:node-autoapprove-certificate-rotation          4d
root@node1:~# 
```
3. controller-manager会自动签发证书,有两个配置项：签证书用到的ca和对应的私钥文件
```bash
root@node1:~# ps -ef |grep kube-controller |grep sign
root     16685 16580  0 Jun29 ?        00:37:51 kube-controller-manager --allocate-node-cidrs=true --authentication-kubeconfig=/etc/kubernetes/controller-manager.conf --authorization-kubeconfig=/etc/kubernetes/controller-manager.conf --bind-address=127.0.0.1 --client-ca-file=/etc/kubernetes/pki/ca.crt --cluster-cidr=10.244.0.0/16 --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt --cluster-signing-key-file=/etc/kubernetes/pki/ca.key --controllers=*,bootstrapsigner,tokencleaner --kubeconfig=/etc/kubernetes/controller-manager.conf --leader-elect=true --node-cidr-mask-size=24 --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt --root-ca-file=/etc/kubernetes/pki/ca.crt --service-account-private-key-file=/etc/kubernetes/pki/sa.key --use-service-account-credentials=true
```
以上三点都具备，集群中新增一个节点的时候，就可以自动的完成证书的签发

CKA考试关于这部分的题是提供一套ca证书和私钥，让你去配置集群，使节点加入可以自动签发证书：
1. 生成一个token文件，写到对应的secret中，api-server设置--enable-bootstrap-token-auth参数;
2. kubelet节点上，把对应的token文件放到默认的bootstrap kubecfg中;controller-manager,配置启动参数--cluster-signing-cert-file和--cluster-signing-key-file 
3. 在集群中手动创建clusterrole和clusterrolebinding,已完成bootstrap的证书签发请求api调用和后边的自动续期


可以修改kube-controller-manager参数，调整证书的有效时间长度
```bash
# kube-controller-manager -h |grep signing-dura
      --experimental-cluster-signing-duration duration   The length of duration signed certificates will be given. (default 8760h0m0s)
```
```bash
# kube-apiserver -h |grep enable
...
      --enable-bootstrap-token-auth                       Enable to allow secrets of type 'bootstrap.kubernetes.io/token' in the 'kube-system' namespace to be used for TLS bootstrapping authentication.
...

root@node1:~# ps -ef |grep kubelet |grep enable
root     16652 16570  1 Jun29 ?        01:27:05 kube-apiserver --advertise-address=172.19.124.123 --allow-privileged=true --authorization-mode=Node,RBAC --client-ca-file=/etc/kubernetes/pki/ca.crt --enable-admission-plugins=NodeRestriction --enable-bootstrap-token-auth=true --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key --etcd-servers=https://127.0.0.1:2379 --insecure-port=0 --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key --requestheader-allowed-names=front-proxy-client --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt --requestheader-extra-headers-prefix=X-Remote-Extra- --requestheader-group-headers=X-Remote-Group --requestheader-username-headers=X-Remote-User --secure-port=6443 --service-account-key-file=/etc/kubernetes/pki/sa.pub --service-cluster-ip-range=10.96.0.0/12 --tls-cert-file=/etc/kubernetes/pki/apiserver.crt --tls-private-key-file=/etc/kubernetes/pki/apiserver.key

 
root@node1:~# kubectl get secret -n kube-system |grep boot
bootstrap-signer-token-7lq5r                     kubernetes.io/service-account-token   3      4d
bootstrap-token-0iha3k                           bootstrap.kubernetes.io/token         7      4d
root@node1:~# kubectl get secret -n kube-system bootstrap-token-0iha3k -oyaml
apiVersion: v1
data:
  auth-extra-groups: c3lzdGVtOmJvb3RzdHJhcHBlcnM6a3ViZWFkbTpkZWZhdWx0LW5vZGUtdG9rZW4=
  description: VGhlIGRlZmF1bHQgYm9vdHN0cmFwIHRva2VuIGdlbmVyYXRlZCBieSAna3ViZWFkbSBpbml0Jy4=
  expiration: MjAxOS0wNi0zMFQxNTo1Nzo1MyswODowMA==
  token-id: MGloYTNr
  token-secret: ZGhiY2x4bHFqNDBxcng2ZQ==
  usage-bootstrap-authentication: dHJ1ZQ==
  usage-bootstrap-signing: dHJ1ZQ==
kind: Secret
metadata:
  creationTimestamp: "2019-06-29T07:57:53Z"
  name: bootstrap-token-0iha3k
  namespace: kube-system
  resourceVersion: "181"
  selfLink: /api/v1/namespaces/kube-system/secrets/bootstrap-token-0iha3k
  uid: 7e00e193-d82b-415c-bda0-eea35aff60f2
type: bootstrap.kubernetes.io/token
root@node1:~# echo " c3lzdGVtOmJvb3RzdHJhcHBlcnM6a3ViZWFkbTpkZWZhdWx0LW5vZGUtdG9rZW4=" |base64 -d
base64: invalid input
root@node1:~# echo "c3lzdGVtOmJvb3RzdHJhcHBlcnM6a3ViZWFkbTpkZWZhdWx0LW5vZGUtdG9rZW4=" |base64 -d
system:bootstrappers:kubeadm:default-node-token
root@node1:~# 


root@node1:~# kubectl get clusterrole |grep nodeclient
system:certificates.k8s.io:certificatesigningrequests:nodeclient       4d
system:certificates.k8s.io:certificatesigningrequests:selfnodeclient   4d
root@node1:~# kubectl get clusterrole system:certificates.k8s.io:certificatesigningrequests:nodeclient 
root@node1:~# kubectl get secret -n kube-system |grep boot
bootstrap-signer-token-7lq5r                     kubernetes.io/service-account-token   3      4d
bootstrap-token-0iha3k                           bootstrap.kubernetes.io/token         7      4d
root@node1:~# kubectl get secret -n kube-system bootstrap-token-0iha3k -oyaml
apiVersion: v1
data:
  auth-extra-groups: c3lzdGVtOmJvb3RzdHJhcHBlcnM6a3ViZWFkbTpkZWZhdWx0LW5vZGUtdG9rZW4=
  description: VGhlIGRlZmF1bHQgYm9vdHN0cmFwIHRva2VuIGdlbmVyYXRlZCBieSAna3ViZWFkbSBpbml0Jy4=
  expiration: MjAxOS0wNi0zMFQxNTo1Nzo1MyswODowMA==
  token-id: MGloYTNr
  token-secret: ZGhiY2x4bHFqNDBxcng2ZQ==
  usage-bootstrap-authentication: dHJ1ZQ==
  usage-bootstrap-signing: dHJ1ZQ==
kind: Secret
metadata:
  creationTimestamp: "2019-06-29T07:57:53Z"
  name: bootstrap-token-0iha3k
  namespace: kube-system
  resourceVersion: "181"
  selfLink: /api/v1/namespaces/kube-system/secrets/bootstrap-token-0iha3k
  uid: 7e00e193-d82b-415c-bda0-eea35aff60f2
type: bootstrap.kubernetes.io/token
root@node1:~# echo " c3lzdGVtOmJvb3RzdHJhcHBlcnM6a3ViZWFkbTpkZWZhdWx0LW5vZGUtdG9rZW4=" |base64 -d
base64: invalid input
root@node1:~# echo "c3lzdGVtOmJvb3RzdHJhcHBlcnM6a3ViZWFkbTpkZWZhdWx0LW5vZGUtdG9rZW4=" |base64 -d
system:bootstrappers:kubeadm:default-node-tokenroot@node1:~# 


root@node1:~# kubectl get clusterrole system:certificates.k8s.io:certificatesigningrequests:nodeclient -oyaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  creationTimestamp: "2019-06-29T07:57:50Z"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
  resourceVersion: "66"
  selfLink: /apis/rbac.authorization.k8s.io/v1/clusterroles/system%3Acertificates.k8s.io%3Acertificatesigningrequests%3Anodeclient
  uid: cb7ca3f2-eaf5-42c0-98c2-a34b5e2f4346
rules:
- apiGroups:
  - certificates.k8s.io
  resources:
  - certificatesigningrequests/nodeclient
  verbs:
  - create

root@node1:~# kubectl get clusterrolebinding |grep appro
kubeadm:node-autoapprove-bootstrap                     4d
kubeadm:node-autoapprove-certificate-rotation          4d
root@node1:~# kubectl get clusterrolebinding kubeadm:node-autoapprove-bootstrap  -oyaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: "2019-06-29T07:57:53Z"
  name: kubeadm:node-autoapprove-bootstrap
  resourceVersion: "184"
  selfLink: /apis/rbac.authorization.k8s.io/v1/clusterrolebindings/kubeadm%3Anode-autoapprove-bootstrap
  uid: e77145e1-580b-49d3-9a86-a012fa1fb596
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:nodeclient #绑定的是刚才的cluster role
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:bootstrappers:kubeadm:default-node-token #user group
root@node1:~# 
  

```  

 总结：首先kubelet通过token访问api-server时，会得到system:bootstrappers:kubeadm:default-node-token 用户组，该用户组绑定了ClusterRole system:certificates.k8s.io:certificatesigningrequests:nodeclient，就拿到了可以创建nodeclient这种类型的csr请求。 也就是kubelet启动时使用该token,只能调用nodeclient csr API。




#### 高可用集群

Master节点的高可用：
1. 三个节点部署etcd集群；
2. kube-apiserver实例部署，作为endpoints挂在loadBalancer下，用keepalived为LB绑定一个虚拟ip,将这个请求发送到LB上，然后负载均衡到apiserver andpoints上；
3. controller-manager和scheduler组件主备部署:主实例通过锁获取etcd操作，备份实例不断尝试获得锁，当可以得到锁时，则替换上;这两个组件这是通过LB访问kube-apiserver的

Node节点：
给kubelet配置LB的地址，通过LB访问kube-apiserver

![k8s-ha](../images/20190702-k8s-ha.png)

#### 集群升级流程

Master升级不希望断服，在升级时依旧可以提供服务,所以一般都是滚动升级的，Master上的组件时通过manifest配置的，所以可以在各节点上<font color=red>逐个替换manifest</font>,之后kubelet会感知到变化，升级组件。

Node节点升级，可以进行kubelet二进制替换，但是可能存在打内核补丁，要重启服务,所以要先将该Node上的<font color=red>pod驱逐</font>到其他Node上，然后进行升级替换，kubectl命令可以直接完成该过程。

Master节点滚动升级：
  1. 升级kubelet
  2. 通过更新manifest升级组件

Node节点升级：
  1. kubectl drain {node name}, 将节点变为不可用状态，然后对pod驱逐，pod会变为failed,之后有scdeduler调度到其他节点上,对于存在deamonSet的，加上--ignore-daemonsets=true，完成pod驱逐
  2. kubectl uncordon, 完成升级后，通过该命令，将节点恢复为可用状态


#### 备份恢复

依赖etcd的原生能力

备份：   
export ETCDCTL_API=3   
etcdctl --endpoints localhost:2379 snapshot save snapshot.db   

恢复：   
etcdctl snapshot restore snapshot.db --name m3 --data-dir=/home/etcd_data   
另外可以指定--cert,--key,--cacert参数


作业：
1. 用kubeadm部署集群，并添加CNI插件
2. bootstrap，cka考试那道题


---

### 第八课

E2E测试及结果分析,管理面异常原因排查，节点异常原因排查，应用异常原因排查，Service访问异常问题排查，常用kubectl命令


#### E2E测试及结果分析

1. 环境准备
    1. local-up-cluster、kubeadm等工具测试集群
    2. ginkgo测试框架
    3. go语言编译环境

2. E2E配置及用例选择
    1. 集群地址 --host
    2. 筛选用例 --ginkgo.ship --ginkgo.focus
  
3. 问题定位    
   关注框架清理环境前打印的定位信息：Namespace Event信息、节点状态及Event信息、Pod状态及Event信息



#### 管理面异常排查

1. Master组件状态查询： kubectl get cs
2. 进程不存在：
    1. 明确组件声明周期管理方式
    2. 故障检测方式是否有效(livenessProbe,restartPolicy)
    3. 重启进程

3. 进程crash：分析日志
4. 组件功能异常：分析日志、检查依赖组件是否正常


```bash
root@node1:~# kubectl get cs
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok                  
controller-manager   Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   
```

如何确定日志位置：
1. 查看进程启动参数，ps -ef
2. kube命令 --help,查看帮助文档，找到默认日志位置
3. docker标准输出，分析日志
4. 若组件用systemd管理，可以用journalclt查看系统组件日志

#### 节点异常原因排查

1. 节点状态查询： kubectl get nodes
2. 常见异常现象：
    1. 节点状态为NotReady
    2. 调度到该节点上的Pod显示NodeLost、Unknown、Pending等状态
3. 常见故障：
    1. kubelet进程异常
    2. 未安装cni插件
    3. docker异常
    4. 磁盘空间不足
    5. 内存不足
4. 定位方式：
    1. kubectl describe nodes查看异常事件,kubectl get nodes node1 -oyaml查看node具体情况
    2. service status查看系统进程状态
    3. journalctl 查看系统组件日志
    4. top查看系统cpu、内存
    5. du、df查看磁盘使用情况,主要是docker image占用等


#### 应用异常原因排查

应用模型异常：
1. 已存在的pod数超过resource-quota限制：kubectl desribe quota -n $(ns)
2. 待创建的pod不满足admission controller限制: 查看kube-apiserver enable-admission-plugins参数启动了哪些ac
3. DaemonSet找不到符合要求的节点：
    1. kubectl describe ds -n $(ns)
    2. 查看ds的nodeSelector
    3. 查看节点taints

4. StatefulSet:
    1. podManagementPolicy
    2. serviceName
    3. volumeClaimTemplates
  
pod实例异常：
1. 状态检查：kubectl get/describe pod
2. Pending:
    1. 可用资源不足：describe pod可看到调度失败event
    2. 不满足亲和性策略
    3. 节点有taints

3. Waiting:
    1. 镜像下载失败
    2. 配置的imagePullSecret无法通过认证，查看环境是否存在可用的dockerConfigjson类型的secret
    3. imagePullPolicy配置是否正确

4. CrashBackoff:
    1. kubectl logs查看容器日志
    2. kubectl/docker exec登录容器验证功能
    3. 检查pod配置是否正确：command、liveness、readiness


#### Service访问异常原因排查

1. 通过域名访问Service,nslookup判断域名解析是否正常
2. 没有Endpoint：
    1. kubectl -n ${ns} get endpoints ${service-name}
    2. kubectl -n ${ns} get pods --selector=${service-selector}
    3. 查看pod status是否为ready状态
    4. 查看service port定义与pod定义是否匹配

3. Endpoint访问不同：
    1. kube-proxy是否运行正常，依赖的contrack是否安装
    2. 查看kube-proxy配置参数，确认mode类型，查看转发规则是否正确
        1. userspace:   
          iptables-save |grep ${servicename}   
          KUBE-PORTALS-CONTAINER、KUBE-PORTALS-HOST
        2. iptables: 
          iptables-save |grep ${servicename}   
          KUBE-SVC-XXX、KUBE-SEP-XXX
        3. ipvs: ipvsadm -ln

常用命令：kubectl -h,kuectl explain