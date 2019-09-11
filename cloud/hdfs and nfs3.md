### HDFS NFS Gateway

label: 分布式存储、hdfs、nfs

最近我们在做一些区块链可靠性的东西，在存储方面我们知道区块链的数据是只增不减的，所以就会造成磁盘占用空间持续上涨，迟早有一天会塞满真个磁盘，而我们要思考的就是如何解决这个问题。在存储这块，我们读的轮文大多是从区块、账本的数据结构优化出发的，目的就是减少磁盘占用，我一直觉得占用是少了点，但终究会沾满空间，也只是比为优化的账本晚点占满空间，这不是最终的解决办法。  

在几个月里思考如何提升区块链的可靠性，我们也大多是对区块链的各个分层、各个组件划分调研、思考如何提高可靠性，花费了那么久的时间，也没发现有什么好的办法。     

我记得有一种思想是组件不可靠，但是我们通过整体管理控制的来提高整体的可靠性，这是不是工程控制论的方法？我想在实际生产中，应该也是这样的吧。比如，k8s下一个简单的业务可靠性，设计、开发者无需在可靠性上花费过多，而是将这个业务的健康管理交给k8s，最简单的情况，当部署这个业务的pod挂了，k8s根据配置的重启策略，重启、扩容pod,可以简单的有效解决一些系统的异常情况，更复杂的业务场景要和k8s环境有效结合来提升业务可靠性。当然，这仅仅是举个单方面的例子，并不适合所有的场景。     

鉴于上述思考，我想能否从另一个角度来提高区块链系统的可靠性，甚至我们不必要为了区块链单个组件的可靠性而浪费昂贵的资源，而通过和外部环境的协调来提升业务系统的可靠性。  

这里仅仅涉及存储方面，在云环境下，业务的开发难度其实降低了很多，比如区块链的账本存储，最开始担心的账本无限增长，就可以使用分布式存储来解决。比如，我们使用分布式存储管理文件空间容量，将分布式文件系统挂载到本地主机目录，区块链的账本存储在这个挂载的目录上。这样从整本的角度看，就可以拥有无限的空间，我们就无需再懂区块链账本部分的代码，支持原生系统；从外围部署环境的角度看，我们只要监控分布式文件系统，保证可用空间容量以及系统的正常工作即可。 

这个想法最初是和做私有云的面试官交流的时候想到的，面试官介绍他们公司的前景优势是他们在分布式存储方面拥有比较强的技术积累，云主机只需挂载相应的虚拟文件目录就可以，可以降低云上磁盘管理的复杂度，所以说他们在私有云这块是有优势的。他们也做k8s这块的内容，只不过是做整体方案以私有云的方式提供的。   

在后来jd的面试上，和他们的面试官也交流了分布式存储这块。

接下来，我就以去年刚学过的hdfs来简单测试一下，hdfs是支持nfs3的，也就是我们搭建好hdfs后，可以通过挂载nfs磁盘的方式，将hdfs挂载到本地目录，而主机上的业务就可以像在普通目录下操作的方式操作挂载的hdfs目录。  


hdfs伪分布式环境+nfs3挂载到本地

**第一步 安装java、下载hadoop**:

安装java:
```bash
apt install openjdk-11-jdk
```
hadoop需要JAVA_HOME,ubuntu上java的安装位置:
```bash
root@node1:~# ls /usr/lib/jvm/
java-1.11.0-openjdk-amd64  java-11-openjdk-amd64  java-1.8.0-openjdk-amd64  java-8-openjdk-amd64
root@node1:~# ls /usr/lib/jvm/java-11-openjdk-amd64/bin/
java         jjs          keytool      pack200      rmid         rmiregistry  unpack200    
```

下载haddop:

```
wget http://mirror.bit.edu.cn/apache/hadoop/common/hadoop-3.1.2/hadoop-3.1.2.tar.gz
```

接下来，安装官方demo，配置伪分布式hadoop并测试：   

