### Linux上网工具

```bash
v2ray服务端--<port:1234>---v2ray客户端---<1087 http>-----http
                                     |
                                     +----<1080 socket5>-----socket5
```

v2ray服务本身就支持多种本地接口，只需配置inbounds入站协议即可。同时可以作为中转服务。

---
**v2ray**

1. 本地客安装v2ray客户端：
```bash
bash <(curl -L -s https://install.direct/go.sh)
```
go.sh脚本会先下载v2ray-linux-64.zip文件，比较慢   
也可以先下载v2ray-linux-64.zip,再通过go.sh安装
```bash
sudo ./go.sh --local v2ray-linux-64.zip
```
2. 配置客户端，```/etc/v2ray/config.json```,直接把桌面客户端的vmss配置文件复制过来就可以
```bash
{
  ...
  "inbounds": [
    {
      "listen": "127.0.0.1", //可以通过socks访问中转流量，127这个地址表示只为本地流量代理
      "protocol": "socks",
      "settings": {
        "ip": "",
        "userLevel": 0,
        "timeout": 360,
        "udp": false,
        "auth": "noauth"
      },
      "port": "1080"
    },
    {
      "listen": "127.0.0.1", //可以通过http直接访问，中转流量,只为本地流量代理
      "protocol": "http",
      "settings": {
        "timeout": 360
      },
      "port": "1087"
    }
  ],
  "outbounds": [
    {
      "mux": {
        "enabled": false,
        "concurrency": 8
      },
      "protocol": "vmess",
      "streamSettings": {
       ...
        },
       ...
        "network": "tcp"
      },
      "tag": "agentout",
      "settings": {
        "vnext": [
          {
            "address": "xxx.xxx.xxx.xxx",
            "users": [
              {
                "id": "xxxxx",
                "alterId": 64,
                "level": 0,
                "security": "auto"
              }
            ],
            "port": xxxxx
          }
        ]
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs",
        "redirect": "",
        "userLevel": 0
      }
    },
    {
      "tag": "blockout",
      "protocol": "blackhole",
      "settings": {
        "response": {
          "type": "none"
        }
      }
    }
  ],
  "dns": {...
  },
  "routing": {
      ...
    }
  },
  "transport": {}
}
```
3. 重启v2ray服务
```bash
node@node:~$ sudo service v2ray restart
node@node:~$ sudo service v2ray status
● v2ray.service - V2Ray Service
   Loaded: loaded (/etc/systemd/system/v2ray.service; enabled; vendor preset:
   Active: active (running) since Mon 2020-02-17 02:21:36 UTC; 2s ago
 Main PID: 18917 (v2ray)
    Tasks: 7 (limit: 2260)
   CGroup: /system.slice/v2ray.service
           └─18917 /usr/bin/v2ray/v2ray -config /etc/v2ray/config.json
```
---
**http代理**

注意我们在Linux安装了v2ray，并配置了http和socket5本地代理入口。   
在Linux终端上我们选择http进行代理

1. 配置```.bashrc```文件
```bash
startvpn(){
  export http_proxy='http://127.0.0.1:1087'
  export https_proxy='http://127.0.0.1:1087'
  echo "设置代理"
}
stopvpn(){
 unset http_proxy
 unset https_proxy
 echo "取消代理"
}
```
2. 生效配置
```bash
node@node:~$ source .bashrc
```
3. 测试,开启后可以看到出口ip已经变成了代理服务器的ip
```bash
node@node:~$ startvpn
设置代理
node@node:~$ curl ip.sb
52.xx.237.xx  #代理服务器的公网ip
node@node:~$ stopvpn
取消代理
node@node:~$ curl ip.sb
36.xx.130.xx  #宽带服务商的ip
```


---
**国内流量中转**

之所以搞这个是因为家里的宽带影响了穿透，但是用手机热点访问没有任何问题，速度还杠杠的。所以就有了用中转服务的想法。

```bash
[v2ray client]--宽带服务商-----------no---------->gfw----->[v2ray server on aws]--->
[v2ray client]--宽带服务商--ok-->[国内服务器]--ok-->gfw----->[v2ray server on aws]--->
````


一开始想用Nginx转发，直接修改v2ray客户单的目标地址，但实际上不行，失败了。原因不清楚，可能是协议的事。

继续查阅资料发现v2ray本身就支持中转，且不影响中转服务器的代理，只需要添加一个入口即可。


首先生成客户端的UID,客户端无需直接使用aws服务器上的uid。

```bash
root@node1:~# cat /proc/sys/kernel/random/uuid
69440bb2-518e-4c9a-87d3-ee16adaee7cf
root@node1:~# cat /proc/sys/kernel/random/uuid
afa8c367-e6af-45b5-b398-74da2445336e
root@node1:~# cat /proc/sys/kernel/random/uuid
1639abee-d2a3-481e-bfd3-fafc2ca79e3e
root@node1:~#
```


```bash
{
  ...
  "inbounds": [
    {
      "listen": "127.0.0.1", //用于服务器本地代理,127表示只能本地代理
      "protocol": "socks",
      "settings": {
        "ip": "",
        "userLevel": 0,
        "timeout": 360,
        "udp": false,
        "auth": "noauth"
      },
      "port": "1080"
    },
    {
      "listen": "127.0.0.1",//本地http代理
      "protocol": "http",
      "settings": {
        "timeout": 360
      },
      "port": "1087"
    },
    {
      "listen": "0.0.0.0", //0.0.0.0表示任意来源流量，就可以作为中转服务,如果是局域网，可以设置更详细的地址
      "protocol": "vmess",
      "settings": {
        "clients": [ //可以添加多个客户端，给多个人使用
            {
                "id": "69440bb2-518e-4c9a-87d3-ee16adaee7cf",//uid要
                "alterId": 12
            },
            {
                "id": "afa8c367-e6af-45b5-b398-74da2445336e",//uid要
                "alterId": 34
            }
            ]
      },
      "port": "12345"//注意配置国内服务器的安全组，打开端口
    }
  ],
  "outbounds": [
    ...//这里可客户端配置没啥区别
  }
```

而国内的客户单就可以使用中转服务器的配置了

```bash
{
  ...
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "ip": "",
        "userLevel": 0,
        "timeout": 360,
        "udp": false,
        "auth": "noauth"
      },
      "port": "1080"
    },
    {
      "listen": "127.0.0.1",
      "protocol": "http",
      "settings": {
        "timeout": 360
      },
      "port": "1087"
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "streamSettings": {
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        },
        "tlsSettings": {
          "allowInsecure": true
        },
        "security": "none",
        "network": "tcp"
      },
      "tag": "agentout",
      "settings": {
        "vnext": [
          {
            "address": "中转服务器地址",
            "users": [
              {
                "id": "69440bb2-518e-4c9a-87d3-ee16adaee7cf",
                "alterId": 12,
                "level": 0,
                "security": "auto"
              }
            ],
            "port": 12345
          }
        ]
      }
    },
    ...
  ],
  "routing": {
    ...
  }
```

这时就可以穿透了。



参考：
1. [v2ray](https://www.jianshu.com/p/a5b6d9dc0441)  
2. [服务器端升级后无法启动(code=exited, status=255) #815](https://github.com/v2ray/v2ray-core/issues/815)
3. [配置中转服务器](https://github.com/v2ray/v2ray-core/issues/1220)
4. [高级配置，伪装、安全配置等](https://toutyrater.github.io/advanced/vps_relay.html)