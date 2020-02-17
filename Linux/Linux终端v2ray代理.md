### Linux上网工具

```bash
v2ray服务端--<port:1234>---v2ray客户端---<1080>---polipo---<8123>--http
```
v2ray完成穿越，polipo负责将socket5转换成http。

需要安装v2ray和polipo。

注意先启动v2ray客户端，再启动polipo否则，会v2ray客户端会启动失败。

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
**Polipo**

1. 安装polipo，并修改配置
```bash
node@node:~$ sudo apt install polipo

node@node:~$ cat /etc/polipo/config
# This file only needs to list configuration variables that deviate
# from the default values.  See /usr/share/doc/polipo/examples/config.sample
# and "polipo -v" for variables you can tweak and further information.

logSyslog = true
logFile = /var/log/polipo/polipo.log

##这些配置看v2ray桌面客户度本地的监听端口和模式
socksParentProxy = "127.0.0.1:1080"   #必须
socksProxyType = socks5  #必须
proxyAddress = "0.0.0.0"  #必须
proxyPort = 8123  #必

```
2. 重启polipo
```bash
node@node:~$ sudo service polipo restart
node@node:~$ sudo service polipo status
● polipo.service - LSB: Start or stop the polipo web cache
   Loaded: loaded (/etc/init.d/polipo; generated)
   Active: active (running) since Mon 2020-02-17 02:23:55 UTC; 1s ago
     Docs: man:systemd-sysv-generator(8)
  Process: 19536 ExecStop=/etc/init.d/polipo stop (code=exited, status=0/SUCCE
  Process: 19542 ExecStart=/etc/init.d/polipo start (code=exited, status=0/SUC
    Tasks: 1 (limit: 2260)
   CGroup: /system.slice/polipo.service

```

---
**http代理**

1. 配置```.bashrc```文件
```bash
startvpn(){
  export http_proxy='http://127.0.0.1:8123'
  export https_proxy='http://127.0.0.1:8123'
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




参考：
1. [v2ray](https://www.jianshu.com/p/a5b6d9dc0441)  
2. [服务器配置-polipo](https://blog.csdn.net/scylhy/article/details/84335095)
