### 用三个线程输出alialiali...

这个输出aliali没啥难度，难的在于如何退出，因为三个goroutine处于循环依赖中，这里处理的一个办法：
1. 对于goroutine a使用for-select方式，作为启动和退出的点，接收到stop chan int时,想goroutine l发送退出消息，而a不能退出，因为循环依赖，上一轮，它的前驱还没有把消息发送给它，所以需要等待来自goroutine i的消息；
2. goroutine对于ch2数据进行判断，如果是退出消息，则将退出传递给goroutine i,并且不需要等待，因为退出消息是它的前驱发来的，没有依赖要解决了；
3. gorouinte i在接收到 goroutine l发送的退出消息前，先将上一轮的消息发送给goroutine a，然后退出，同样没有依赖要解决了。

这样通过外部干涉+内部退出消息传递+退出goroutine等待的办法解决了循环依赖优雅退出的问题
```go
package main

import (
	"fmt"
	"time"
)
func outputAli(stop chan int) {
	ch1 := make(chan int)
	ch2 := make(chan int)
	ch3 := make(chan int)
	go func() {
		defer func(){
			fmt.Println("done:a!")
		}()
		for {
			select{
				case v:=<-ch1:
					if v==1{
						fmt.Print("a")
						ch2 <- 2
					}else{
						break
					}
				case <-stop:
					ch2<-0
					//goto sp
					<-ch1
					return
			}
		}
	}()
	go func() {
		defer func(){
			fmt.Println("done:l!")
		}()
		for {
			v:=<-ch2
			if v==2{
				fmt.Print("l")
				ch3 <- 3
			}else{
				ch3<-0
				break
			}
		}
	}()
	go func() {
		defer func(){
			fmt.Println("done:i!")
		}()
		for {
			v:=<-ch3
			if v==3 {
				fmt.Print("i")
				ch1 <- 1
			}else{
				break
			}
		}
	}()
	ch1 <- 1
}
/*
怎么让这个循环依赖停下来，外部干涉，改变传递的消息为退出消息，一轮后全部退出。
选择一个入口比如a，先把它stop,可以用select 接收一个stop chan int,但不能退出，因为它还有前驱，需要等待前驱将前一轮的消息发送完毕，再退出；
l接收来自前驱a的消息，若是输出控制则输出'l'并想后继i发送输出消息，否则向i发送退出消息，l不要等待前驱，因为是前驱通知退出的；
i接收来自前驱l的输出和退出消息，i将前一轮传递过来的消息发送给a,接着收到l的退出消息，直接退出即可。
最后三个goroutine退出顺序分别是l,i,a
*/
func main() {
	fmt.Println("output:")
	stop:=make(chan int)
	outputAli(stop)
	time.Sleep(10*time.Microsecond)
	stop<-1
	time.Sleep(1*time.Second)
}
```