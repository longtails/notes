### Hyperledger Fabric make: *** No rule to make target问题


最近一段时间，改Fabric代码，发现没法编译了！make总是报找不到target!
```bash
➜  fabric git:(master) ✗ make configtxgen
make: *** No rule to make target `.build/bin/configtxgen', needed by `configtxgen'.  Stop.
```
make 输出debug信息，没有error,只是告诉必须重新make
```bash
➜  fabric git:(master) ✗ make configtxgen -d
...
  Must remake target `.build/bin/configtxgen'.
make: *** No rule to make target `.build/bin/configtxgen', needed by `configtxgen'.  Stop.
➜  fabric git:(master) ✗
```


后来，在其他机器上发现，存在.build文件的可以通过编译。  
从对应版本的项目中复制fabric/.build过来，就可以编译了。

```bash
➜  fabric git:(master) ✗ cp ../fabric-dev/.build .
cp: ../fabric-dev/.build is a directory (not copied).
➜  fabric git:(master) ✗ cp -rf  ../fabric-dev/.build .
➜  fabric git:(master) ✗ make configtxgen
make: Circular .build/bin/configtxgen <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/configtxlator <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/configtxlator <- .build/bin/configtxlator dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/configtxlator dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/cryptogen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/configtxgen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/configtxlator dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/cryptogen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/docker/bin/peer dependency dropped.
.build/bin/cryptogen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/cryptogen/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/cryptogen
Binary available as .build/bin/cryptogen
.build/bin/configtxlator
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxlator/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/configtxlator
Binary available as .build/bin/configtxlator
.build/bin/configtxgen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxgen/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/configtxgen
Binary available as .build/bin/configtxgen

```

我想，这是不是make成功过，后续make检测到对应文件存在，就不重新编译了，但是中间必要的部分又被我删掉，所以导致了失败。

那解决办法两个：  
一、恢复中间文件，这个从别的项目复制过来就行，注意相对版本   
二、强制make重新编译，但是对make不太熟，怎么操作不明白。中间还产生了哪些中间文件不清楚，fabric/makefile有点多就不细读了。(未解决)

```bash
make configtxgen -p 可以看到搜索的过程
```

---
测试.build中哪些文件，影响了编译
```bash
➜  fabric git:(master) ✗ cd .build
➜  .build git:(master) ✗ ls
bin                  image
docker               sampleconfig.tar.bz2
➜  .build git:(master) ✗ cd ..
➜  fabric git:(master) ✗ rm -rf .build
➜  fabric git:(master) ✗ ls -a
.                  Gopkg.toml         examples           protos
..                 LICENSE            go.mod             release
.dockerignore      Makefile           go.sum             release_notes
.git               README.md          gossip             sampleconfig
.gitattributes     bccsp              gotools.mk         scripts
.gitignore         ci.properties      idemix             settings.gradle
.gitreview         cmd                images             test-pyramid.png
.idea              common             integration        testingInfo.rst
.travis.yml        core               log                token
CHANGELOG.md       devenv             log2               tox.ini
CODE_OF_CONDUCT.md discovery          msp                unit-test
CONTRIBUTING.md    docker-env.mk      orderer            vendor
Gopkg.lock         docs               peer
➜  fabric git:(master) ✗ make configtxgen
make: *** No rule to make target `.build/bin/configtxgen', needed by `configtxgen'.  Stop.
➜  fabric git:(master) ✗
```

```bash
➜  .build git:(master) ✗ ls
bin                  docker               image                sampleconfig.tar.bz2
➜  .build git:(master) ✗ rm -rf bin
➜  .build git:(master) ✗ cd ..

➜  fabric git:(master) ✗ make configtxgen
make: Circular .build/bin/configtxgen <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/configtxlator <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/configtxlator <- .build/bin/configtxlator dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/configtxlator dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/cryptogen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/configtxgen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/configtxlator dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/cryptogen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/docker/bin/peer dependency dropped.
.build/bin/cryptogen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/cryptogen/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/cryptogen
Binary available as .build/bin/cryptogen
.build/bin/configtxlator
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxlator/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/configtxlator
Binary available as .build/bin/configtxlator
.build/bin/configtxgen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxgen/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/configtxgen
Binary available as .build/bin/configtxgen

```
删除.build/bin .build/docker，后make configtxgen
```bash
➜  fabric git:(master) ✗ ls .build
bin                  image
docker               sampleconfig.tar.bz2
➜  fabric git:(master) ✗ rm -rf  .build/docker

