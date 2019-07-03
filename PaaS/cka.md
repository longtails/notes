## k8s复习笔记


面向k8s管理员的认证项目，考核日常运维k8s集群所需的知识、技能、熟练度。

---

### 第一课

基础概念，调度，网络，存储，问题排查，安全，日志、监控与应用管理，集群安装运维与安装配置

本质上是一种list-watch的工作方式；



k8s整体架构：master-slave

master: scheduler->apiserver(一大堆控制器，Endpoints、node、repulicate)-> etcd

slave: kubelet(负责pod被调度之后完整的生命周期)、kube-proxy(负责service和endpoints的生命周期，负责loadbalance的规则)


工作原理，本质上是list-wath的工作方式，可以认为一种消息通知的方式

不同的组件对象，处理的是不同的api对象，或者某个对象不同的生命周期,所有组件与apiserver交互屏蔽了与底层的etcd的接触，每次接收到的变化都存到etcd中去

创建对象：  

0. 集群启动，各个组件controller-manager、scheduler、kubelet都会和API-server发起watch请求，建立链接
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

