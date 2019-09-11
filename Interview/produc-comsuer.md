###  生产社消费者


刚才代码并不能正常工作，这里仅是提交一个可以正常工作的，思路是wheel[csize*3],body[csize]两个缓冲区，生产工人向两个缓冲区提交零件（随机性体现在生产工人并不知道要给谁），装配工人从缓冲区取两种零件并凑够一辆车。

```
package main
import (
   "fmt"
   "time"
)

type Factory struct{
   asize,bsize,csize int
   wheel chan int
   body chan int
}
func (f Factory)Work(){
   for i:=0;i<f.asize;i++{
      go func(){
         for{
            time.Sleep(time.Second)
            f.wheel<-1
         }
      }()
   }
   for i:=0;i<f.bsize;i++{
      go func(){
         for {
            time.Sleep(time.Second)
            f.body<-1
         }
      }()
   }
   for i:=0;i<f.csize;i++{
      go func(id int){
         for{
            <-f.body
            for i:=0;i<4;i++{
               <-f.wheel
            }
            fmt.Println("装配工人【",id,"】装配完成了一辆车")
         }
      }(i)
   }
}
func (f *Factory)init(a,b,c int){
   f.asize=a
   f.bsize=b
   f.csize=c
   f.body=make(chan int,f.csize)
   f.wheel=make(chan int,f.csize*4)
}
func main() {
   var f Factory
   f.init(4,10,10)
   f.Work()
   time.Sleep(time.Minute)
}
```