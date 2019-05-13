### Golang

1. select会速记选择一个可用的通道做收发操作
2. go语言局部变量分配在栈还是堆上？
   go语言编译器会做逃逸分析，决定将变量放在栈还是堆；当发现变量的作用域没有超出函数范围，会放在栈上，否则放在堆上。不论是new的对象，还是普通创建的。
3. 简述一下对Go垃圾回收机制的理解？
   [go-gc](https://segmentfault.com/a/1190000018161588)

4. 简述golang的协程调度原理？
   M-P-G模型 [Goroutine并发调度模型深度解析之手撸一个协程池](http://blog.taohuawu.club/article/42)