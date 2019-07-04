### Golang

---
### 原理分析

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


5. 介绍下golang的runtime机制   
   
    Runtime负责管理任务调度、垃圾回收及运行环境;Go的goroutine、channel、gc等需要runtime支持，runtime和用户编译后的代码，被linker静态连接起来，形成一个可执行文件。    

    这个可执行文件由两部分组成：用户代码+runtime,runtime通过接口函数来管理这些高级功能，用户代码发起的系统调用会被runtime拦截并处理。

    Runtime的一个重要组件goroutine scheduler，负责追踪、调度每个goroutine运行，实际上从应用程序的process所属的thread pool中分配一个thread来执行这个goroutine。实际的系统调用、现成创建都是由runtime执行的。

    ![](https://reading.developerlearning.cn/images/goruntime.png)



6. 如何获取 go 程序运行时的协程数量, gc 时间, 对象数, 堆栈信息?

    runtime.ReadMemStats 可以获取以上所有信息, 注意: 调用此接口会触发 STW(Stop The World),主要是一些内存相关的信息，比如stack/heap obj,gc等；   

    runtime包有一系列的接口可以获得这些信息，比如:   
    runtime.NumGoroutine()获得协程数量;   
    runtime.NumCPU()获得cpu数;   
    runtime.CPUProfile() 查看消耗CPU的热点函数，能否减少调用次数，能否避免重复计算。   


7. 怎么调试golang的bug以及性能问题的？

    1. panic调用栈
    2. pprof
    3. 火焰图(配合压测)
    4. 使用go run -race 或者go build -race来进行竞争检测
    5. 查看系统 磁盘io/网络io/内存占用/cpu占用(配合压测)


8. 介绍下golang的make和 new的区别?

    new(T)是为一个T类型的新值分配空间，并将此空间初始化为T的零值，并返回这块内存空间的地址，也就是*T;   
    ```func new(Type) *Type```

    make(T)返回的是初始化之后的T，且只能用于slice,map,channel三种类型，make(T,args)返回初始化后T类型的值，且此新值并不是T的零值，而不是T的指针，而是初始化后的T值(元数据,原数据包含数据地址等)。   
    ```func make(Type, size IntegerType) Type ```


---
### 语言应用分析


- 以下代码有什么问题，说明原因。

    ```go
    type student struct {
        Name string
        Age  int
    }

    func pase_student() {
        m := make(map[string]*student)
        stus := []student{
            {Name: "zhou", Age: 24},
            {Name: "li", Age: 23},
            {Name: "wang", Age: 22},
        }
        for _, stu := range stus {//stu是值，所以&stu操作是该变量地址，而不是爹迭代的值
            m[stu.Name] = &stu
        }

    }
    /*
    //错误代码
    for _, stu := range stus {
        stu.Age = stu.Age+10
    }
    */
    ```



- 下面的代码会输出什么，并说明原因,goroutine闭包

    整体输出比较随机，其中A的i值相对固定，是一个闭包，和外部i是同一个变量，所以最后i一致；而B是函数，会传入值拷贝，所以i从0-9。
    ```go
    func main() {
        runtime.GOMAXPROCS(1)
        wg := sync.WaitGroup{}
        wg.Add(20)
        for i := 0; i < 10; i++ {
            //闭包，同一个变量i，最后i一致,协程中读取的是当前i的最新值；
            //不加控制，循环更新比协程快，所以最后看到10
            //如果加上time.Sleep(time.Second),就会发现依次输出0-9，因为这时外部循环更新慢
            go func() {
                fmt.Println("A: ", i)
                wg.Done()
            }()
        }
        for i := 0; i < 10; i++ {
            go func(i int) {
                fmt.Println("B: ", i)
                wg.Done()
            }(i)
        }
        wg.Wait()
    }
    /*
    B: 9 A: 10 A: 10 A: 10 A: 10 A: 10 A: 10 A: 10 A: 10 A: 10 A: 10 B: 0 B: 1 B: 2 B: 3 B: 4 B: 5 B: 6 B: 7 B: 8 
    */
    ```

- go的组合继承,下面代码会输出什么？

    ```go
    type People struct{}

    func (p *People) ShowA() {
        fmt.Println("showA")
        p.ShowB()//这时是p是people类型，所以只能输出People的
    }
    func (p *People) ShowB() {
        fmt.Println("showB")
    }

    type Teacher struct {
        People //struct 定义，组合进来，有重复的函数名
    }

    func (t *Teacher) ShowB() {
        fmt.Println("teacher showB")
    }

    func main() {
        t := Teacher{}
        t.ShowA()
    }
    /*
    showA
    showB
    */
    ```

    go的struct可以类型转化吗？


- 下面的代码有什么问题?

    可能会出现fatal error: concurrent map read and map write.读写冲突
    ```go
    type UserAges struct {
        ages map[string]int
        sync.Mutex
    }

    func (ua *UserAges) Add(name string, age int) {
        ua.Lock()
        defer ua.Unlock()
        ua.ages[name] = age
    }

    func (ua *UserAges) Get(name string) int {
        if age, ok := ua.ages[name]; ok {
            return age
        }
        return -1
    }
    //test
    func main() {
        var a UserAges
        a.ages = make(map[string]int)
        go func() {
            for i := 0; i < 1000; i++ {
                a.Add("abc", 10)
            }
        }()
        for i := 0; i < 1000; i++ {
            go a.Get("abc")
        }
    }
    ```
    竞态分析，对Add和
    ```bash
    liudeMacBook-Pro:~ liu$ go run -race test.go 
    ==================
    WARNING: DATA RACE
    Read at 0x00c000086000 by goroutine 6:
    runtime.mapaccess2_faststr()
        /usr/local/go/src/runtime/map_faststr.go:101 +0x0
    main.(*UserAges).Get()
        /Users/liu/test.go:17 +0x6f

    Previous write at 0x00c000086000 by goroutine 5:
    runtime.mapassign_faststr()
        /usr/local/go/src/runtime/map_faststr.go:190 +0x0
    main.(*UserAges).Add()
        /Users/liu/test.go:13 +0xac
    main.main.func1()
        /Users/liu/test.go:28 +0x5f

    Goroutine 6 (running) created at:
    main.main()
        /Users/liu/test.go:32 +0x10e

    Goroutine 5 (running) created at:
    main.main()
        /Users/liu/test.go:26 +0xce
    ==================
    ```



- 下面的迭代会有什么问题

    ```go
    func (set *threadSafeSet) Iter() <-chan interface{} {
        ch := make(chan interface{})
        go func() {
            set.RLock()
            //set锁住，之后因为无缓冲chan,所以在外部未取数据，这里会阻塞，此时set无法被其他人读取
            //改进，改为带缓冲chan
            for elem := range set.s {
                ch <- elem
            }
            close(ch)
            set.RUnlock()
        }()
        return ch
    }
    ```

- **golang的方法集**

    ```go
    package main
    import (
        "fmt"
    )
    type People interface {
        Speak(string) string
    }

    type Stduent struct{}

    func (stu *Stduent) Speak(think string) (talk string) {
        if think == "bitch" {
            talk = "You are a good boy"
        } else {
            talk = "hi"
        }
        return
    }
    func main() {
        //var peo People = &Stduent{}//可以通过
        var peo People = Stduent{}//这里通不过,但可以将方法主体取消*，这样就可以了
        //所以，interface的方法集后，对象方法定义时用的指针还是值，这里就比较严格的体现出来了
        //平常不经过interface,go中没有专门的调用函数时的指针标志，都是.取，所以屏蔽了这些问题
        //综合来说，还是你用的指针，那就用指针对象调用函数，用的值，就用值对象调用函数
        think := "bitch"
        fmt.Println(peo.Speak(think))
    }
    ```

- 空接口：以下代码打印出来什么内容，说出为什么。


    ```go
    package main
    import  "fmt"

    type People interface {
        Show()
    }
    type Student struct{}
    func (stu *Student) Show() {}
    //var in interface{},才是一个空接口，即in==nil
    func live() People { //People是接口，是个值对象，注意，接口有数据结构，它不像c的指针
        var stu *Student
        return stu
    }
    func main() {
        var in interface{}
        fmt.Println(live()) //<nil> ,这是因为toString()输出的是data部分
        fmt.Println(in) //<nil> ，这俩data部分都是nil，但是People有itab方法集合数据
        if in == nil {
            fmt.Println("nil")
        }
        if live() == nil {
            fmt.Println("AAAAAAA")
        } else {
            fmt.Println("BBBBBBB")
        }
    }
    ```
    go中接口分为两种：
    ```go
    var in interface{}//空接口
    type People interface{
        Show() //这不是空接口，因为，这里有方法集合，是要记录的，即是有数据的
    }
    ```
    两种接口的底层结构：
    ```go
    type eface struct {      //空接口
        _type *_type         //类型信息
        data  unsafe.Pointer //指向数据的指针(go语言中特殊的指针类型unsafe.Pointer类似于c语言中的void*)
    }
    type iface struct {      //带有方法的接口
        tab  *itab           //存储type信息还有结构实现方法的集合
        data unsafe.Pointer  //指向数据的指针(go语言中特殊的指针类型unsafe.Pointer类似于c语言中的void*)
    }
    type _type struct {
        size       uintptr  //类型大小
        ptrdata    uintptr  //前缀持有所有指针的内存大小
        hash       uint32   //数据hash值
        tflag      tflag
        align      uint8    //对齐
        fieldalign uint8    //嵌入结构体时的对齐
        kind       uint8    //kind 有些枚举值kind等于0是无效的
        alg        *typeAlg //函数指针数组，类型实现的所有方法
        gcdata    *byte
        str       nameOff
        ptrToThis typeOff
    }
    type itab struct {
        inter  *interfacetype  //接口类型
        _type  *_type          //结构类型
        link   *itab
        bad    int32
        inhash int32
        fun    [1]uintptr      //可变大小 方法集合
    }
    ```