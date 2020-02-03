### 智能DNS

作用：  
减少动态服务（一般集中部署的）响应延时   
CDN加速  
负载均衡   
防止DDos攻击  


缺陷：  
成本增加（硬件、维护成本）  
不配套支持应用检测机制  
准确性欠缺，不一定能正确得到用户的地域信息等

----

IP库  

能提供有完整且准确的IP地址和地址位置等信息  

获取途径：  
1. 商业第三方机构、ISP提供   
2. 自己修正或弥补  
3. 通过APNIC生成IP库   


通过APNIC(亚太网络中心)生成IP库     

数据格式 

```
apnic|CN|asn|3460|1|20020801|allocated
```


Bind中的ACL(媒体访问控制列表)    

```
acl ACL_NAME{
    <需要定义的网段>;
};
//需要定义的网段：每个网络范围一行，可以包含多行，如172。16.10.0。24
```


如何通过主机数量求得掩码地址   

公式：hosts=2^(32-mask)   


主机数反求子网掩码的话，应该是log以2为底取主机树的对数.然后32减去该对数得到的子网掩码   

```bash
mask=$(cat <<EOF |bc | tail -1 
    pow=32;
    define log2(x){
        if (x<=1)return (pow);
        pow--;
        return (log2(x/2));
    }
    log2($cnt)
    EOF )
```

```bash
FILE=$PWD/apnic
wget http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest -O $FILE  

grep 'apnic|CN|ipv4|' $FILE |cut -f4,5 -d '|' |sed -e 's/|/ /g' | while read ip cnt  
do 
echo $ip:$cnt  
mask=$(cat <<EOF |bc | tail -1 
    pow=32;
    define log2(x){
        if (x<=1)return (pow);
        pow--;
        return (log2(x/2));
    }
    log2($cnt)
    EOF )
echo $ip/$mask >> cn.net  
if whois $ip@whois.apnic.net |grep -i ".*chinanet.*\|.*telecom.*" > /dev/null;then
    echo $ip/$mask >>chinanet
elif whois $ip@whois.apnic.net | grep -i ".*unicom.*" > /dev/null;then
    echo $ip/$mask >>unicom
else 
    echo $ip/$mask >> others
fi
```

---
智能dns配置 

创建acl文件，放到指定位置  

bind view配置  

```
include "/var/named/CHINANET.acl";
include "/var/named/UNICOM.acl";
include "/var/named/OTHERS.acl";
view "imooc.com.chinanet.zon" {
    recursion no;
    match-clients {CHINANET;};
    zone "." IN{
        type hint;
        file "name.ca";
    };
    zone "imooc.com"{ #权威解析域
        type master;
        notify yes;
      //also-notify {30.96.8.233;};
      //allow-transfer {30.96.8.233;};
        file "imooc.com.chinanet.zone";
    };
    ...

}
view "imooc.com.unicom.zone"{
    ...
}
...
```

---

**DNS安全**  

DNS信息污染  

用户发送查询请求，攻击者返回假的结果，原因是dns使用的是无连接的udp,或者更上一级的攻击  
用TCP参数查询dns，会好很多

```
nslookup -vc www.google.com
```


DNS拒绝服务攻击  
利用DNS软件版本漏洞攻击  
DDOS攻击

DNS放大攻击  


