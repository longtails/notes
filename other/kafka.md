### 消息服务KAFKA

为何需要消息服务？为云服务提供统一通信

基于消息中间件构建消息服务，解决云分布式场景的消息通信问题，提供高可靠、高性能（高并发、高吞吐）、高可扩展的消息管道。

消息中间件是指支持与保障分布式应用程序之间同步/异步收发消息的中间件。通过消息中间件，应用程序或组件之间可以进行可靠的异步通信来降低系统之间的耦合度，从而提高整个系统的可扩展行和可用性。


kafka: 一种分布式、基于发布/订阅的消息中间件

1. 高性能、高吞吐：顺序写盘、消息压缩
2. 在线扩容：分区机制，在线扩容；副本在线扩容；节点在线扩容
3. 高可靠：集群部署、多副本机制：多副本机制，支持在线扩容；支持分区在线迁移


broker: kfk集群包含一个或多个服务实例，这种服务实例被成为broker
topic: 每条发布到kfk集群的消息都有一个类别，这个类别被称为topic  
partition: partition是无力上的概念，每个topic包含一个或多个partition  
producer: 负责发布消息到kafka broker  
consumer: 消息消费者，向kafka broker读取消息的客户端  
consumer group: 每个consumer属于一个特定的consumer group（可为每个consumer制定group name，否则属于默认的group)  



kafka批量生产机制

客户端通过异步接口发送消息，消息首先在客户端根据分区打包；  
发送线程根据分区leader所在broker，把多个batch组成一个请求，打包发送；  
2个参数控制打包速度：当batch。size达到或者linger.ms时间达到；   

批量发送包的大小越大吞吐量越高，但是延迟也相应增大


kafka分区副本

 
kafka通过副本方式达到高可用的目标，每个分区可以有1个或者多个副本，分别分配在不同的节点上；  
多个副本之间只有一个leader,其他副本通过pull模式同步leader消息，处于同步状态的副本集合成为ISR;      
生产者和消费者都只能从leader写入或者读取数据，leader故障后，会优先从ISR集合中选择副本作为leader;  
ISR同步副本的集合。


kafka-partition and offset

每个分区消息只能通过追加消息方式增加消息，消息都有一个偏移量（offset),顺序写入确保性能高效  
消费者通过分区中offset定位消息和记录消费的位置  

kafka 消费者组与分区

每个消费者都属于一个消费组内，通过消费组概念可以实现topic消息的广播（发给所有消费组）或者单播（组内消息均衡分担）    
消费者采用pull模式进行消费，方便消费进度记录在客户端，服务端无状态   
组内的消费者以topic分区个数进行均衡分配，所以组内消费者最多只能有分区个数的消费者  

kafka消费机制

每个消费组里面的消费者都需要先查找一个协调者  
消费者加入到这个组内，主要目的是为了对分区进行分区  
分配分区完毕后，再查找各自分区的leader，进行消费


kafka高可靠机制

分布式系统下，单点故障不可避免，kafka如何管理节点故障？  
从kafka的broker中选择一个节点作为分区管理与副本状态变更的控制，成为controller  
统一侦听zk元数据变化，通知各节点状态信息；  
管理broker节点的故障恢复，对古装节点所在分区进行重新leader选举，帮助业务故障切换到新的leader  

如果Controller节点本身故障？   
各个broker节点通过watch zk的/controller节点，如果controller故障，会触发节点进行争夺创建/controller节点，创建上的节点成为新controller  


---

KFK生产机制


生产模型、参数调优、代码示例、操作实战

生产模型：批量+异步

Record Accumulator(本地缓存):同一个partition的消息会被打包成一个batch（batchSize,linger.ms)  
SendThread（异步）: 将batchs(同一个broker)合成request发送到同一个broker

client-->kafka:
主线程：kafkaProducer -> intercepotrs(过滤器) ->waitOnMetadata --> key/value serializer --> partitioner -->RecordAccumulator-->(sender线程)    
sender线程：drain-->sendProduceRequest --> NetworkClient -->Kselector -->kafka  


Batch:  
batch.size:默认6K,减少request数量，提升发送效率，减轻服务器压力  
ling.ms:默认0,sender线程检查batch是否ready,满足batch.size和ling.ms其中一个，即发送消息  
buffer.memory:默认32M,producer可以用来混存数据的内存大小，如果数据产生速度大雨想borker发送的速度，producer会阻塞或者抛出一场，通过参数block.on.buffer.full控制  

Record Accumulator:
获取制定TP(Deque<RcordBatch>),在Deques的RecordBatch中添加Rcord



参数调优：buffer.memory,linger.ms,receive.buffer.bytes,send.buffer.bytes,acks(0,1,all),batch.size

建议：   
同步复制客户端还需要配合使用：ack=all;   
配置发送失败重试：retries=3;   
发送优化：linger.ms-0;   
生产端的jvm内存要足够，避免内存不足导致发送阻塞；   
callback函数不能阻塞，否则会阻塞sender线程（sender线程只有一个）。   

通过场景FIFO,消息保序：
生产消息制定partition:
producerrecord(string topic,ineger partition,k key,v value);  
配置发送失败重试为0;  
或者设置请求发送队列长度为1；  

高吞吐（允许丢消息）：  
topic配置：3分区、2副本；   
配置发送确认配置：acks=0,1   

相对可靠：  
topic配置：3分区、3副本，min.insync.replicas=2  
配置发送确认：acks=-1  


高可靠配置：  
topic:3分区、3副本，min.insync.replicas=2,flush.messages=1  
发送确认：acks=-1



---

### kafka消费机制

基本概念、消费机制、GroupCoordinator、GroupRbalancer、配置参数、代码示例、操作实战


consumer:kafka消费者负责拉取消息和确认消息，分new consumer和old consumer  
group:每个消费者都属于一个消费组内，通过消费组概念可以实现topic消息的广播（发给组内所有）和单播（组内负载均衡）  
rebalance: 组内的消费者以topic分区个数进行均衡分配，所以组内消费者最多只有分区个数的消费者   
assign模式：手工分配消费分区
subscribe模式：自动分配消费分区  

消费者机制：
每个消费组里面的消费者都需要先查找一个协调者；  
消费者加入到这个组内，主要目的是为了对分区进行分配；  
分配分区完毕后，再查找各自分区的Leader，进行消费。  



groupCoordinator:职责

处理JoinGroupRequest、SyncGroupRequest完成partition分配；  
维护_consumer_offset,管理消费进度；  
consumer调用unsubscrible  

group Rebalance:触发条件  
新consumer加入group;  
有consumer退出：主动leave、宕机、网络故障等；  
topic分区数变化;  
consumer调用unsubscrible  

