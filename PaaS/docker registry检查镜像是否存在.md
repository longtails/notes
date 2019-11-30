### docker registry检查镜像是否存在

[docker registry v2 API](https://docs.docker.com/registry/spec/api/)没有提供直接判断一个镜像是否已经存在的api，但是可以通过一些接口组合判断，这里用manifest接口判断该镜像是否已经存在


测试manifests API，存在结果
```bash
➜  ~ curl -X GET "http://registry:5000/v2/nginx/manifests/1.12"
{
   "schemaVersion": 1,
   "name": "nginx",
   "tag": "1.12",
   "architecture": "amd64",
   "fsLayers": [
      {
         "blobSum": "sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4"
      },
      {
         "blobSum": "sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4"
      },
      {
         "blobSum": "sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4"
      },
      {
         "blobSum": "sha256:38cb13c1e4c90656d66a957d513bed8091953d5bfdb3c76664f71df7fc1b058d"
      },
      {
         "blobSum": "sha256:e3eaf3d87fe01fe9d7dc0a1e80afaf96e853cce39342325cd1236c58e02515db"
      },
      {
         "blobSum": "sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4"
      },
      {
         "blobSum": "sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4"
      },
      {
         "blobSum": "sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4"
      },
      {
         "blobSum": "sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4"
      },
      {
         "blobSum": "sha256:f2aa67a397c49232112953088506d02074a1fe577f65dc2052f158a3e5da52e8"
      }
   ],
   "history": [
      {
         "v1Compatibility": "{\"architecture\":\"amd64\",\"config\":{\"Hostname\":\"\",\"Domainname\":\"\",\"User\":\"\",\"AttachStdin\":false,\"AttachStdout\":false,\"AttachStderr\":false,\"ExposedPorts\":{\"80/tcp\":{}},\"Tty\":false,\"OpenStdin\":false,\"StdinOnce\":false,\"Env\":[\"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\",\"NGINX_VERSION=1.12.2-1~stretch\",\"NJS_VERSION=1.12.2.0.1.14-1~stretch\"],\"Cmd\":[\"nginx\",\"-g\",\"daemon off;\"],\"ArgsEscaped\":true,\"Image\":\"sha256:5125da1f0971ca2dbb51e9ac889bcf44dcf2bf5aa584508ccc838130d9afbb43\",\"Volumes\":null,\"WorkingDir\":\"\",\"Entrypoint\":null,\"OnBuild\":[],\"Labels\":{\"maintainer\":\"NGINX Docker Maintainers \\u003cdocker-maint@nginx.com\\u003e\"},\"StopSignal\":\"SIGTERM\"},\"container\":\"3150b3b4f95f2a750e3295169f8b0327e727af1aae9d1411b68d0e8fc7b5f135\",\"container_config\":{\"Hostname\":\"3150b3b4f95f\",\"Domainname\":\"\",\"User\":\"\",\"AttachStdin\":false,\"AttachStdout\":false,\"AttachStderr\":false,\"ExposedPorts\":{\"80/tcp\":{}},\"Tty\":false,\"OpenStdin\":false,\"StdinOnce\":false,\"Env\":[\"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\",\"NGINX_VERSION=1.12.2-1~stretch\",\"NJS_VERSION=1.12.2.0.1.14-1~stretch\"],\"Cmd\":[\"/bin/sh\",\"-c\",\"#(nop) \",\"CMD [\\\"nginx\\\" \\\"-g\\\" \\\"daemon off;\\\"]\"],\"ArgsEscaped\":true,\"Image\":\"sha256:5125da1f0971ca2dbb51e9ac889bcf44dcf2bf5aa584508ccc838130d9afbb43\",\"Volumes\":null,\"WorkingDir\":\"\",\"Entrypoint\":null,\"OnBuild\":[],\"Labels\":{\"maintainer\":\"NGINX Docker Maintainers \\u003cdocker-maint@nginx.com\\u003e\"},\"StopSignal\":\"SIGTERM\"},\"created\":\"2018-04-30T13:57:12.489317377Z\",\"docker_version\":\"17.06.2-ce\",\"id\":\"df43aa640285b3e22952edbf68c813572e048b078240145d1e4563584808d9c9\",\"os\":\"linux\",\"parent\":\"a33648714ef0db84a50e07fef54e430cd58217d8c23848594c02f36bd8780a8f\",\"throwaway\":true}"
      },
      {
         "v1Compatibility": "{\"id\":\"a33648714ef0db84a50e07fef54e430cd58217d8c23848594c02f36bd8780a8f\",\"parent\":\"ffb7dabfed035273818eddda54135673e6d8c550bb269c31a3a5496f6e846fa8\",\"created\":\"2018-04-30T13:57:12.180453254Z\",\"container_config\":{\"Cmd\":[\"/bin/sh -c #(nop)  STOPSIGNAL [SIGTERM]\"]},\"throwaway\":true}"
      },
      {
         "v1Compatibility": "{\"id\":\"ffb7dabfed035273818eddda54135673e6d8c550bb269c31a3a5496f6e846fa8\",\"parent\":\"996e92c399a57c1e391dcdd2e5b2ca35eb61005809f538d20b9f2a9962d25160\",\"created\":\"2018-04-30T13:57:11.908455358Z\",\"container_config\":{\"Cmd\":[\"/bin/sh -c #(nop)  EXPOSE 80/tcp\"]},\"throwaway\":true}"
      },
      {
         "v1Compatibility": "{\"id\":\"996e92c399a57c1e391dcdd2e5b2ca35eb61005809f538d20b9f2a9962d25160\",\"parent\":\"85e516b299ed57b887ba2ab4c84588c98ab15d9ef920ba55ace7d64f77b7284b\",\"created\":\"2018-04-30T13:57:11.617810743Z\",\"container_config\":{\"Cmd\":[\"/bin/sh -c ln -sf /dev/stdout /var/log/nginx/access.log \\t\\u0026\\u0026 ln -sf /dev/stderr /var/log/nginx/error.log\"]}}"
      },
      {
         "v1Compatibility": "{\"id\":\"85e516b299ed57b887ba2ab4c84588c98ab15d9ef920ba55ace7d64f77b7284b\",\"parent\":\"699c8955bad376a5e22ce1c8a7a7326eab6a8e9376059b28c91716471d683242\",\"created\":\"2018-04-30T13:57:10.725167216Z\",\"container_config\":{\"Cmd\":[\"/bin/sh -c set -x \\t\\u0026\\u0026 apt-get update \\t\\u0026\\u0026 apt-get install --no-install-recommends --no-install-suggests -y gnupg1 \\t\\u0026\\u0026 \\tNGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \\tfound=''; \\tfor server in \\t\\tha.pool.sks-keyservers.net \\t\\thkp://keyserver.ubuntu.com:80 \\t\\thkp://p80.pool.sks-keyservers.net:80 \\t\\tpgp.mit.edu \\t; do \\t\\techo \\\"Fetching GPG key $NGINX_GPGKEY from $server\\\"; \\t\\tapt-key adv --keyserver \\\"$server\\\" --keyserver-options timeout=10 --recv-keys \\\"$NGINX_GPGKEY\\\" \\u0026\\u0026 found=yes \\u0026\\u0026 break; \\tdone; \\ttest -z \\\"$found\\\" \\u0026\\u0026 echo \\u003e\\u00262 \\\"error: failed to fetch GPG key $NGINX_GPGKEY\\\" \\u0026\\u0026 exit 1; \\tapt-get remove --purge --auto-remove -y gnupg1 \\u0026\\u0026 rm -rf /var/lib/apt/lists/* \\t\\u0026\\u0026 dpkgArch=\\\"$(dpkg --print-architecture)\\\" \\t\\u0026\\u0026 nginxPackages=\\\" \\t\\tnginx=${NGINX_VERSION} \\t\\tnginx-module-xslt=${NGINX_VERSION} \\t\\tnginx-module-geoip=${NGINX_VERSION} \\t\\tnginx-module-image-filter=${NGINX_VERSION} \\t\\tnginx-module-njs=${NJS_VERSION} \\t\\\" \\t\\u0026\\u0026 case \\\"$dpkgArch\\\" in \\t\\tamd64|i386) \\t\\t\\techo \\\"deb http://nginx.org/packages/debian/ stretch nginx\\\" \\u003e\\u003e /etc/apt/sources.list \\t\\t\\t\\u0026\\u0026 apt-get update \\t\\t\\t;; \\t\\t*) \\t\\t\\techo \\\"deb-src http://nginx.org/packages/debian/ stretch nginx\\\" \\u003e\\u003e /etc/apt/sources.list \\t\\t\\t\\t\\t\\t\\u0026\\u0026 tempDir=\\\"$(mktemp -d)\\\" \\t\\t\\t\\u0026\\u0026 chmod 777 \\\"$tempDir\\\" \\t\\t\\t\\t\\t\\t\\u0026\\u0026 savedAptMark=\\\"$(apt-mark showmanual)\\\" \\t\\t\\t\\t\\t\\t\\u0026\\u0026 apt-get update \\t\\t\\t\\u0026\\u0026 apt-get build-dep -y $nginxPackages \\t\\t\\t\\u0026\\u0026 ( \\t\\t\\t\\tcd \\\"$tempDir\\\" \\t\\t\\t\\t\\u0026\\u0026 DEB_BUILD_OPTIONS=\\\"nocheck parallel=$(nproc)\\\" \\t\\t\\t\\t\\tapt-get source --compile $nginxPackages \\t\\t\\t) \\t\\t\\t\\t\\t\\t\\u0026\\u0026 apt-mark showmanual | xargs apt-mark auto \\u003e /dev/null \\t\\t\\t\\u0026\\u0026 { [ -z \\\"$savedAptMark\\\" ] || apt-mark manual $savedAptMark; } \\t\\t\\t\\t\\t\\t\\u0026\\u0026 ls -lAFh \\\"$tempDir\\\" \\t\\t\\t\\u0026\\u0026 ( cd \\\"$tempDir\\\" \\u0026\\u0026 dpkg-scanpackages . \\u003e Packages ) \\t\\t\\t\\u0026\\u0026 grep '^Package: ' \\\"$tempDir/Packages\\\" \\t\\t\\t\\u0026\\u0026 echo \\\"deb [ trusted=yes ] file://$tempDir ./\\\" \\u003e /etc/apt/sources.list.d/temp.list \\t\\t\\t\\u0026\\u0026 apt-get -o Acquire::GzipIndexes=false update \\t\\t\\t;; \\tesac \\t\\t\\u0026\\u0026 apt-get install --no-install-recommends --no-install-suggests -y \\t\\t\\t\\t\\t\\t$nginxPackages \\t\\t\\t\\t\\t\\tgettext-base \\t\\u0026\\u0026 rm -rf /var/lib/apt/lists/* \\t\\t\\u0026\\u0026 if [ -n \\\"$tempDir\\\" ]; then \\t\\tapt-get purge -y --auto-remove \\t\\t\\u0026\\u0026 rm -rf \\\"$tempDir\\\" /etc/apt/sources.list.d/temp.list; \\tfi\"]}}"
      },
      {
         "v1Compatibility": "{\"id\":\"699c8955bad376a5e22ce1c8a7a7326eab6a8e9376059b28c91716471d683242\",\"parent\":\"5a12309aaedf44e0747980c564d4c5a39b8613c945aeb1a0de05564ab55216de\",\"created\":\"2018-04-30T13:56:58.17473167Z\",\"container_config\":{\"Cmd\":[\"/bin/sh -c #(nop)  ENV NJS_VERSION=1.12.2.0.1.14-1~stretch\"]},\"throwaway\":true}"
      },
      {
         "v1Compatibility": "{\"id\":\"5a12309aaedf44e0747980c564d4c5a39b8613c945aeb1a0de05564ab55216de\",\"parent\":\"b96755dc9656074743d9dd291617f86fb5aad95c3f1c9e4f1411101aab21b3eb\",\"created\":\"2018-04-30T13:56:57.819870948Z\",\"container_config\":{\"Cmd\":[\"/bin/sh -c #(nop)  ENV NGINX_VERSION=1.12.2-1~stretch\"]},\"throwaway\":true}"
      },
      {
         "v1Compatibility": "{\"id\":\"b96755dc9656074743d9dd291617f86fb5aad95c3f1c9e4f1411101aab21b3eb\",\"parent\":\"0483928f21489548b99e04fdd943c445a6af3833069f959578125bf535a804ce\",\"created\":\"2018-04-30T13:55:06.091154073Z\",\"container_config\":{\"Cmd\":[\"/bin/sh -c #(nop)  LABEL maintainer=NGINX Docker Maintainers \\u003cdocker-maint@nginx.com\\u003e\"]},\"throwaway\":true}"
      },
      {
         "v1Compatibility": "{\"id\":\"0483928f21489548b99e04fdd943c445a6af3833069f959578125bf535a804ce\",\"parent\":\"6be500308632e8b0abf11ffedca4fc0048237dc4578d87030bff73ce9769c230\",\"created\":\"2018-04-28T07:09:59.664484364Z\",\"container_config\":{\"Cmd\":[\"/bin/sh -c #(nop)  CMD [\\\"bash\\\"]\"]},\"throwaway\":true}"
      },
      {
         "v1Compatibility": "{\"id\":\"6be500308632e8b0abf11ffedca4fc0048237dc4578d87030bff73ce9769c230\",\"created\":\"2018-04-28T07:09:59.28969784Z\",\"container_config\":{\"Cmd\":[\"/bin/sh -c #(nop) ADD file:ec5be7eec56a749752ca284359ece04f5eb0b981eac08b8855454c6b16e3893c in / \"]}}"
      }
   ],
   "signatures": [
      {
         "header": {
            "jwk": {
               "crv": "P-256",
               "kid": "ZWN2:4QKB:XIQV:KLUP:MN4P:2WS6:7XRS:NTDO:COR6:5MIM:NIF5:FDKY",
               "kty": "EC",
               "x": "1SkTPqKlx4a2-nWJ46O1Rzh1ScyOre-ZRwqIs5snwf0",
               "y": "9x1BuZFVNewX2Y-PJ0T-E4iWY5cfgrwtNMI2vH3j2oE"
            },
            "alg": "ES256"
         },
         "signature": "Qxy_keUgeWjLf7lYNXPYtDx8LG805Uam2SdiF5tnx75fOjlSx-VyhHMlKpZIBY748cMJuS_6uonziZJoYQ9BJA",
         "protected": "eyJmb3JtYXRMZW5ndGgiOjkzNTEsImZvcm1hdFRhaWwiOiJDbjAiLCJ0aW1lIjoiMjAxOS0xMS0yN1QxNDozNjowOFoifQ"
      }
   ]
}%
```
不存在的返回错误消息
error:
```bash
➜  ~  curl -X GET "http://registry:5000/v2/nginx/manifests/1.13"
{"errors":[{"code":"MANIFEST_UNKNOWN","message":"manifest unknown","detail":{"Tag":"1.13"}}]}
```



Go demo

```go
func isDockerImageInRegistry(registryAddress,name,tag string)error{
	path:="http://"+registryAddress+"/v2/"+name+"/manifests/"+tag
	//curl -X GET "http://registry:5000/v2/nginx/manifests/1.12"
	resp,err:=http.Get(path)
	if err!=nil{
		return errors.Errorf("http error:",err)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	//fmt.Println("resp:",string(body))
	var manifest DockerManifest
	err=json.Unmarshal(body,&manifest)
	if err!=nil{
		fmt.Println(err)
		return errors.Errorf("can not got this docker manifest")
	}
	//fmt.Println(manifest.Name,manifest.Tag,manifest.Arch)
	if manifest.Name!=name||manifest.Tag!=tag{
		return errors.Errorf("not this images")
	}
	return nil
}
```