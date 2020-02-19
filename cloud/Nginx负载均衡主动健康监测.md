### Nginx负载均衡主动健康监测

准备好nginx源码和健康监测的源码。


```bash
root@hw2:~# wget http://nginx.org/download/nginx-1.14.2.tar.gz
--2020-02-19 22:00:31--  http://nginx.org/download/nginx-1.14.2.tar.gz
Resolving nginx.org (nginx.org)... 95.211.80.227, 62.210.92.35, 2001:1af8:4060:a004:21::e3
Connecting to nginx.org (nginx.org)|95.211.80.227|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 1015384 (992K) [application/octet-stream]
Saving to: ‘nginx-1.14.2.tar.gz.1’

nginx-1.14.2.tar.gz.1 100%[=========================>] 991.59K   422KB/s    in 2.4s

2020-02-19 22:00:34 (422 KB/s) - ‘nginx-1.14.2.tar.gz.1’ saved [1015384/1015384]

root@hw2:~# git clone https://github.com/yaoweibin/nginx_upstream_check_module.git
Cloning into 'nginx_upstream_check_module'...
remote: Enumerating objects: 3, done.
remote: Counting objects: 100% (3/3), done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 770 (delta 0), reused 2 (delta 0), pack-reused 767
Receiving objects: 100% (770/770), 413.30 KiB | 11.00 KiB/s, done.
Resolving deltas: 100% (412/412), done.
root@hw2:~#
root@hw2:~# tar -zxf nginx-1.14.2.tar.gz -C /usr/local/src/
root@hw2:~# mv nginx_upstream_check_module /usr/local/src/
root@hw2:~#
root@hw2:~# cd /usr/local/src/
root@hw2:/usr/local/src# ls
nginx-1.14.2  nginx_upstream_check_module
root@hw2:/usr/local/src#

```
添加补丁
```bash
root@hw2:/usr/local/src# ls
nginx-1.14.2  nginx_upstream_check_module
root@hw2:/usr/local/src#
```
添加补丁

```bash
patch -p1 -u < ../nginx_upstream_check_module/check_1.14.0+.patch
```
```bash
root@hw2:/usr/local/src# ls
nginx-1.14.2  nginx_upstream_check_module
root@hw2:/usr/local/src# cd nginx-1.14.2/
root@hw2:/usr/local/src/nginx-1.14.2# ls
auto  CHANGES  CHANGES.ru  conf  configure  contrib  html  LICENSE  man  README  src
root@hw2:/usr/local/src/nginx-1.14.2# patch -p1 -u < ../nginx_upstream_check_module/check_1.14.0+.patch
patching file src/http/modules/ngx_http_upstream_hash_module.c
patching file src/http/modules/ngx_http_upstream_ip_hash_module.c
patching file src/http/modules/ngx_http_upstream_least_conn_module.c
patching file src/http/ngx_http_upstream_round_robin.c
patching file src/http/ngx_http_upstream_round_robin.h
root@hw2:/usr/local/src/nginx-1.14.2#
```

配置、编译项目
```bash
./configure --prefix=/usr/local/nginx --add-module=/root/nginx_upstream_check_module/
make & make install
```

```bash

root@hw2:/usr/local/src/nginx-1.14.2# ./configure   --add-module=../nginx_upstream_check_module/
checking for OS
 + Linux 4.15.0-65-generic x86_64
checking for C compiler ... found
 + using GNU C compiler
 + gcc version: 7.4.0 (Ubuntu 7.4.0-1ubuntu1~18.04.1)
checking for gcc -pipe switch ... found
checking for -Wl,-E switch ... found
checking for gcc builtin atomic operations ... found
...
creating objs/Makefile

Configuration summary
  + using system PCRE library
  + OpenSSL library is not used
  + using system zlib library

  nginx path prefix: "/usr/local/nginx"
  nginx binary file: "/usr/local/nginx/sbin/nginx"
  nginx modules path: "/usr/local/nginx/modules"
  nginx configuration prefix: "/usr/local/nginx/conf"
  nginx configuration file: "/usr/local/nginx/conf/nginx.conf"
  nginx pid file: "/usr/local/nginx/logs/nginx.pid"
  nginx error log file: "/usr/local/nginx/logs/error.log"
  nginx http access log file: "/usr/local/nginx/logs/access.log"
  nginx http client request body temporary files: "client_body_temp"
  nginx http proxy temporary files: "proxy_temp"
  nginx http fastcgi temporary files: "fastcgi_temp"
  nginx http uwsgi temporary files: "uwsgi_temp"
  nginx http scgi temporary files: "scgi_temp"

root@hw2:/usr/local/src/nginx-1.14.2#
root@hw2:/usr/local/src/nginx-1.14.2# ls
auto     CHANGES.ru  configure  html     Makefile  objs    src
CHANGES  conf        contrib    LICENSE  man       README
root@hw2:/usr/local/src/nginx-1.14.2#
root@hw2:/usr/local/src/nginx-1.14.2# make & make install
[1] 26419
make -f objs/Makefile install
make -f objs/Makefile
make[1]: Entering directory '/usr/local/src/nginx-1.14.2'
cc -c -pipe  -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g  -I src/core -I src/event -I src/event/modules -I src/os/unix -I ../nginx_upstream_check_module/ -I objs \
	-o objs/src/core/nginx.o \
	src/core/nginx.c
make[1]: Entering directory '/usr/local/src/nginx-1.14.2'

...
	|| cp conf/nginx.conf '/usr/local/nginx/conf/nginx.conf'
cp conf/nginx.conf '/usr/local/nginx/conf/nginx.conf.default'
test -d '/usr/local/nginx/logs' \
	|| mkdir -p '/usr/local/nginx/logs'
test -d '/usr/local/nginx/logs' \
	|| mkdir -p '/usr/local/nginx/logs'
test -d '/usr/local/nginx/html' \
	|| cp -R html '/usr/local/nginx'
test -d '/usr/local/nginx/logs' \
	|| mkdir -p '/usr/local/nginx/logs'
make[1]: Leaving directory '/usr/local/src/nginx-1.14.2'
[1]+  Exit 2                  make

```
可以从编译输出看到nginx被安装到了/usr/local/nginx的位置。当然也可以通过prefix指定安装位置。
```bash
./configure --prefix=/usr/local/nginx --add-module=../nginx_upstream_check_module/
```

