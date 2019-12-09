### 在k8s上搭建kfk-zk集群(2)

这篇接zk的部署方式，整体结构是一样的，包括StorageClass、PV、HeadlessService、StatefulSet，不同的是kfk本身的配置，k8s官方没有k8s的部署教程，我在网上找到一个在k8s上部署kfk的帖子，借用其kfk的模版。

StorageClass我们已经创建，直接使用local-class。
```bash
root@hw1:~/zk# kubectl get storageclass
NAME          PROVISIONER                    AGE
local-class   kubernetes.io/no-provisioner   18h
```

上次仅仅创建了三个PVs,不够用，这里我们为kfk也创建三个PVs，```kubectl create -f pv-kfk.yaml```。
```yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: datadir-kfk-1
  labels:
    type: local
spec:
  storageClassName: local-class
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data11"
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: datadir-kfk-2
  labels:
    type: local
spec:
  storageClassName: local-class
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data22"
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: datadir-kfk-3
  labels:
    type: local
spec:
  storageClassName: local-class
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data33"
```

kfk模板借用[Kafka on Kubernetes Deploy a highly available Kafka cluster on Kubernetes.](https://imti.co/kafka-kubernetes/#kafka-service)中kfk部分，修改kfk的spec.volumeClaimTemplates.spec.storageClassName为之前的local-class,以及kfk连接zk的参数 KAFKA_ZOOKEEPER_CONNECT为zk-cs:2181。
```kubectl create -f kfk.yaml```。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka
spec:
  ports:
  - name: broker
    port: 9092
    protocol: TCP
    targetPort: kafka
  selector:
    app: kafka
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: kafka-headless
spec:
  clusterIP: None
  ports:
  - name: broker
    port: 9092
    protocol: TCP
    targetPort: 9092
  selector:
    app: kafka
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app: kafka
  name: kafka
spec:
  podManagementPolicy: OrderedReady
  replicas: 3
  revisionHistoryLimit: 1
  selector:
    matchLabels:
      app: kafka
  serviceName: kafka-headless
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - command:
        - sh
        - -exc
        - |
          unset KAFKA_PORT && \
          export KAFKA_BROKER_ID=${HOSTNAME##*-} && \
          export KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://${POD_IP}:9092 && \
          exec /etc/confluent/docker/run
        env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.podIP
        - name: KAFKA_HEAP_OPTS
          value: -Xmx1G -Xms1G
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: zk-cs:2181
        - name: KAFKA_LOG_DIRS
          value: /opt/kafka/data/logs
        - name: KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR
          value: "3"
        - name: KAFKA_JMX_PORT
          value: "5555"
        image: confluentinc/cp-kafka:4.1.2-2
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
            - sh
            - -ec
            - /usr/bin/jps | /bin/grep -q SupportedKafka
          failureThreshold: 3
          initialDelaySeconds: 30
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 5
        name: kafka-broker
        ports:
        - containerPort: 9092
          name: kafka
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          initialDelaySeconds: 30
          periodSeconds: 10
          successThreshold: 1
          tcpSocket:
            port: kafka
          timeoutSeconds: 5
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /opt/kafka/data
          name: datadir
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 60
  updateStrategy:
    type: OnDelete
  volumeClaimTemplates:
  - metadata:
      name: datadir
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: "local-class"
      resources:
        requests:
          storage: 1Gi
```

查看部署情况
```bash
root@hw1:~/zk# kubectl get pods
NAME                READY   STATUS    RESTARTS   AGE
busybox             1/1     Running   20         20h
kafka-0             1/1     Running   9          18h
kafka-1             1/1     Running   0          18h
kafka-2             1/1     Running   0          18h
zk-0                1/1     Running   0          18h
zk-1                1/1     Running   0          18h
zk-2                1/1     Running   0          18h
root@hw1:~/zk# kubectl get pvc
NAME              STATUS   VOLUME          CAPACITY   ACCESS MODES   STORAGECLASS   AGE
datadir-kafka-0   Bound    datadir-kfk-1   5Gi        RWO            local-class    18h
datadir-kafka-1   Bound    datadir-kfk-2   5Gi        RWO            local-class    18h
datadir-kafka-2   Bound    datadir-kfk-3   5Gi        RWO            local-class    18h
datadir-zk-0      Bound    datadir1        5Gi        RWO            local-class    18h
datadir-zk-1      Bound    datadir2        5Gi        RWO            local-class    18h
datadir-zk-2      Bound    datadir3        5Gi        RWO            local-class    18h
root@hw1:~/zk# kubectl get pv
NAME            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                     STORAGECLASS   REASON   AGE
datadir-kfk-1   5Gi        RWO            Retain           Bound    default/datadir-kafka-0   local-class             18h
datadir-kfk-2   5Gi        RWO            Retain           Bound    default/datadir-kafka-1   local-class             18h
datadir-kfk-3   5Gi        RWO            Retain           Bound    default/datadir-kafka-2   local-class             18h
datadir1        5Gi        RWO            Retain           Bound    default/datadir-zk-0      local-class             18h
datadir2        5Gi        RWO            Retain           Bound    default/datadir-zk-1      local-class             18h
datadir3        5Gi        RWO            Retain           Bound    default/datadir-zk-2      local-class             18h
root@hw1:~/zk# 
```

接着，测试kfk是否连接上zk,能够正常的生产消费，同样借用上述老哥的kfk-test-pod，```kubectl create -f pod-test.yaml```。
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kafka-test-client
spec:
  containers:
  - command:
    - sh
    - -c
    - exec tail -f /dev/null
    image: confluentinc/cp-kafka:4.1.2-2
    imagePullPolicy: IfNotPresent
    name: kafka
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
```

查看topic,并创建test topic。
```bash
root@hw1:~/zk# kubectl exec  kafka-test-client -- /usr/bin/kafka-topics --zookeeper zk-cs:2181 --list
__confluent.support.metrics
root@hw1:~/zk# kubectl exec  kafka-test-client -- /usr/bin/kafka-topics --zookeeper zk-cs:2181 --topic test --create --partitions 1 --replication-factor 1
Created topic "test".
```

启动在topic=test的生产者进程，并写入hello world消息。
```bash
root@hw1:~# kubectl exec -it kafka-test-client --  /usr/bin/kafka-console-producer  --broker-list kafka:9092 --topic test
>hello
>world
>
```

启动消费者，查看topic=test上的消息。
```bash
root@hw1:~#  kubectl exec  kafka-test-client -- /usr/bin/kafka-console-consumer  --bootstrap-server kafka:9092 --topic test --from-beginning

hello
world
```

至此，zk/kfk都已经部署完成。


参考资料：

1. [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
2. [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
3. [Kafka on Kubernetes Deploy a highly available Kafka cluster on Kubernetes.](https://imti.co/kafka-kubernetes/#kafka-service
)
---

接下来，我们要利用zk/kfk集群，部署fabric with kafka consensus。


