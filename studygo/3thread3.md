
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
		defer fmt.Println("--a--")
		for {
			select {
				case _,ok:=<-ch1:
					if !ok{
						return
					}
					fmt.Print("a")
					ch2 <- 1
				case <-stop:
					close(ch1)
					close(ch2)
					close(ch3)
				return
			}
		}
	}()
	go func() {
		defer fmt.Println("--l--")
		for {
			select{
				case _,ok:=<-ch2:
					if !ok{
						fmt.Println("--l--")
						return
					}
					fmt.Print("l")
					ch3 <- 2
				case <-stop:
					close(ch1)
					close(ch2)
					close(ch3)
					return
			}
		}
	}()
	go func() {
		defer fmt.Println("--i--")
		for {
			select{
				case _,ok:=<-ch3:
					if !ok{
						return
					}
					fmt.Print("i")
					ch1 <- 3
				case <-stop:
					close(ch1)
					close(ch2)
					close(ch3)
					return
			}
		}
	}()
	ch1 <- 0
}
func main() {
	fmt.Println("output:")
	stop:=make(chan int)
	outputAli(stop)
	time.Sleep(1*time.Second)
	stop<-1
	time.Sleep(1*time.Second)
}
/*
GOROOT=/usr/local/go #gosetup
GOPATH=/Users/liu/work/go #gosetup
/usr/local/go/bin/go build -o /private/var/folders/hf/lwx68wgn4cb40d25cgq7z7f80000gn/T/___go_build_thread_go /Users/liu/work/go/src/studygo/thread.go #gosetup
/private/var/folders/hf/lwx68wgn4cb40d25cgq7z7f80000gn/T/___go_build_thread_go #gosetup
output:
alialialialialialialialialialialialialialialialialialialialialialialialialialialialialialialial
--l--
--l--
--i--
panic: send on closed channel

goroutine 7 [running]:
main.outputAli.func3(0xc000060180, 0xc0000600c0, 0xc000060060, 0xc000060120)
	/Users/liu/work/go/src/studygo/thread.go:57 +0x179
created by main.outputAli
	/Users/liu/work/go/src/studygo/thread.go:48 +0x145
*/

```