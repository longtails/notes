### Linux上网工具

```bash
v2ray服务端--<port:1234>---v2ray客户端---<1080>---polipo---<8123>--http
```
v2ray完成穿越，polipo负责将socket5转换成http。

需要安装v2ray和polipo。

注意先启动v2ray客户单，再启动polipo否则，会v2ray客户端会启动失败。

参考：
1. [v2ray](https://www.jianshu.com/p/a5b6d9dc0441)  
2. [服务器配置-polipo](https://blog.csdn.net/scylhy/article/details/84335095)