[hadoop3.12官方教程 singlecluster](https://hadoop.apache.org/docs/r3.1.2/hadoop-project-dist/hadoop-common/SingleCluster.html)   
[其他，伪分布式搭建](https://www.jianshu.com/p/1352ce8c8d73)


由于我是直接用root操作的，3.12会存在问题，需要在hdfs-site.yaml,yarn-site.yaml中制定用户:  
在sbin/start-dfs.sh和sbin/stop-dfs.sh的开头加入如下内容：
```bash
HDFS_DATANODE_USER=root
HADOOP_SECURE_DN_USER=hdfs
HDFS_NAMENODE_USER=root
HDFS_SECONDARYNAMENODE_USER=root
```
在sbin/start-yarn.sh和sbin/stop-yarn.sh的开头加入如下内容：
```bash
YARN_RESOURCEMANAGER_USER=root
HADOOP_SECURE_DN_USER=yarn
YARN_NODEMANAGER_USER=root
```

接下来可以启动hadoop,可以测试wordcount demo，
```bash
root@node1:~/hdp/hadoop-3.1.2# sbin/start-all.sh 
WARNING: HADOOP_SECURE_DN_USER has been replaced by HDFS_DATANODE_SECURE_USER. Using value of HADOOP_SECURE_DN_USER.
Starting namenodes on [localhost]
Starting datanodes
Starting secondary namenodes [node1]
Starting resourcemanager
Starting nodemanagers

root@node1:~/hdp/hadoop-3.1.2# jps
23177 NameNode
23322 DataNode
23563 SecondaryNameNode
24204 Portmap
24271 Jps
```
测试wordcount,将本地README.txt put到hdfs上，然后运行wordcount:
```bash
root@node1:~/hdp/hadoop-3.1.2# ls
bin  etc  include  input  lib  libexec  LICENSE.txt  logs  NOTICE.txt  output  README.txt  sbin  share
root@node1:~/hdp/hadoop-3.1.2# bin/hadoop  fs -put ./README.txt /
root@node1:~/hdp/hadoop-3.1.2# bin/hadoop  fs -ls /
Found 3 items
-rw-r--r--   1 root supergroup       1366 2019-09-11 15:02 /README.txt
-rw-r--r--   1 root root               38 2019-09-11 13:10 /readme.md
-rw-r--r--   1 root root                3 2019-09-11 13:13 /readme2.md

root@node1:~/hdp/hadoop-3.1.2# bin/hadoop jar share/hadoop/mapreduce/sources/hadoop-mapreduce-examples-3.1.2-sources.jar org.apache.hadoop.examples.WordCount / /usr/test/hadoop/output
...
2019-09-11 15:03:11,997 INFO mapred.LocalJobRunner: reduce task executor complete.
2019-09-11 15:03:12,353 INFO mapreduce.Job:  map 100% reduce 100%
2019-09-11 15:03:12,354 INFO mapreduce.Job: Job job_local1378003446_0001 completed successfully
2019-09-11 15:03:12,378 INFO mapreduce.Job: Counters: 35
	File System Counters
		FILE: Number of bytes read=1272707
		FILE: Number of bytes written=3288709
		FILE: Number of read operations=0
		FILE: Number of large read operations=0
		FILE: Number of write operations=0
		HDFS: Number of bytes read=5584
		HDFS: Number of bytes written=1343
		HDFS: Number of read operations=35
		HDFS: Number of large read operations=0
		HDFS: Number of write operations=6
	Map-Reduce Framework
		Map input records=33
		Map output records=189
		Map output bytes=2136
		Map output materialized bytes=1949
		Input split bytes=290
		Combine input records=189
		Combine output records=141
		Reduce input groups=137
		Reduce shuffle bytes=1949
		Reduce input records=141
		Reduce output records=137
		Spilled Records=282
		Shuffled Maps =3
		Failed Shuffles=0
		Merged Map outputs=3
		GC time elapsed (ms)=109
		Total committed heap usage (bytes)=700080128
	Shuffle Errors
		BAD_ID=0
		CONNECTION=0
		IO_ERROR=0
		WRONG_LENGTH=0
		WRONG_MAP=0
		WRONG_REDUCE=0
	File Input Format Counters 
		Bytes Read=1407
	File Output Format Counters 
		Bytes Written=1343
```

**第二步 HDFS NFS Gateway**  

先关闭hadoop: 
```bash
root@node1:~/hdp/hadoop-3.1.2# sbin/stop-all.sh 
``` 

配置nfs,修改配置文件core-site.xml、hdfs-site.xml，详细配置参考官方教程：   
[hadoop官方HDFS NFS Gateway配置教程](http://hadoop.apache.org/docs/r3.1.2/hadoop-project-dist/hadoop-hdfs/HdfsNfsGateway.html)  

但是core-site.xml要略微修改两个属性，否则后续的挂载会失败[(mount.nfs: mount system call failed)](https://serverfault.com/questions/858286/mount-nfs-mount-system-call-failed)：  
```xml
	<property>
		<!--<name>hadoop.proxyuser.nfsserver.groups</name>-->
		<name>hadoop.proxyuser.root.groups</name>
		<value>*</value>
		<description>
			The 'nfsserver' user is allowed to proxy all members of the 'nfs-users1' and
			'nfs-users2' groups. Set this to '*' to allow nfsserver user to proxy any group.
		</description>
	</property>
	<property>
		<!---<name>hadoop.proxyuser.nfsserver.hosts</name>-->
		<name>hadoop.proxyuser.root.hosts</name>
		<value>*</value>
		<description>
			This is the host where the nfs gateway is running. Set this to '*' to allow
			requests from any hosts to be proxied.
		</description>
	</property>
```

重启hadoop:
```bash
root@node1:~/hdp/hadoop-3.1.2# sbin/start-all.sh 
WARNING: HADOOP_SECURE_DN_USER has been replaced by HDFS_DATANODE_SECURE_USER. Using value of HADOOP_SECURE_DN_USER.
Starting namenodes on [localhost]
Starting datanodes
Starting secondary namenodes [node1]
Starting resourcemanager
Starting nodemanagers
```
启动portmap和nfs3,需要确保nfs（ubuntu是nfs-kernel-server）、rpcbind服务关闭，有否则后续portmap和nfs3会因为端口占用无法启动：
```
root@node1:~/hdp/hadoop-3.1.2# service nfs-kernel-server stop
root@node1:~/hdp/hadoop-3.1.2# service rpcbind stop
root@node1:~/hdp/hadoop-3.1.2# bin/hdfs --daemon start portmap
root@node1:~/hdp/hadoop-3.1.2# bin/hdfs --daemon start nfs3
root@node1:~/hdp/hadoop-3.1.2# jps
24325 Nfs3
23177 NameNode
23322 DataNode
24347 Jps
23563 SecondaryNameNode
24204 Portmap
```
测试各组件是否正常工作：
```bash
root@node1:~/hdp/hadoop-3.1.2# rpcinfo -p localhost
program vers proto   port
100005    1   tcp   4242  mountd
100005    2   udp   4242  mountd
100005    2   tcp   4242  mountd
100000    2   tcp    111  portmapper
100000    2   udp    111  portmapper
100005    3   udp   4242  mountd
100005    1   udp   4242  mountd
100003    3   tcp   2049  nfs
100005    3   tcp   4242  mountd

root@node1:~/hdp/hadoop-3.1.2# showmount -e localhost
Exports list on localhost :
/ (everyone)
```

**第三步 以nfs的方式挂载hdfs到本地**:

这里挂载hdfs到本地hdfsnew中,在hdfsnew中创建一个readme.md文件,并可以在hdfs中查看到对应文件：
```bash
root@node1:~/hdp/hadoop-3.1.2# mount -t nfs -o vers=3,proto=tcp,nolock,noacl,sync node1:/ /mnt/hdfsnew
root@node1:~/hdp/hadoop-3.1.2# touch /mnt/hdfsnew/readme.md
root@node1:~/hdp/hadoop-3.1.2# ls /mnt/hdfsnew/
readme.md
root@node1:~/hdp/hadoop-3.1.2# bin/hadoop fs -ls /
Found 1 items
-rw-r--r--   1 root root         38 2019-09-11 13:00 /readme.md
```

查看hdfs的容量：
```bash
root@node1:~/hdp/hadoop-3.1.2# bin/hdfs dfsadmin -report
Configured Capacity: 42140479488 (39.25 GB)
Present Capacity: 23885504553 (22.25 GB)
DFS Remaining: 23885455401 (22.25 GB)
DFS Used: 49152 (48 KB)
DFS Used%: 0.00%
Replicated Blocks:
	Under replicated blocks: 0
	Blocks with corrupt replicas: 0
	Missing blocks: 0
	Missing blocks (with replication factor 1): 0
	Low redundancy blocks with highest priority to recover: 0
	Pending deletion blocks: 0
Erasure Coded Block Groups: 
	Low redundancy block groups: 0
	Block groups with corrupt internal blocks: 0
	Missing block groups: 0
	Low redundancy blocks with highest priority to recover: 0
	Pending deletion blocks: 0

-------------------------------------------------
Live datanodes (1):

Name: 127.0.0.1:9866 (localhost)
Hostname: iZuf68s1uoyxjhtgk7l3mhZ
Decommission Status : Normal
Configured Capacity: 42140479488 (39.25 GB)
DFS Used: 49152 (48 KB)
Non DFS Used: 15768768512 (14.69 GB)
DFS Remaining: 23885455401 (22.25 GB)
DFS Used%: 0.00%
DFS Remaining%: 56.68%
Configured Cache Capacity: 0 (0 B)
Cache Used: 0 (0 B)
Cache Remaining: 0 (0 B)
Cache Used%: 100.00%
Cache Remaining%: 0.00%
Xceivers: 9
Last contact: Wed Sep 11 13:10:15 CST 2019
Last Block Report: Wed Sep 11 12:53:34 CST 2019
Num of Blocks: 0

```



注意：ubuntu上安装的nfs名字是nfs-kernel-server，并且查看端口看不到进程信息：


```
root@node1:~/hdp/hadoop-3.1.2# netstat -ntulp |grep 2049
tcp        0      0 0.0.0.0:2049            0.0.0.0:*               LISTEN      -                   
tcp6       0      0 :::2049                 :::*                    LISTEN      -                   
udp        0      0 0.0.0.0:2049            0.0.0.0:*                           -                   
udp6       0      0 :::2049                 :::*                                -                   
root@node1:~/hdp/hadoop-3.1.2# 
root@node1:~/hdp/hadoop-3.1.2# service nfs-kernel-server stop
root@node1:~/hdp/hadoop-3.1.2# service nfs-kernel-server status
● nfs-server.service - NFS server and services
   Loaded: loaded (/lib/systemd/system/nfs-server.service; enabled; vendor preset: enabled)
   Active: inactive (dead) since Wed 2019-09-11 13:15:16 CST; 3s ago
  Process: 31484 ExecStopPost=/usr/sbin/exportfs -f (code=exited, status=0/SUCCESS)
  Process: 31483 ExecStopPost=/usr/sbin/exportfs -au (code=exited, status=0/SUCCESS)
  Process: 31474 ExecStop=/usr/sbin/rpc.nfsd 0 (code=exited, status=0/SUCCESS)
  Process: 31398 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 31397 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 31398 (code=exited, status=0/SUCCESS)

Sep 11 13:14:08 node1 systemd[1]: Starting NFS server and services...
Sep 11 13:14:08 node1 systemd[1]: Started NFS server and services.
Sep 11 13:15:16 node1 systemd[1]: Stopping NFS server and services...
Sep 11 13:15:16 node1 systemd[1]: Stopped NFS server and services.

root@node1:~/hdp/hadoop-3.1.2# netstat -ntulp |grep 2049
root@node1:~/hdp/hadoop-3.1.2# 

```

现在，完成了分布式文件系统hdfs挂载到本地，并可以以普通目录文件的方式使用分布式系统。  