修改nginx.conf文件，实现主动监测后端服务。
```bash
    upstream my_server {
        server 121.36.9.214;
        server 106.15.46.11;
        keepalive 2000;
        #check interval=3000  rise=2  fall=4  timeout=4000;
        check_http_send "HEAD / HTTP/1.0\r\n\r\n";
        check_http_expect_alive http_2xx http_3xx;
    }

    server {
        listen       80;
        server_name  localhost;
        location / {
        #    root   html;
        #    index  index.html index.htm;
                proxy_pass http://my_server/;
                proxy_set_header Host $host:$server_port;
        }
    }

```


```bash
root@hw2:/usr/local/nginx# ls
client_body_temp  fastcgi_temp  logs        sbin       uwsgi_temp
conf              html          proxy_temp  scgi_temp
root@hw2:/usr/local/nginx# cp sbin/nginx /usr/local/bin/
root@hw2:/usr/local/nginx# nginx -v
nginx version: nginx/1.14.2
root@hw2:/usr/local/nginx# cd conf/
root@hw2:/usr/local/nginx/conf# ls
fastcgi.conf            koi-utf             nginx.conf           uwsgi_params
fastcgi.conf.default    koi-win             nginx.conf.default   uwsgi_params.default
fastcgi_params          mime.types          scgi_params          win-utf
fastcgi_params.default  mime.types.default  scgi_params.default
root@hw2:/usr/local/nginx/conf#


root@hw2:/usr/local/nginx/conf# cat nginx.conf |grep check -n20
19-    default_type  application/octet-stream;
20-
21-    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
22-    #                  '$status $body_bytes_sent "$http_referer" '
23-    #                  '"$http_user_agent" "$http_x_forwarded_for"';
24-
25-    #access_log  logs/access.log  main;
26-
27-    sendfile        on;
28-    #tcp_nopush     on;
29-
30-    #keepalive_timeout  0;
31-    keepalive_timeout  65;
32-
33-    #gzip  on;
34-
35-	   upstream my_server {
36-	      server 121.36.9.214;
37-	      server 106.15.46.11;
38-	      keepalive 2000;
39:	      #check interval=3000  rise=2  fall=4  timeout=4000;
40:	      check_http_send "HEAD / HTTP/1.0\r\n\r\n";
41:	      check_http_expect_alive http_2xx http_3xx;
42-	  }
43-
44-    server {
45-        listen       80;
46-        server_name  localhost;
47-
48-        #charset koi8-r;
49-
50-        #access_log  logs/host.access.log  main;
51-
52-        location / {
53-        #    root   html;
54-        #    index  index.html index.htm;
55-
56-                proxy_pass http://my_server/;
57-                proxy_set_header Host $host:$server_port;
58-
59-        }
60-
61-        #error_page  404              /404.html;
root@hw2:/usr/local/nginx/conf#

```

启动nginx测试,可以访问到后端的两个服务
```bash
root@hw2:~# curl localhost |grep nginx
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   622  100   622    0     0  77750      0 --:--:-- --:--:-- --:--:-- 77750
<title>Welcome to nginx(node2)!</title>
<h1>Welcome to nginx 02!</h1>
<p>If you see this page, the nginx web server is successfully installed and
<a href="http://nginx.org/">nginx.org</a>.<br/>
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
root@hw2:~# curl localhost |grep nginx
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   619  100   619    0     0  10316      0 --:--:-- --:--:-- --:--:-- 10316
<title>Welcome to nginx(node1)!</title>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
<a href="http://nginx.org/">nginx.org</a>.<br/>
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
root@hw2:~#

```

关闭node2上的服务，再测试nginx的主动探测是否生效
```bash
root@node2:~# service nginx stop
root@node2:~# curl localhost
curl: (7) Failed to connect to localhost port 80: Connection refused
root@node2:~#
```
这时访问到的都是后端node1的服务。
```bash
root@hw2:/usr/local/nginx# sbin/nginx
root@hw2:~# curl localhost |grep nginx
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   619  100   619    0     0   9983      0 --:--:-- --:--:-- --:--:--  9983
<title>Welcome to nginx(node1)!</title>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
<a href="http://nginx.org/">nginx.org</a>.<br/>
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
root@hw2:~# curl localhost |grep nginx
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   619  100   619    0     0  10316      0 --:--:-- --:--:-- --:--:-- 10316
<title>Welcome to nginx(node1)!</title>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
<a href="http://nginx.org/">nginx.org</a>.<br/>
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
root@hw2:~# curl localhost |grep nginx
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   619  100   619    0     0  10147      0 --:--:-- --:--:-- --:--:-- 10147
<title>Welcome to nginx(node1)!</title>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
<a href="http://nginx.org/">nginx.org</a>.<br/>
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
root@hw2:~#
```



参考

[Nginx主动健康监测模块](https://github.com/yaoweibin/nginx_upstream_check_module)  

[nginx_upstream_check_module监控后端服务器http](https://www.cnblogs.com/paul8339/p/8124739.html)