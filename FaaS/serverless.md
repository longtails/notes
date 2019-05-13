## serverless

what function?

![func in mq](../images/20190513.1.png)

    1. 从input topic中消费消息
    2. 将用户提供的处理逻辑应用到每条消息上，function
    3. 将结果publish到output topic 
why function?
    1. 部署简单：
       1. localrun,本地运行一个函数，适用于开发者
       2. managed-worker service来运行和管理functions
       3. k8s:每个function等价于一个k8s的statefulset,利用k8s进行弹性扩展
    2. 接口简单
    3. 运维简单

  
使用场景：
- ETL
- Data Enrichment
- Data Filtering 数据过滤
- Routing 


pulsar中所有的instance都可以抽象为一个topic 

![instance](../images/20190513.2.png)


**Runtime**:进程级别、docker容器级别，java的thread级别

**wWorker**:

Go Function

serverless的核心

整个instance有两部分，一个是instance所在workflow,一个是用户定义的process，即如何将用户的process内嵌到workflow中，当拿到用户process，接着如何进行相应处理调用。


serverless本身定位是轻量级的，所定义function不会很重的。
核心，在于怎样将用户定义的

