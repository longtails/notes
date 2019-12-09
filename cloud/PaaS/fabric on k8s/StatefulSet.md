### Stateful Set

在k8s上部署有状态的应用是通过StatefulSets实现的。这里我们尝试部署官网的Stateful Set demo，为kfk/zk的部署做前期实验。


像Deployment一样，StatefulSet也是基于容器特定的标识来管理Pod的，不一样的是StatefulSet会为每个pod保持一个标识。StatefulSet下创建的pod具有相同的配置，但每个pod都有一个持久的标志，正是该标志可以保证pod部署和scale的顺序。

StatefulSets是用来解决有状态的应用的，比如：
1. 稳定的网络标识
2. 稳定的持久化存储
3. 有序部署、有序扩容
4. 有序收缩、有序删除

StatefulSets的使用限制：
1. StatefulSet在1.9之前是beta资源，在1.5之前是不可用的
2. Pod的存储必须由PersistentVolume Provisioner根据请求的storage class配置，或者由管理员预先配置。
3. 删除或者收缩不会删除与其相关的数据卷，其目的是保证数据安全，一般是比自动清除数据要可靠些。
4. 为了Pods的网络表识，StatefulSets要求创建Headless Service。
5. StatefulSet被删除，其不保证中止pods,为了有序平滑的中止pods,应该收缩StatefulSet到0，最后删除StatefulSet。
6. 在使用默认Pod管理策略（orderedReady)进行滚动升级是，可能会进入异常状态，这需要手动干预修复。

Components:

StatefulSet配置需要如下几个组件：
1. Headless Service，用来控制网络域名。
2. spec要制定副本数，以启动对应数量的pods。
3. volumeClaimTemplates,使用供应商提供的PV来提供稳定存储。




Pod Identity:

StatefulSet中的每个pod拥有一个独特的表识，包含有序索引、稳定的网络表识，稳定存储。

ordinal index：n个副本，索引则从0到n-1。
stable network id:pod的主机名为\$(statefulset name)-\$(ordinal),StatefulSet的域名为\$(service name).\$(namespace).svc.cluster.local。（cluster.local为集群域名），在pod创建后，会匹配一个DNS子域名：\$(podname).\$(service name)。

Stable storage:

k8s为每个VolumeClaimTemplate创建一个pv,pod会收到制定StorageClass和规格的pv,如果StorageClass没有指定，会使用默认的StorageClass。当pod被调度到node上，其volumeMounts会挂在pvc指定的pv。在StatefulSet/pod被删除后，其关联的pv不会自动删除，需要用户手动删除。

Pod Name Label:

StatefulSet控制器创建一个Pod，就会为其添加 statefulset.kubernetes.io/pod-name 标签，可以通过该标签在指定的pod上附着Service。


**创建有状态的应用：**

实践，在自己搭建的集群上，因为没有pv provisioner,所以我们需要使用本地的存储,在volumeClaimTemplates上使用自定义的storageClass,provisioner要设置为 kubernetes.io/no-provisioner;创建指定storageClass的pv;创建有状态的应用，通过storageClass使用对应的pv。

storageClass:
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
pv:
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

nginx web，一个有状态的应用：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: nginx # has to match .spec.template.metadata.labels
  serviceName: "nginx"
  replicas: 3 # by default is 1
  template:
    metadata:
      labels:
        app: nginx # has to match .spec.selector.matchLabels
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: k8s.gcr.io/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "local-class"
      resources:
        requests:
          storage: 1Gi

```

测试:
```bash
root@hw1:~/k8s/stateful# kubectl get pods
NAME           READY   STATUS    RESTARTS   AGE
busybox        1/1     Running   181        7d13h
busybox-curl   1/1     Running   45         45h
web-0          1/1     Running   0          45h
web-1          1/1     Running   0          45h
web-2          1/1     Running   0          45h
root@hw1:~/k8s/stateful# kubectl get statefulset
NAME   READY   AGE
web    3/3     45h
root@hw1:~/k8s/stateful# kubectl get pvc
NAME        STATUS   VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
www-web-0   Bound    datadir    5Gi        RWO            local-class    45h
www-web-1   Bound    datadir1   5Gi        RWO            local-class    45h
www-web-2   Bound    datadir2   5Gi        RWO            local-class    45h
root@hw1:~/k8s/stateful# kubectl get pv
NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM               STORAGECLASS   REASON   AGE
datadir    5Gi        RWO            Retain           Bound       default/www-web-0   local-class             45h
datadir1   5Gi        RWO            Retain           Bound       default/www-web-1   local-class             45h
datadir2   5Gi        RWO            Retain           Bound       default/www-web-2   local-class             45h
datadir3   5Gi        RWO            Retain           Available                       local-class             45h


root@hw1:~/k8s/stateful# kubectl exec -it busybox-curl -- nslookup nginx
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      nginx
Address 1: 10.244.0.23 web-0.nginx.default.svc.cluster.local
Address 2: 10.244.0.25 web-2.nginx.default.svc.cluster.local
Address 3: 10.244.0.24 web-1.nginx.default.svc.cluster.local
root@hw1:~/k8s/stateful# kubectl exec -it busybox-curl -- nslookup web-0.nginx
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      web-0.nginx
Address 1: 10.244.0.23 web-0.nginx.default.svc.cluster.local

```