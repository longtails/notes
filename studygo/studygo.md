### Golang

1. select会速记选择一个可用的通道做收发操作
2. go语言局部变量分配在栈还是堆上？
   go语言编译器会做逃逸分析，决定将变量放在栈还是堆；当发现变量的作用域没有超出函数范围，会放在栈上，否则放在堆上。不论是new的对象，还是普通创建的。
3. 简述一下对Go垃圾回收机制的理解？
   [go-gc](https://segmentfault.com/a/1190000018161588)

   1.5 采用三色标记法，这种方式的mark可以渐进执行而不是每次扫描整个内存空间，可以减少stop the world时间
   go的内部对象并没有保存颜色的属性，三色知识对它们状态的描述，
   白色对象在它所在span的gcmarkBits中对应bit为0，
   灰色对象在它所在span的gcmarkBits中对应bit为1，并且对象在标记队列中，
   黑色对象在它所在span的gcmarkBits中对应bit为1，并且从队列标记中取出并处理。
   gc完成后，gcmarkBits会移动到allocBits然后重新分配一个全部为0的bitmap,这样黑色对象就变成白色。
   
   1.8 采用混合写屏障，

   Go包含两大可调节的方法来控制GC,一个是SetGCPerconet,另一个是SetMaxHeap。分别表示想要使用的CPU以及内存。

4. 简述golang的协程调度原理？
   M-P-G模型 [Goroutine并发调度模型深度解析之手撸一个协程池](http://blog.taohuawu.club/article/42)