➜  fabric git:(master) ✗ make configtxgen
make: Circular .build/bin/configtxgen <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/configtxlator <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/configtxlator <- .build/bin/configtxlator dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/configtxlator dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/cryptogen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/configtxgen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/configtxlator dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/cryptogen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/docker/bin/peer dependency dropped.
Building .build/docker/bin/peer
# github.com/hyperledger/fabric/peer
/tmp/go-link-987887359/000006.o: In function `pluginOpen':
/workdir/go/src/plugin/plugin_dlopen.go:19: warning: Using 'dlopen' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-987887359/000021.o: In function `mygetgrouplist':
/workdir/go/src/os/user/getgrouplist_unix.go:16: warning: Using 'getgrouplist' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-987887359/000020.o: In function `mygetgrgid_r':
/workdir/go/src/os/user/cgo_lookup_unix.go:38: warning: Using 'getgrgid_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-987887359/000020.o: In function `mygetgrnam_r':
/workdir/go/src/os/user/cgo_lookup_unix.go:43: warning: Using 'getgrnam_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-987887359/000020.o: In function `mygetpwnam_r':
/workdir/go/src/os/user/cgo_lookup_unix.go:33: warning: Using 'getpwnam_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-987887359/000020.o: In function `mygetpwuid_r':
/workdir/go/src/os/user/cgo_lookup_unix.go:28: warning: Using 'getpwuid_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-987887359/000004.o: In function `_cgo_18049202ccd9_C2func_getaddrinfo':
/tmp/go-build/cgo-gcc-prolog:49: warning: Using 'getaddrinfo' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
.build/bin/cryptogen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/cryptogen/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/cryptogen
Binary available as .build/bin/cryptogen
.build/bin/configtxlator
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxlator/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/configtxlator
Binary available as .build/bin/configtxlator
.build/bin/configtxgen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxgen/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/configtxgen
Binary available as .build/bin/configtxgen
➜  fabric git:(master) ✗

```

出现了！
删除.build/image后无法编译configtxgen,

```bash
➜  fabric git:(master) ✗ ls .build
bin                  image
docker               sampleconfig.tar.bz2
➜  fabric git:(master) ✗ rm -rf  .build/image
➜  fabric git:(master) ✗ make configtxgen
make: Nothing to be done for `configtxgen'.
➜  fabric git:(master) ✗
```
恢复.build/image后，可重新编译
```bash
➜  fabric git:(master) ✗ make configtxgen
make: Circular .build/bin/configtxgen <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/configtxlator <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/configtxlator <- .build/bin/configtxlator dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/configtxlator dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/cryptogen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/configtxgen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/configtxlator dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/cryptogen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/docker/bin/peer dependency dropped.
Building .build/docker/bin/peer
.build/bin/cryptogen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/cryptogen/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/cryptogen
Binary available as .build/bin/cryptogen
.build/bin/configtxlator
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxlator/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/configtxlator
Binary available as .build/bin/configtxlator
.build/bin/configtxgen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxgen/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/configtxgen
Binary available as .build/bin/configtxgen
```
删除sampleconfig.tar.bz2仍可编译，会通过tar出新的
```bash
➜  fabric git:(master) ✗ ls .build
bin                  image
docker               sampleconfig.tar.bz2
➜  fabric git:(master) ✗ rm .build/sampleconfig.tar.bz2
➜  fabric git:(master) ✗ make configtxgen
make: Circular .build/bin/configtxgen <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/configtxlator <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/configtxlator <- .build/bin/configtxlator dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/configtxlator dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/cryptogen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/configtxgen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/configtxlator dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/cryptogen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/docker/bin/peer dependency dropped.
(cd sampleconfig && tar -jc *) > .build/sampleconfig.tar.bz2
Building .build/docker/bin/peer
# github.com/hyperledger/fabric/peer
/tmp/go-link-480341836/000006.o: In function `pluginOpen':
/workdir/go/src/plugin/plugin_dlopen.go:19: warning: Using 'dlopen' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-480341836/000021.o: In function `mygetgrouplist':
/workdir/go/src/os/user/getgrouplist_unix.go:16: warning: Using 'getgrouplist' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-480341836/000020.o: In function `mygetgrgid_r':
/workdir/go/src/os/user/cgo_lookup_unix.go:38: warning: Using 'getgrgid_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-480341836/000020.o: In function `mygetgrnam_r':
/workdir/go/src/os/user/cgo_lookup_unix.go:43: warning: Using 'getgrnam_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-480341836/000020.o: In function `mygetpwnam_r':
/workdir/go/src/os/user/cgo_lookup_unix.go:33: warning: Using 'getpwnam_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-480341836/000020.o: In function `mygetpwuid_r':
/workdir/go/src/os/user/cgo_lookup_unix.go:28: warning: Using 'getpwuid_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-480341836/000004.o: In function `_cgo_18049202ccd9_C2func_getaddrinfo':
/tmp/go-build/cgo-gcc-prolog:49: warning: Using 'getaddrinfo' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
.build/bin/cryptogen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/cryptogen/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/cryptogen
Binary available as .build/bin/cryptogen
.build/bin/configtxlator
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxlator/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/configtxlator
Binary available as .build/bin/configtxlator
.build/bin/configtxgen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxgen/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/configtxgen
Binary available as .build/bin/configtxgen
```


最后，删掉除.build/image外其他文件，仍可编译
```bash
➜  fabric git:(master) ✗ ls .build
bin                  image
docker               sampleconfig.tar.bz2
➜  fabric git:(master) ✗ cd .build
➜  .build git:(master) ✗ ls
bin                  image
docker               sampleconfig.tar.bz2
➜  .build git:(master) ✗ rm -rf bin
➜  .build git:(master) ✗ rm -rf docker
➜  .build git:(master) ✗ rm -rf sampleconfig.tar.bz2
➜  .build git:(master) ✗ ls
image
➜  .build git:(master) ✗ cd ..
➜  fabric git:(master) ✗ make configtxgen
make: Circular .build/bin/configtxgen <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/configtxlator <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/configtxlator <- .build/bin/configtxlator dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/configtxgen dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/configtxlator dependency dropped.
make: Circular .build/bin/cryptogen <- .build/bin/cryptogen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/configtxgen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/configtxlator dependency dropped.
make: Circular .build/docker/bin/peer <- .build/bin/cryptogen dependency dropped.
make: Circular .build/docker/bin/peer <- .build/docker/bin/peer dependency dropped.
(cd sampleconfig && tar -jc *) > .build/sampleconfig.tar.bz2
Building .build/docker/bin/peer
# github.com/hyperledger/fabric/peer
/tmp/go-link-426226281/000006.o: In function `pluginOpen':
/workdir/go/src/plugin/plugin_dlopen.go:19: warning: Using 'dlopen' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-426226281/000021.o: In function `mygetgrouplist':
/workdir/go/src/os/user/getgrouplist_unix.go:16: warning: Using 'getgrouplist' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-426226281/000020.o: In function `mygetgrgid_r':
/workdir/go/src/os/user/cgo_lookup_unix.go:38: warning: Using 'getgrgid_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-426226281/000020.o: In function `mygetgrnam_r':
/workdir/go/src/os/user/cgo_lookup_unix.go:43: warning: Using 'getgrnam_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-426226281/000020.o: In function `mygetpwnam_r':
/workdir/go/src/os/user/cgo_lookup_unix.go:33: warning: Using 'getpwnam_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-426226281/000020.o: In function `mygetpwuid_r':
/workdir/go/src/os/user/cgo_lookup_unix.go:28: warning: Using 'getpwuid_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/tmp/go-link-426226281/000004.o: In function `_cgo_18049202ccd9_C2func_getaddrinfo':
/tmp/go-build/cgo-gcc-prolog:49: warning: Using 'getaddrinfo' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
.build/bin/cryptogen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/cryptogen/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/cryptogen
Binary available as .build/bin/cryptogen
.build/bin/configtxlator
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxlator/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/configtxlator
Binary available as .build/bin/configtxlator
.build/bin/configtxgen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxgen/metadata.CommitSHA=56c6365" github.com/hyperledger/fabric/common/tools/configtxgen
Binary available as .build/bin/configtxgen
```

所以，这个./build/image中存储了哪些信息？image下是几个Dockerfile,tools/Dockerfile下是编译用的
```bash
➜  image git:(master) ✗ tree
.
├── peer
│   ├── Dockerfile
│   └── payload
│       ├── peer
│       └── sampleconfig.tar.bz2
└── tools
    └── Dockerfile

