### k8s调度器原理剖析与实践

k8s调度机制介绍、k8s中的调度策略与算法、k8s高级调度特性详解


Scheduler: 为Pod找到一个合适的Node?

调度器的特点是，所处理的是Pod，它的输入就是不断的从集群中获取可用的节点，以及集群中有哪些带调度的pod，经过调度器的处理将pod调度到合适的节点上；
从yaml文件看，经过调度器处理后，填入了NodeName


default scheduler:
1. 基于队列的调度器
2. 一次调度一个pod
3. 调度时刻全局最优的节点

从外部流程看调度器，从pod创建到pod被bind结束



![k8s-watch-list](../images/20190702-k8s-watch-list.png)

调度器内部流程：
1. 通过NodeLister获取所有节点信息；
2. 整合scheduled pods和assume pods，合并到pods,作为所有已调度pod信息；
3. 从pods中整理出node-pods的对应关系表nodeNameToInfo;
4. 过滤不合适节点；
5. 给剩下的节点依次打分；
6. 在分数最高的nodes中随机选择一个即节点用于绑定。这是为了避免分数最高的节点被几次调度撞车


#### k8s中的调度策略与算法

Predicates:过滤类的；Priorities:评分类

通过Predicate策略筛选符合条件的Node，过滤“不合格”节点，避免资源冲突、节点超载



GeneralPredicates: 包含三项基本检查：节点、端口、规则
PodToleratesNodeTaints: 检查Pod是否能够



通过Priority策略给剩余的Node评分，挑选最优的节点，挑选“优质”节点，优化资源分配、应用分布


#### k8s高级调度特性

label&selector

任意的metadata,所有api对象都有label,通常用来标记“身份”，可以查询时用selector过滤，类似sql'select ... where'

Node Affinity让pod在一组指定Node上运行

Pod Affinity 让pod与指定service的一组pod在相同node上运行

#内置的key,topologyKey: "hostname"

Pod Anfti-Affinity 让通一个Service的pod分散到不同Node上运行

Taints-tolerations 来自Node的反亲和和配置

