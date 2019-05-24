#### go-gc

低延迟要求
一个并发的GC是如何工作的？

Golang的三色标记法，并发gc,意味着将暂停时间转变为了调度问题，并且调度器可以配置是gc在一个很小的间隔运行。

   1.5 采用三色标记法，这种方式的mark可以渐进执行而不是每次扫描整个内存空间，可以减少stop the world时间
   go的内部对象并没有保存颜色的属性，三色知识对它们状态的描述，
   白色对象在它所在span的gcmarkBits中对应bit为0，
   灰色对象在它所在span的gcmarkBits中对应bit为1，并且对象在标记队列中，
   黑色对象在它所在span的gcmarkBits中对应bit为1，并且从队列标记中取出并处理。
   gc完成后，gcmarkBits会移动到allocBits然后重新分配一个全部为0的bitmap,这样黑色对象就变成白色。

   
```go
//初始化AB为根对象，总是可达的，GC未运行所以它们都是白色的
var A LinkedListNode;
var B LinkedListNode; 
// ...
//B.next=C
B.next = &LinkedListNode{next: nil}; 
// ...
//A.next=D ,当指针域改变时，其指向对象的颜色就会改变，因为创建新对象，必然会有指向它的指针，所以新对象会被上色
A.next = &LinkedListNode{next: nil}; 
//这时，GC启动，所以跟对象
*(B.next).next = &LinkedListNode{next: nil};
B.next = *(B.next).next;
B.next = nil;
```