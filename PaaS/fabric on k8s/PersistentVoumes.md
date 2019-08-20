### Persistent Volumes

#### introduce
PersistentVolume子系统为用户和管理员提供一套将系统底层存储细节抽象的api，涉及两类API资源:PersistentVolume和PersistentVolumeClaim.

PersistentVolume(pv)是由集群管理员提供的一种存储，它和node一样是一种集群资源。PVs是一种类似Volumes的存储插件，但是它具有独立于pod的生命周期。PV 的存储实现方式有NFS、iSCSI以及云提供商制定的存储系统。

PersistentVolumeClaim(PVC)是一个存储请求，它类似于pod，pod消耗node资源，而pvc消耗pv资源；Pod能够请求指定级别的cpu和memory资源，pvc可以请求制定大小和获取模式(支持once read/write 和many times read only)的pv。

用户一般会用PVC去申请不同规格的PV，这些不同规格的PV应该集群管理员，这样就为用户屏蔽了底层存储实现的细节，而对应的规格是由另一种资源SotrageClass定义的。

在搭建kafaka/zookeeper集群时，stateful set需要动态绑定pv,一般动态绑定pv是需要云服务提供商的服务，本地需要另做处理。


#### lifecycle of a lolume and claim

**Provisioning阶段**：

PVs由两种管理方式，static和dynamic。

static：集群管理员会创建大量的PV,静态方式会将存储细节暴露给集群用户，方便用户通过集群api使用存储。其实，觉得这更适合k8s的学习、开发者用。

dynamic: 当没有静态的PVs匹配用户的PVC时，集群就会尝试动态的为PVC提供一个数据卷。这种动态分配基于StorageClasses:PVC必须制定一个strage class,管理员必须创建PV时，必须配置storage class。在动态分配数据卷下，PVC通过storage class和数据卷联系。


**Binding**:

用户创建动态方式的PVC后，该PVC指定了所需的access mode。master上的控制循环会监视到新的PVC,如果有匹配的PV，就会绑定他们。一个PV如果被分配给一个PVC，控制循环将始终绑定该PV\PVC。一般用户会得到比他们申请规格大的数据卷。PV/PVC的绑定时排他的，这种绑定关系时一一映射的。

**Using**:

Pods使用claims获取存储,集群通过claims找到PVC/PV绑定，为pod挂在PV数据卷。数据卷支持多种访问模式，用户可以使用claims在pods上指定访问模式。

**Reclaiming**
 
当用户使用完他们的数据卷后，便可删除PVC对象，k8s API允许回收该数据卷。PersistentVolume的声明告诉集群在释放claim后应该怎么做。目前数据卷可以被Retained、Recycled和Deleted。

Retain（保留）:

Retain回收策略允许手动回收数据卷。当PVC被删除后，PV仍然存在，在pod看来，数据卷似乎被释放了，但该PV对于对于其他PVC仍是不可用的，因为之前使用者的数据还在数据卷里。管理员可以通过如下步骤手动回收该数据卷：
1. 删除PV,对于外部基础设施提供的相关存储在PV删除后，仍然存在。
2. 手动清理关联的存储上的数据。
3. 手动删除关联的存储，如果想重新使用该存储，可以创建一个指定该存储的PV。

Delete:

Delete回收策略会同时删除PV及对应的存储。动态配置的卷集成StorageClass的回收策略，其默认Delete，管理原应该为用户的期望来配置StorageClass，否则只能在卷创建后进行编辑和修补。

Recycle:

如果底层的存储卷插件支持，那Recycle回收策略会在该卷上执行基本的擦洗（rm -rf /thevolume/*)使其可被新的PVC使用。
然而，管理员也可以配置一个自定义的回收pod模版通过k8s控制管理命令擦洗卷。