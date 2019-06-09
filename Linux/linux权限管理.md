### linux权限管理

以往，需要改权限都是需要时，直接“百度”，但用了将近5年的linux，还不能熟练操作权限，理解权限，有点丢人哈。


#### 文件基本权限

```-rw-r--r--```   
第一位：文件类型(**-:文件 d:目录 l:软链接**,还有块设备文件、字符设备文件、套接字文件、管道符文件）

剩下九位：每三位一组， 分别代表u所有者、g所属数组、o其他人  
r:读，w:写，x:执行

一般所有者权限>所属组>其他人

```bash
liudeMacBook-Pro:~ liu$ ls -l
-rwxr-xr-x   1 liu  staff  27464  6  5 21:21 a.out
drwxr-xr-x   5 liu  staff    160  5 17 21:43 k8s.kfk
drwxr-xr-x   2 liu  staff     64  5 24 10:42 tmp
drwxr-xr-x  32 liu  staff   1024  6  6 10:50 work
```

chmod修改文件权限

+-模式：
```bash
chmod u+x test.av        #给所有者赋予执行权限  
chmod g+w,o+w test.av    #给多个组同时赋予权限
chmod u-x test.av        #收回u的x权限
```
=模式：
```bash
chmod u=rwx test.av      #给所有者赋予读写执行去权限
chmod u=rwx,g=rw test.av #给多个组赋予权限
chmod a=rw test.av       #给所有人赋予相同的权限
```
数字表示(建议使用)：```r--4,w--2,x--1 ```   

用二进制来看每个权限位只有0和1两个状态，高低位表示就是r,w,x,转化成十进制就是4,2,1,在比较权限时直接比较各位就行。

**常用权限**： 
777 -->所有权限   
644 -->普通文件权限，所有者读写，其他只有读权限  
755 -->执行权限，指向权限前提可读   

实际工作中，ugo权限值是非递增，所以常用就是上边几个。

```bash
chmod 755 test.av #赋予rwxr-xr-x权限
```

**权限对文件的作用**：
r: 读取文件内容（cat、more、head、tail)   
w: 编辑、新增、修改文件内容（vi echo），**但不包含删除文件**  
(文件的权限是指对文件下级的内容的权限，这里就是文件内容,所以要删除文件应该看上一层目录的权限)
x: 执行

所以，本级设置的权限，是对其子级的操作控制。  

**权限对目录的作用**:  
r: 可以查看目录下文件名(ls)  
w: 具有修改目录结构的权限。如新建文件和目录，删除此目录下文件和目录，重命名此目录下文件和目录，剪切(touch rm mv cp)  
x: 可以进入目录(cd)

对文件来讲：最高权限是 x  
对目录来讲：最高权限是 w （可以赋予的权限0，5：读和进入，7。但4没有意义，1没有意义，6没有意义） 

所以对文件要少赋x，对目录少赋w，其他人不要赋予7权限。  



其他权限命令：   
chown 用户名 文件名，改变文件的所有者   
chown 所有者：所在组 文件
```bash
liudeMacBook-Pro:~ liu$ ll
drwxr-xr-x   2 root  staff     64  5 24 10:42 tmp
liudeMacBook-Pro:~ liu$ sudo chown liu tmp
liudeMacBook-Pro:~ liu$ ll
drwxr-xr-x   2 liu  staff     64  5 24 10:42 tmp
```

chgrp 组名 文件名
```bash
chgrp usergrp  tmp
```

让用户对文件及目录有一定的权限   
要求：  
1. 拥有一个av目录  
2. 让A老师拥有所有的权限：7
3. 让同学有查看的权限: 5
4. 其他人不能查: 0

```bash
root@hw1:~# ll -d av
drwxr-xr-x 2 root root 4096 Jun  9 10:36 av/
root@hw1:/home/test# useradd user1  #创建用户user1,所数组user1
root@hw1:~# chgrp user1 av
root@hw1:~# ll -d av
drwxr-xr-x 2 root user1 4096 Jun  9 10:36 av/
root@hw1:~# chmod 750 av
root@hw1:~# ll -d av
drwxr-x--- 2 root user1 4096 Jun  9 10:36 av/
root@hw1:~# mkdir /home/test
root@hw1:~# mv av /home/test/
root@hw1:~# cd /home/test/
root@hw1:/home/test# su - user1
$ ls -l
total 4
drwxr-x--- 2 root user1 4096 Jun  9 10:36 av
$ cd av
$ ls
root@hw1:/home/test# useradd user2  #创建用户user2,所数组user2
root@hw1:/home/test# su - user2
$ cd /home/test/
$ ls -l
total 4
drwxr-x--- 2 root user1 4096 Jun  9 10:36 av
$ cd av
-su: cd: av: Permission denied

```

分配文件基本权限时，核心原则：在最小权限情况下能够实现要求即可。

#### 文件默认权限  


查看默认权限：umask
```bash
root@hw1:/home/test# umask
0022
```
第一位：文件特殊权限  
后三位：文件默认权限

默认权限：
1. 文件默认不能建立为执行文件，必须手工赋予执行权限  
2. 所以文件默认权限最大为666
3. 默认权限需要换算称字母再相减
4. 建立文件之后的默认权限，为666减去umask值 

666换成字母-rw-rw-rw-  
022换成字母-----w--w-  
666-022= -rw-r--r--

033换成字母-----wx-wx  
666-033= -rw-r--r--  

其实就是换成二进制，先对umask取反，再进行逻辑与运算:umask&~原权限  

目录的默认权限：
1. 目录默认的最大权限为777
2. 默认权限需要换算称字母再相减
3. 建立文件之后的默认权限，为777减去umask值

777=-rwxrwxrwx umask=022=-----w--w-  
777-022=-rwxr-xr-x   
就是各位进行7 7 7& ~0 ~2 ~2=7 5 5; 7&~2=5  


临时修改: umask 022  
永久修改: /etc/profile



---
接下来，还有ACL权限、文件特殊权限、不可改变位权限、sudo权限  
