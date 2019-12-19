### Fabric make error on mac


make peer-docker-clean时发生bzip2 data invalid:bad magic value错误。


```bash
liu@liudeMacBook-Pro fabric % make peer-docker-clean
docker images --quiet --filter=reference='hyperledger/fabric-peer:amd64-1.4.4-snapshot-*' | xargs docker rmi -f
liu@liudeMacBook-Pro fabric % make peer-docker      
mkdir -p .build/image/peer/payload
cp .build/docker/bin/peer .build/sampleconfig.tar.bz2 .build/image/peer/payload
mkdir -p .build/image/peer
Building docker peer-image
docker build  -t hyperledger/fabric-peer .build/image/peer
Sending build context to Docker daemon  38.85MB
Step 1/7 : FROM hyperledger/fabric-baseos:amd64-0.4.16
 ---> f711d456dcc4
Step 2/7 : ENV FABRIC_CFG_PATH /etc/hyperledger/fabric
 ---> Using cache
 ---> 37208aa44860
Step 3/7 : RUN mkdir -p /var/hyperledger/production $FABRIC_CFG_PATH
 ---> Using cache
 ---> a9aa22315715
Step 4/7 : COPY payload/peer /usr/local/bin
 ---> Using cache
 ---> 119a1e66635d
Step 5/7 : ADD  payload/sampleconfig.tar.bz2 $FABRIC_CFG_PATH
failed to copy files: Error processing tar file(bzip2 data invalid: bad magic value in continuation file): 
make: *** [.build/image/peer/.dummy-amd64-1.4.4-snapshot-d0eecbac7] Error 1

```
这确实根mac环境有关，mac上默认的工具是bsd的，而我们开发经常用的是gnu，也就是我们常在linux上用户的工具。  
有一点很明显，就是mac上rm abc -r 是有问题的，必须改成rm -r abc，而在linux上，我们就可以使用rm abc -r来删除abc文件夹，这也是bsd和gnu工具的差别造成的。  

看下mac上工具的信息
```bash
➜  ~ /usr/bin/tar --version
bsdtar 3.3.2 - libarchive 3.3.2 zlib/1.2.11 liblzma/5.0.5 bz2lib/1.0.6
```

解决上述问题，只需要安装gnu工具，并使其优先于bsd
```bash
brew install gnu-tar --default-names
```
安装完成后，设置PATH
```bash
GNUBIN=/usr/local/opt/gnu-tar/libexec/gnubin
export PATH=$GNUBIN:$PATH   #GNUBIN要在PATH前，否则就会优先搜索到系统的bsdtar
```
测试tar版本
```bash
➜  ~ tar --version
tar (GNU tar) 1.32
Copyright (C) 2019 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by John Gilmore and Jay Fenlason.
```

之后，就可以重新编译了。

参考  
1. [Mac OS 安装GNU命令行工具](https://www.phodal.com/blog/mac-os-install-gnu-command-toolsg/)
2. [Issue with "--with-default-names" #61](https://github.com/HyperledgerHandsOn/trade-finance-logistics/issues/61)