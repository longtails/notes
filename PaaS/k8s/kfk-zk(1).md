### 在k8s上搭建kfk-zk集群(1)

kfk/zk属于有状态的应用，所以应当用StatefulSet来部署应用，但StatefulSet要比无状态的Deployment要复杂，主要表现在增加了：

1. stable stroage，并且需要用StorageClass、PV
2. 有状态应用的网络问题，需要Headless Service,并且每个pod是有序编号的，其DNS就是name-1.headlessService

这里，我们采用[官方部署zk的教程](https://kubernetes.io/zh/docs/tutorials/stateful-application/zookeeper/),该教程有个前提（新手一般想打它）
> This tutorial assumes that you have configured your cluster to dynamically provision PersistentVolumes. If your cluster is not configured to do so, you will have to manually provision three 20 GiB volumes before starting this tutorial.

这就给我们带来了一点麻烦,主要是创建PV以及如何让StatefulSet能够绑定我们创建的PV。那么，我们的工作就是创建PV，以及如何让StatefulSet绑定它们。

StatefulSet使用spec.volumeClaimTemplates为其pod创建PVC以此绑定PV。回想，之前PVC通过name的方式手动绑定到PV，但，这里肯定不行的，一个StatefulSet管理多个Pod,每个Pod都以自己的PVC,如果通过名字，那它们都会去找同一个PV,一个PV只能有一个PVC绑定，其他PVC就会处于pendding状态；这时，我们再看官方[StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)页的demo，会发现有个storageClassName，在Stable Storage下也说明了，StatefulSet创建的PVC是通过storageClassName的方式找到PV的，回到官方部署zk的教程，demo中storageNameClassName是缺失的，即，使用的是默认的StorageClass。

>If no StorageClass is specified, then the default StorageClass will be used

至此，理解了k8s使用storageClass绑定pvc/pv的设计，也知道在statefulSet中如何使用，但，我们实验要简单，查阅资料storageClass大多是云厂商provisioner,可实验的是NFS和local，当然local更简单，但有个支持版本问题。
> FEATURE STATE: Kubernetes v1.14
实验使用的是1.14.2集群，看下local-storageClass.yaml,```kubectl create -f local-storageClass.yaml```创建storageClass。
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
```bash
root@hw1:~/zk# kubectl get storageclass
NAME          PROVISIONER                    AGE
local-class   kubernetes.io/no-provisioner   17h
```
接着，我们要创建属于local-class的PVs,为简单，使用本机文件作为存储，spec.storageClassName指定为上边创建的local-class，之后在statefulSet指定的PVC中指定该storageClass即可。这样操作简单，但为了方便管理以及生产，可以考虑NFS、甚至云服务商的PV。

```kubectl -f pv-zk.yaml```创建三个PVs。
```yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: datadir1
  labels:
    type: local
spec:
  storageClassName: local-class
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data1"
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: datadir2
  labels:
    type: local
spec:
  storageClassName: local-class
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data2"
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: datadir3
  labels:
    type: local
spec:
  storageClassName: local-class
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data3"
```

最后，我们要对官方的zk demo进行修改，将其spec.volumeClaimTemplates.storageClassName指定为lacal-class。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: zk-hs
  labels:
    app: zk
spec:
  ports:
  - port: 2888
    name: server
  - port: 3888
    name: leader-election
  clusterIP: None
  selector:
    app: zk
---
apiVersion: v1
kind: Service
metadata:
  name: zk-cs
  labels:
    app: zk
spec:
  ports:
  - port: 2181
    name: client
  selector:
    app: zk
---
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: zk-pdb
spec:
  selector:
    matchLabels:
      app: zk
  maxUnavailable: 1
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zk
spec:
  selector:
    matchLabels:
      app: zk
  serviceName: zk-hs
  replicas: 3
  updateStrategy:
    type: RollingUpdate
  podManagementPolicy: OrderedReady
  template:
    metadata:
      labels:
        app: zk
    spec:
      containers:
      - name: kubernetes-zookeeper
        imagePullPolicy: Always
        #image: k8s.gcr.io/kubernetes-zookeeper:1.0-3.4.10
        image: gcr.azk8s.cn/google_containers/kubernetes-zookeeper:1.0-3.4.10
        resources:
          requests:
            memory: "1Gi"
            cpu: "0.2"
        ports:
        - containerPort: 2181
          name: client
        - containerPort: 2888
          name: server
        - containerPort: 3888
          name: leader-election
        command:
        - sh
        - -c
        - "start-zookeeper \
          --servers=3 \
          --data_dir=/var/lib/zookeeper/data \
          --data_log_dir=/var/lib/zookeeper/data/log \
          --conf_dir=/opt/zookeeper/conf \
          --client_port=2181 \
          --election_port=3888 \
          --server_port=2888 \
          --tick_time=2000 \
          --init_limit=10 \
          --sync_limit=5 \
          --heap=512M \
          --max_client_cnxns=60 \
          --snap_retain_count=3 \
          --purge_interval=12 \
          --max_session_timeout=40000 \
          --min_session_timeout=4000 \
          --log_level=INFO"
        readinessProbe:
          exec:
            command:
            - sh
            - -c
            - "zookeeper-ready 2181"
          initialDelaySeconds: 10
          timeoutSeconds: 5
        livenessProbe:
          exec:
            command:
            - sh
            - -c
            - "zookeeper-ready 2181"
          initialDelaySeconds: 10
          timeoutSeconds: 5
        volumeMounts:
        - name: datadir
          mountPath: /var/lib/zookeeper
      securityContext:
        #runAsUser: 1000
        fsGroup: 1000
  volumeClaimTemplates:
  - metadata:
      name: datadir
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "local-class"
      resources:
        requests:
          storage: 1Gi
```


```kubectl exec -it zk.yaml```启动ZKs。查看zk状态，并进行测试。

```bash
root@hw1:~/zk# kubectl get pods
NAME                READY   STATUS    RESTARTS   AGE
busybox             1/1     Running   19         19h
zk-0                1/1     Running   0          17h
zk-1                1/1     Running   0          17h
zk-2                1/1     Running   0          17h

root@hw1:~/zk# kubectl get pv
NAME            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                     STORAGECLASS   REASON   AGE
Bound    default/datadir-kafka-2   local-class             17h
datadir1        5Gi        RWO            Retain           Bound    default/datadir-zk-0      local-class             17h
datadir2        5Gi        RWO            Retain           Bound    default/datadir-zk-1      local-class             17h
datadir3        5Gi        RWO            Retain           Bound    default/datadir-zk-2      local-class             17h
root@hw1:~/zk# kubectl get pvc
NAME              STATUS   VOLUME          CAPACITY   ACCESS MODES   STORAGECLASS   AGE
datadir-zk-0      Bound    datadir1        5Gi        RWO            local-class    17h
datadir-zk-1      Bound    datadir2        5Gi        RWO            local-class    17h
datadir-zk-2      Bound    datadir3        5Gi        RWO            local-class    17h 
```

查看zk的状态
```bash
root@hw1:~/zk# for i in 0 1 2; do kubectl exec zk-$i -- hostname; done
zk-0
zk-1
zk-2
root@hw1:~/zk# for i in 0 1 2; do echo "myid zk-$i";kubectl exec zk-$i -- cat /var/lib/zookeeper/data/myid; done
myid zk-0
1
myid zk-1
2
myid zk-2
3
root@hw1:~/zk# for i in 0 1 2; do kubectl exec zk-$i -- hostname -f; done
zk-0.zk-hs.default.svc.cluster.local
zk-1.zk-hs.default.svc.cluster.local
zk-2.zk-hs.default.svc.cluster.local
root@hw1:~/zk# kubectl exec zk-0 -- cat /opt/zookeeper/conf/zoo.cfg
#This file was autogenerated DO NOT EDIT
clientPort=2181
dataDir=/var/lib/zookeeper/data
dataLogDir=/var/lib/zookeeper/data/log
tickTime=2000
initLimit=10
syncLimit=5
maxClientCnxns=60
minSessionTimeout=4000
maxSessionTimeout=40000
autopurge.snapRetainCount=3
autopurge.purgeInteval=12
server.1=zk-0.zk-hs.default.svc.cluster.local:2888:3888
server.2=zk-1.zk-hs.default.svc.cluster.local:2888:3888
server.3=zk-2.zk-hs.default.svc.cluster.local:2888:3888
root@hw1:~/zk# 

```


参考资料：
1. [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
2. [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/#local)
3. [Running ZooKeeper, A Distributed System Coordinator](https://kubernetes.io/docs/tutorials/stateful-application/zookeeper/)



---

由于篇幅关系，kafka部分分在下一篇记录。


