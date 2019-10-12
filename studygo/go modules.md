### Go Modules 


1个开关环境变量： GO111MODULE  
5个辅助环境变量： GOPROXY、GONOPROXY、GOSUMDB、GONOSUMDB、GOPRIVATE   
2个辅助概念：Go module proxy和Go checksum database   
2个主要文件：go.mod和go.sum   
1个主要管理子命令：go mod   
内置在几乎所有其他子命令中：go get、go install、go list、go test、go run、go build...   
Global Caching: 不同项目的相同模块版本只会在你的电脑上混存一份  



*go.mod*  

go.mod是启用了Go modules项目所必须的文件，描述了当前项目的愿信息，每一行都以一个动词开头，目前有一下5个动词：  
module: 用于定义当前项目的模块路径,mod path   
go: 用于设置预期的Go版本   
require：用于需求一个特定的模块版本   
exclude: 用于从使用中排除一个特定的模块版本   
replace: 用于将一个模块版本替换为另外一个模块版本   

```mod
module example.com/foobar  

go 1.13   

require(
    example.com/apple v0.1.2
    example.com/banana v1.2.3   
    example.com/banana/v2 v2.3.4
    example.com/pineapple v0.0.0-20190-1b0
)

exclude example.com/banana v1.2.4  

replace example.com/apple v0.1.2 => example.com/rda v0.1.0  
replace example.com/banana => example.com/hugebanana  
```



*go.sum*  

go.sum类似于dep的gopkg.lock，详细罗列了当前项目直接活简介依赖的所有模块版本以及哪些模块的SHA-256哈希值，确保这些模块版本不会被篡改  

```go.sum
github.com/robteix/testmod v1.0.0 h1:9EdH0EArQ/rkpss9Tj8gUnwx3w5p0jkzJrd5tRAhxnA=
github.com/robteix/testmod v1.0.0/go.mod h1:UVhi5McON9ZLc5kl5iN2bTXlL6ylcxE9VInV71RrlO8=
```

*GO111MODULE*  

auto：只在项目包含了go.mod文件时启用go modules,在go 1.13中仍然是默认值   
on：无脑启用go modules，推荐设置，未来版本中的默认值，让GOPATH从此称为历史  
off：禁用go modules  

*GOPROXY*   

goproxy的值是一个以英文逗号“,"分割的go module proxy列表，用于后续拉去模块版本时能够脱离传统的vcs方式从镜像站点快速拉取，它的值可以是"off"即禁止go 从任何地方拉取模块版本   

默认值：https://proxy.golang.org,direct 国内无法访问，可以用goproxy.cn代替：go env -w GOPROXY=https://goproxy.cn,direct   

direct,用于指示go回源到模块版本的源地址去抓去（如github等） 

当值列表中上一个go module proxy返回404/410错误时，go会自动尝试列表中的下一个，遇见“direct"时终止并回源，遇见EOF时终止并抛出类似"invalid version: unknown revision..."的错误   

*GOSUMDB*  

Go checksum database,用于拉取模块版本时保证拉取的模块版本数据未经篡改，它的值可以时“off"即禁止Go校验任何模块版本   
格式1: <SUMDB_NAME>+<PUBLIC_KEY>  
格式2: <SUMDB_NAME>+<PUBLIC_KEY><SUMDB_URL>   

默认值：sum.golang.org(之所以没有按照上面的格式，因为go对默认值做了特殊处理),国内无法访问，可以将goproxy设置为goproxy.cn（支持代理sum.golang.org）     

可被go module proxy代理   


*Go Checksum Database*

前身notary,透明公证人系统  
保护go模块的生态系统  
防止go从任何圆头（包括go module proxy）意外拉取经过篡改的模块版本，引入了意外代码更改   
go help module-auth   


*GONOPROXY、GONOSUMDB、GOPRIVATE*  

这三个变量都是用在当前项目依赖了私有模块，也就是依赖了有GOPROXY指定的Go module proxy或有GOSUMDB指定Go checksum database无法访问到的模块时的场景   

它们的值以英文逗号","分割的模块路径前缀，匹配规则同path.Match   

GOPRIVATE较为特殊，它的值将作为GONOPROXY和GONOSUMDB的默认值，所以建议只是用GOPRIVATE  
GOPRIVATE=*.corp.example.com表示所有模块路径以corp.example.com的下一级域名（team1.corp.exmaple.com）为前缀的模块版本都将不经过Go module proxy和Go checksum database，需要注意得失不包过corp.example.com本身  

go help module-private   


*Glabal Caching*  

同一个模块版本的数据只缓存一份，所有其他模块共享使用   

目前所有模块版本数据均缓存在$GOPATH/pkg/mod和$GOPATH/pkg/sum下，未来或将一致$GOCACHE/mod和$GOCACHE/sum下（当GOPATH被淘汰后）   

go clean -modcache 清理所有已缓存的模块版本数据   



*快速潜质项目至Go Mudules*   

1，升级到Go1.13(Go1.11 Go1.12迁移至Go modules问题太多)   
2，让GOPATH从脑海中小时，早一步踏入未来  

    go env -w GOBIN=$HOME?BIN  
    go env -w GO111MODULE=on  
    go env -w GOPROXY=https://goproxy.cn,direct  
3, 按照自己喜欢的目录结构重新组织项目（不用在$GOPATH/src里挣扎了)   
4, 在项目根目录下go mod init <OPTIONAN_MODULE_PATH>生成go.mod  

go help module-get go help gopath-get分别去了解Go modules启用和未启用两种状态下的go get行为  

用go get拉取新的依赖   

    go get golang.org/x/text@latest 拉取最新版本（优先选择tag)  
    go get golang.org/x/text@master 拉取mast分分支下的最新commit  
    go get golang.org/x/text@v0.3.2 拉取tag为v0.3.2的commit  
    go get golang.orgx/text@342b2e1 拉取hash为34b231的commit，最终会被转换为v0.3.2   

go get -u更新现有的所有依赖  
go mod download下载go.mod文件中指明的所有依赖  
go mod tidy整理现有的依赖  
go mod graph整理现有的依赖结构   
go mod init生成go.mod文件（go1.13中唯一一个可以生成go.mod文件的子命令)   
go mod edit编辑go.mod文件   
go mod vendor导出现有的所有依赖(事实上Go modules正在淡化Vendor的概念)   
go mod verify校验一个模块是否被窜改过  


*Go Modules问题*   

如何判断启用了Go Modules: 

在Go1.13中，一个项目只要包含了go.mod文件，且GO111MODULE不为off,那么GO就会为这个项目启动Go modules   
建议将GO111MODULE设置为on: go env -w GO111MODULE=on  
若当前项目没有包含go.mo文件，且GO111MODULE=on,那么每次一构建Go都会从头推算并拉取所需要的模块版本，但是并不会自动生成go.mod文件（go1.13,之前会自动生成)  

管理Go的环境变量：  



 