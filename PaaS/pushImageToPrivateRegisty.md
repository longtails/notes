### pushImageToPrivateRegistry

测试demo已经通过

```go
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	docker "github.com/fsouza/go-dockerclient"
	"github.com/pkg/errors"
	"io/ioutil"
	"net/http"
)
func main(){
	//k8scontroller.K8s()
}
func TestPushToRegistry() {
	repo:="abc"
	tag:="1.12"
	registry:="registry:5000"

	err:=do(registry,repo,tag)
	if err!=nil{
		fmt.Println(err)
	}else{
		fmt.Println("")
	}
}


/*
1. 将镜像push到registry:
  1) list images
  2) tag image
  3) push image to private registry
2. 检查一个镜像是否已经push到registry,isDockerImageInRegsitry
*/
type DockerManifest struct {
	SchemaVersion int `json:schemaVersion`
	Name string `json:name`
	Tag string `json:tag`
	Architecture string `json:architecture`
	FsLayers []interface{} `json:fsLayers`
	History []interface{} `json:history`
	Signatures []interface{} `json:signatrures`
}
func searchImage(client*docker.Client,repo,tag string)error{
	if client==nil{
		return errors.Errorf("client is nil")
	}
	//map[string][]string
	//docker images --filter=reference="hello:1.1" ,使用过滤器
	filter:=map[string][]string{"reference":{repo+":"+tag}}
	opts:=docker.ListImagesOptions{
		Filters: filter,
		All:     true,
		Digests: false,
		Filter:  "",
		//Filter:  "",
		Context: nil,
	}
	images,err:=client.ListImages(opts)
	//8 {sha256:f711d456dcc4b5a6e0187f5c3d1428feca26ec8f676f9e5d968375cb4d2c9b47
	// [hyperledger/fabric-baseos:amd64-0.4.16]
	// 1570186956 80834955 80834955
	// [hyperledger/fabric-baseos@sha256:80639554c03b7362e9a0895557f3e2323917ef1ec80b78caa48d71402c78de8d]
	// map[]}
	repoTags:=make(map[string]bool)
	if err!=nil{
		fmt.Println(err)
		return err
	}else{
		for _,img:=range images{
			fmt.Println(img)
			for _,tag:=range img.RepoTags{
				repoTags[tag]=true
			}
		}
	}
	//fmt.Println(repoTags)
	if ok,in:=repoTags[repo+":"+tag];ok&&in{
		//fmt.Println(repo+":"+tag+" exists!")
		return nil
	}else{
		return errors.Errorf("no such image!")
	}
}
func tagImage(client*docker.Client,repo,tag,newrepo,newtag string)error{
	tagopts:=docker.TagImageOptions{
		Repo:    newrepo, //镜像名
		Tag:     newtag, //标签
		Force:   false,
		Context: nil,
	}
	if err:=client.TagImage(repo+":"+tag,tagopts);err!=nil{
		//fmt.Println(err)
		return err
	}
	if err:=searchImage(client,newrepo,newtag);err!=nil{
		return err
	}
	return nil
}
func do(registry,repo,tag string)error{
	client,err:=docker.NewClient("unix:///var/run/docker.sock")
	if err!=nil{
		fmt.Println(err)
		return err
	}
	return pushToRegistry(client,registry,repo,tag)
}
func pushToRegistry(client*docker.Client,registry,repo,tag string)error{
	fmt.Println("----- image list -----")
	if err:=searchImage(client,repo,tag);err!=nil{
		return err
	}
	fmt.Println(repo+":"+tag+" exists!")
	newrepo:=registry+"/"+repo
	fmt.Println("----- tag -----")
	if err:=tagImage(client,repo,tag,newrepo,tag);err!=nil{
		return err
	}
	fmt.Println("tag image successful!")

	fmt.Println("----- push -----")
	outputbuf := bytes.NewBuffer(nil)
	pOpts:=docker.PushImageOptions{
		Name:              newrepo, //镜像名字，name前必须指定仓库名字，registry:5000/nginx
		Tag:               tag,  //镜像tag
		Registry:          registry,//"127.0.0.1:5000", //仓库地址
		OutputStream:      outputbuf,
		RawJSONStream:     false,
		InactivityTimeout: 0,
		Context:           nil,
	}
	//auth没开，用空
	if err:=client.PushImage(pOpts,docker.AuthConfiguration{});err!=nil{
		fmt.Println(err)
	}
	fmt.Println(outputbuf.String())
	if err:=isDockerImageInRegistry(registry,repo,tag);err!=nil{
		return errors.Errorf("can not push such image to private registry!")
	}else{
		fmt.Println("push successful!")
	}
	return nil
}

func isDockerImageInRegistry(registryAddress,name,tag string)error{
	//curl -X GET "http://registry:5000/v2/nginx/manifests/1.12"
	path:="http://"+registryAddress+"/v2/"+name+"/manifests/"+tag
	//curl -X GET "http://registry:5000/v2/nginx/manifests/1.12"
	//fmt.Println(path)
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
	//fmt.Println(manifest)
	if manifest.Name!=name||manifest.Tag!=tag{
		return errors.Errorf("not this images")
	}
	return nil
}

```