3 directories, 4 files

➜  image git:(master) ✗ cat tools/Dockerfile
# Copyright Greg Haskins All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
FROM hyperledger/fabric-baseimage:amd64-0.4.15 as builder
WORKDIR /opt/gopath
RUN mkdir src && mkdir pkg && mkdir bin
ADD . src/github.com/hyperledger/fabric
WORKDIR /opt/gopath/src/github.com/hyperledger/fabric
ENV EXECUTABLES go git curl
RUN make configtxgen configtxlator cryptogen peer discover idemixgen

FROM hyperledger/fabric-baseimage:amd64-0.4.15
ENV FABRIC_CFG_PATH /etc/hyperledger/fabric
RUN apt-get update && apt-get install -y jq
VOLUME /etc/hyperledger/fabric
COPY --from=builder /opt/gopath/src/github.com/hyperledger/fabric/.build/bin /usr/local/bin
COPY --from=builder /opt/gopath/src/github.com/hyperledger/fabric/sampleconfig $FABRIC_CFG_PATH
LABEL org.hyperledger.fabric.version=1.4.2 \
      org.hyperledger.fabric.base.version=0.4.15
➜  image git:(master) ✗

```


---
但，也是奇怪，拉取官方Fabric，checkout到v1.4.2，ls -a，没有看到.build，但却可以make编译  
是否存在缓存啥的？--｜不知道。。。(当然，这里代码没改过，上述的代码是改过的)

```bash
➜  fabric.12.notchanged git:(c6cc550cb) ✗ cd ..
➜  hyperledger mv fabric fabric.last
➜  fabric.12.notchanged git:(c6cc550cb) ✗ rm -rf .build
➜  fabric.12.notchanged git:(c6cc550cb) ✗ make configtxgen
find: /Users/liu/work/go/src/github.com/hyperledger/fabric/core/chaincode/shim: No such file or directory
.build/bin/configtxgen
CGO_CFLAGS=" " GOBIN=/Users/liu/work/go/src/github.com/hyperledger/fabric.12.notchanged/.build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxgen/metadata.CommitSHA=c6cc550cb" github.com/hyperledger/fabric/common/tools/configtxgen
Binary available as .build/bin/configtxgen
➜  fabric.12.notchanged git:(c6cc550cb) ✗
```

好在，现在可以继续工作，编译了。