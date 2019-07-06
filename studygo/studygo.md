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

- interface.(type)

```go
package main
import "fmt"
func test(i interface{}) {
	switch i.(type) {
	case int:
		fmt.Println("int")
	case string:
		fmt.Println("string")
	default:
		fmt.Println("other")
	}
}
func main() {
	test(10)//int
	test("hello")//string
}
```

- 函数返回值，指定命名，要么全部命名，要么全不

```go
func funcMui(x,y int)(sum int,err error){
    return x+y,nil
}
```
- defer+闭包+返回值:汇编分析

这里需要理解return x,和返回值；return x不是原子操作，它分为两部分，设置返回值+RET；设置返回值，在汇编的角度上是将输出存在了规定好的内存上（调用函数前会先留出返回值、参数的空间，接着是函数栈），所以设置返回值，就是把数复制到这里，而命名参数则是获得了这部分空间的地址，只要在RET前，做改动，都会更新到返回值空间上。
```bash
返回值 = xxx
调用defer函数
空的return
```
栈空间：
```bash
+-----------+----------- 
|  返回值N   |  
+-----------+  
|   ...     | 
+-----------+ 
|  返回值1   |   
+---------+-+      
|  参数2     |   在调用函数中，上述代码就是main函数中
+-----------+       
|   ...     | 
+-----------+     
|  参数1     |  
+-----------+ 
|  返回地址  |   调用结束后PC指向的位置
+-----------+---------bp值
|  局部变量  |   
|    ...    |   被调用数栈祯,上述代码就是DeferFuncX中
|           |
+-----------+---------sp值
--------------------- 
```
```go
package main

func main() {

	println(DeferFunc1(1))//4
	println(DeferFunc2(1))//1
	println(DeferFunc3(1))//3
}

func DeferFunc1(i int) (t int) {
	t = i
	defer func() {
		t += 3
	}()
	return t  //这个其实return不return无所谓，因为函数内直接更新了返回值
}

func DeferFunc2(i int) int {
	t := i
	defer func() {
		t += 3
	}()
	return t //这个地方需要return,首先设置返回值1，接着defer操作，不应用到返回值，接着RET
}

func DeferFunc3(i int) (t int) {
	defer func() {
		t += i
	}()
	return 2 //这个地方，设置返回值2，即t=2,defer操作，直接更新应用t+=i,即返回值为3,最后RET
}

```


- make和new，是否可以编译通过？如果通过，输出什么？

```go
func main() {
	list := new([]int)
	list = append(list, 1)
	fmt.Println(list)
}
```
正确：
```go
package main

import "fmt"

func main() {
	//不匹配，new返回Type=&[]int
	//list := new([]int)
	//append需要的类型是[]int
	//list = append(list, 1)
	//1:
	list1 := new([]int)
	*list1 = append(*list1, 1)
	fmt.Println(list1)//&[1]
	//或者用make,make返回的是Type=[]int的对象(引用)
	list2 := make([]int, 0)
	list2 = append(list2, 1)
	fmt.Println(list2) //[1]
}
```
new(T) 为一个 T 类型新值分配空间并将此空间初始化为 T 的零值，返回的是新值的地址，也就是 T 类型的指针 *T，该指针指向 T 的新分配的零值。  
make 只能用于 slice，map，channel 三种类型，make(T, args) 返回的是初始化之后的 T 类型的值，这个新值并不是 T 类型的零值，也不是指针 *T，是经过初始化之后的 T 的引用。

- 是否可以编译通过？如果通过，输出什么？
```go
package main

import "fmt"

func main() {
	s1 := []int{1, 2, 3}
	s2 := []int{4, 5}
	s1 = append(s1, s2)//这里忘了...,应该是s1=append(s1,s2...)
	fmt.Println(s1)
}

```

- 是否可以编译通过？如果通过，输出什么？

```go
func main() {

	sn1 := struct {
		age  int
		name string
	}{age: 11, name: "qq"}
	sn2 := struct {
		age  int
		name string  //这里都是值类型，可以比较
	}{age: 11, name: "qq"}

	if sn1 == sn2 {
		fmt.Println("sn1 == sn2")
	}

	sm1 := struct {
		age int
		m   map[string]string  //map是引用类型，不能用==比较，所以编译不通过
	}{age: 11, m: map[string]string{"a": "1"}}
	sm2 := struct {
		age int
		m   map[string]string
	}{age: 11, m: map[string]string{"a": "1"}}

	if sm1 == sm2 { //这里编译不过，可以改为reflect.DeepEqual(sm1, sm2) ，这样会通过

		fmt.Println("sm1 == sm2")
	}
}

```

- 是否可以编译通过？如果通过，输出什么？

```go
func Foo(x interface{}) {//考察空接口和接口的内部结构
	if x == nil {
		fmt.Println("empty interface")
		return
	}
	fmt.Println("non-empty interface")
}
func main() {
	var x *int = nil
	Foo(x)
}
```

- 是否可以编译通过？如果通过，输出什么？

只有指针、引用类型、function、channel可以设置为nil
```go
package main

import "fmt"

func GetValue(m map[int]string, id int) (string, bool) {
	if _, exist := m[id]; exist {
		return "存在数据", true
	}
	return nil, false //编译不过，因为只有指针,引用类型,func,channel可以设置为nil
	//return "不存在", false
}
func main() {
	intmap := map[int]string{
		1: "a",
		2: "bb",
		3: "ccc",
	}

	v, err := GetValue(intmap, 3)
	fmt.Println(v, err)
}
```

- 是否可以编译通过？如果通过，输出什么？

```go
const ( 
	x = iota  //0
    y         //1 自增
	z = "zz" //这个也占用iota增量
	k   //直接重复上一个变量初始值
    p = iota
    -  //跳过递增,是指为m跳过了这个位置的增，但还是增了,这个位置为5
    m //m则为6
)

func main()  {
	fmt.Println(x,y,z,k,p)
}
```

---

- 变量简短模式，编译执行下面代码会出现什么?

```go
package main

import _ "fmt"

var (
	size     := 1024//编译不过，改为size =1024
	max_size = size * 2
)

func main() {
	println(size, max_size)
}
```


- 下面函数有什么问题？

常量不同于变量的在运行期分配内存，常量通常会被编译器在预处理阶段直接展开，作为指令数据使用，

```go
package main
const cl  = 100

var bl    = 123

func main()  {
    println(&bl,bl)
    println(&cl,cl) //常量获取地址，因为不会为常量分配地址，而是在编译时直接展开
}
```



- 编译执行下面代码会出现什么?

goto不能跳转到其他函数或者内层代码
```
package main

func main()  {

    for i:=0;i<10 ;i++  {
    loop:     //不能跳到循环中-->内层代码
        println(i)
    }
    goto loop
}
```

- 编译执行下面代码会出现什么?
```go
package main
import "fmt"

func main()  {
    type MyInt1 int //definition，是需要强制类型转换的
    type MyInt2 = int  //这是alias，可以直接赋值的
    var i int =9
    var i1 MyInt1 = i //这里报错，需要强制类型转换，var i1 MyInt1=MyInt1(i)
    var i2 MyInt2 = i
    fmt.Println(i1,i2)
}
```

- 编译执行下面代码会出现什么?（新语法）

```
package main
import "fmt"

type User struct {
}
type MyUser1 User
type MyUser2 = User
func (i MyUser1) m1(){
    fmt.Println("MyUser1.m1")
}
func (i User) m2(){
    fmt.Println("User.m2")
}

func main() {
    var i1 MyUser1
    var i2 MyUser2
    i1.m1()  //MyUser1.m1
    i2.m2()  //User.m2,MyUser2和User是一个东西
} 
```

- 编译执行下面代码会出现什么?

```
package main

import "fmt"

type T1 struct {
}
func (t T1) m1(){
    fmt.Println("T1.m1")
}
type T2 = T1
type MyStruct struct {
    T1 //T1和T2是一个东西，这里重复了
    T2
}
func main() {
    my:=MyStruct{}
    //my.m1() //会报错ambiguous selector my.m1,但是只哟啊不使用T1和T2中的东西，就不会报错
    my.T1.m1() //可以通过
}
```
结果不限于方法，字段也也一样；也不限于type alias，type defintion也是一样的，只要有重复的方法、字段，就会有这种提示，因为不知道该选择哪个
type alias的定义，本质上是一样的类型，只是起了一个别名，源类型怎么用，别名类型也怎么用，保留源类型的所有方法、字段等。

- 编译执行下面代码会出现什么?
```
package main
import (
    "errors"
    "fmt"
)
var ErrDidNotWork = errors.New("did not work")
func DoTheThing(reallyDoIt bool) (err error) {
    if reallyDoIt {
        result, err := tryTheThing() //内部变量
        //result, err = tryTheThing() //改成这样就好
        if err != nil || result != "it worked" {
            err = ErrDidNotWork
        }
    }
    //外层变量，不是同一个
    return err //这个err是空的没有初始化，error类型是个内建类型的interafce
}

func tryTheThing() (string,error)  {
    return "",ErrDidNotWork
}

func main() {
    fmt.Println(DoTheThing(true))
    fmt.Println(DoTheThing(false))
}
```

```go
// The error built-in interface type is the conventional interface for
// representing an error condition, with the nil value representing no error.
type error interface {
	Error() string
}

```


- 编译执行下面代码会出现什么?闭包延迟求值
```go
package main
func test() []func()  {
    var funs []func()
    for i:=0;i<2 ;i++  {
        funs = append(funs, func() { //想不一样，就改成参数传入的
            println(&i,i) //闭包，公用同一个变量，在闭包执行时，这个变量是多少就是多少，
            //这里只是存储，所以最后都是2
        })
    }
    return funs
}

func main(){
    funs:=test()
    for _,f:=range funs{//f是值,这里没问题
        f() //输出相同地址，相同变量
    }
}
```

- 编译执行下面代码会出现什么?闭包引用相同变量
```go
package main

func test(x int) (func(),func())  {
    return func() {
        println(x)  //还是闭包，引用了同一个变量，函数使用时这个变量是多少就是多少
        x+=10
    }, func() {
        println(x) //同一个变量，堆上的，同一个内存
    }
}

func main()  {
    a,b:=test(100)
    a() //100
    b() //110
}
```



- 编译执行下面代码会出现什么?

```go
package main

import (
    "fmt"
    "reflect"
)

func main()  {
    defer func() {
       if err:=recover();err!=nil{  //panic1-->panic2-->这时只能捕捉到最近的，所以是defer panic
           fmt.Println(err)  
       }else {
           fmt.Println("fatal")
       }
    }()

    defer func() {
        panic("defer panic")
    }()
    panic("panic")
}
```
```go
//捕捉测试，用反射测试
func main()  {
    defer func() {
        if err:=recover();err!=nil{
            fmt.Println("++++")
            f:=err.(func()string)
            fmt.Println(err,f(),reflect.TypeOf(err).Kind().String())
            //函数地址，函数调用结果，类型为func
        }else {
            fmt.Println("fatal")
        }
    }()

    defer func() {
        panic(func() string {
            return  "defer panic"
        })
    }()
    panic("panic")
}

```

```go
package main

import (
	"fmt"
)

func main() {
	defer func() {
		if err := recover(); err != nil {
			fmt.Println(err)
		} else {
			fmt.Println("fatal")
        }
        //就是panic链，或者说是栈
		if err := recover(); err != nil {
			fmt.Println(err)
		} else {
			fmt.Println("fatal")
		}

	}()

	defer func() {
		panic("defer panic")
	}()
	panic("panic")
}
/*
defer panic
fatal*/
```

---
编程，算法

- 在utf8字符串判断是否包含指定字符串，并返回下标。 “北京天安门最美丽” , “天安门” 结果：2

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	fmt.Println(Utf8Index("北京天安门最美丽", "天安门"))
	fmt.Println(strings.Index("北京天安门最美丽", "男"))
	fmt.Println(strings.Index("", "男"))
	fmt.Println(Utf8Index("12ws北京天安门最美丽", "天安门"))
}

func Utf8Index(str, substr string) int {
	//Index returns the index of the first instance of substr in s, or -1 if substr is not present in s.
	asciiPos := strings.Index(str, substr)
	if asciiPos == -1 || asciiPos == 0 {
		return asciiPos
	}
	//接下来是咋回事？
	//主要是size问题，byte,和rune大小长度不一样，所以出来的位置也不一样
	pos := 0
	totalSize := 0
	reader := strings.NewReader(str)
	for _, size, err := reader.ReadRune(); err == nil; _, size, err = reader.ReadRune() {
		totalSize += size
		pos++
		// 匹配到
		if totalSize == asciiPos {
			return pos
		}
	}
	return pos
}
```

- 实现一个单例,就是只能保证一个实例，Go中可以把类型改为小写不可导出+创建对象方法大写，然后通过锁实现仅一个实例

主要是考虑并发产生问题,实例化只能执行一次，所以是个临界区，要加锁

```go
package main

import "sync"
import "fmt"

// 实现一个单例

type singleton struct{ v int }

var ins *singleton
var mu sync.Mutex

//懒汉加锁:虽然解决并发的问题，但每次加锁是要付出代价的
func GetIns() *singleton {
	mu.Lock()
	defer mu.Unlock()

	if ins == nil {
		ins = &singleton{10}
	}
	return ins
}

//双重锁:避免了每次加锁，提高代码效率
func GetIns1() *singleton {
	if ins == nil {
		mu.Lock()
		defer mu.Unlock()
		if ins == nil {
			ins = &singleton{11}
		}
	}
	return ins
}

//sync.Once实现
var once sync.Once

func GetIns2() *singleton {
	once.Do(func() {
		ins = &singleton{12}
	})
	return ins
}
func main() {
	a := GetIns() //10
	fmt.Println(a.v)
	a = GetIns1() //10
	fmt.Println(a.v)

	a = GetIns2() //12
	a.v = 1222
	fmt.Println(a.v) //1222

	a = GetIns2() //1222
	fmt.Println(a.v)

}
```

- 执行下面的代码发生什么？

关闭chan后，可读，不可写，可读是可以读到关闭状态（即not ok)
```go
package main

import (
	"fmt"
	"time"
)
func main() {
	ch := make(chan int, 1000)
	go func() {
		for i := 0; i < 10; i++ {
			ch <- i
		}
	}()
	go func() {
		for {
			a, ok := <-ch
			if !ok {
				fmt.Println("close")
				return
			}
			fmt.Println("a: ", a)
		}
	}()
	close(ch)//总共三个协程，这里快，先关闭chan,第一个写成还在往这里边写，所以异常
	fmt.Println("ok")
	time.Sleep(time.Second * 100)
}

```

- 执行下面的代码发生什么？
```go
package main
import "fmt"

type ConfigOne struct {
	Daemon string
}

func (c *ConfigOne) String() string {
	return fmt.Sprintf("print: %v", c)//%v会使用String()的值，所以这里会导致无限递归
}

func main() {
	c := &ConfigOne{}
	c.String()
}
```
- 编程题

反转整数 反转一个整数，例如：

例子1: x = 123, return 321
例子2: x = -123, return -321

输入的整数要求是一个 32bit 有符号数，如果反转后溢出，则输出 0

```go
package main

import "fmt"
import "math"

//-2147483648
//2147483647

func reverse(v int) int {
	max10:= math.MaxInt32 / 10
	rv := 0
	for v/10 != 0 {
		rv = rv*10 + (v % 10)
		v /= 10
    }
    //和214748364比较
	if rv > max10 || rv < 0-max10 || (rv == max10 && v > 7) || (rv <= 0-max10 && v < -8) {
		return 0
	} else {
		return rv*10 + v
	}
}
func main() {
	fmt.Println(reverse(-123))
	fmt.Println(reverse(1463847412))
	fmt.Println(reverse(7463847412))
	fmt.Println(reverse(7463847413))
	fmt.Println(reverse(8463847412))
	fmt.Println(reverse(-8463847412))
	fmt.Println(reverse(-8463847413))
	fmt.Println(reverse(-9463847412))
}
```


- 编程题

合并重叠区间 给定一组 区间，合并所有重叠的 区间。

例如： 给定：[1,3],[2,6],[8,10],[15,18] 返回：[1,6],[8,10],[15,18]

```go
```

- 输出什么
```go
package main

import (
	"fmt"
)

func main() {
	fmt.Println(len("你好bj!"))//输出编码长度，看汉字占用多大空间
}
//utf-8汉字占用字节数3，utf-16汉字占用字节数4
//英文字母都是一个字节

```


- map,编译并运行如下代码会发生什么？

list["name"]不是一个普通的指针值，map的value本身是不可寻址的，因为map中的值会在内存中移动，并且旧的指针在map改变时会变得无效。
map是可以自动扩容的，存储位置是易变的，所以go不允许直接对map的value写，但可以改为指针间接进行,var list map[string]*Test。

```go
package main
import "fmt"
type Test struct {
	Name string
}
var list map[string]Test
func main() {
	list = make(map[string]Test)
	name := Test{"xiaoming"}
	list["name"] = name
    //list["name"].Name = "Hello"  //cannot assign to struct field list["name"].Name in map
    //如果想这样，可以用指针，map[string]*Test
	fmt.Println(list["name"])
}
```

- ABCD中哪一行存在错误？

看到这道题需要第一时间想到的是Golang是强类型语言，interface是所有golang类型的父类，类似Java的Object。 函数中func f(x interface{})的interface{}可以支持传入golang的任何类型，包括指针，但是函数func g(x *interface{})只能接受*interface{}.


```go
type S struct {
}
func f(x interface{}) {
}
func g(x *interface{}) {
}
func main() {
	s := S{}
	p := &s
	f(s) //A
	g(s) //B  cannot use s (type S) as type *interface {} in argument to g: *interface {} is pointer to interface, not interface
	f(p) //C
	g(p) //D cannot use p (type *S) as type *interface {} in argument to g: *interface {} is pointer to interface, not interface
}
```



- 编译并运行如下代码会发生什么？
```go
package main
import (
	"sync"
	//"time"
)
const N = 10
var wg = &sync.WaitGroup{}
func main() {
	for i := 0; i < N; i++ {
		go func(i int) {
			wg.Add(1)
			println(i)
			defer wg.Done()
		}(i)
	}
	wg.Wait()//wait时各协程没有完全开始，所以可能部分没有输出，比较随机
}
```
这是使用WaitGroup经常犯下的错误！请各位同学多次运行就会发现输出都会不同甚至又出现报错的问题。 这是因为go执行太快了，导致wg.Add(1)还没有执行main函数就执行完毕了。 改为如下试试
```go

for i := 0; i < N; i++ {
        wg.Add(1)//外部加个控制
		go func(i int) {
			println(i)
			defer wg.Done()
		}(i)
	}
	wg.Wait()
```
---
算法

- 如何在一个给定有序数组中找两个和为某个定值的数，要求时间复杂度为O(n), 比如给｛1，2，4，5，8，11，15｝和15？


双指针，前提有序
```go
func Lookup(meta []int32, target int32) {
	left := 0
	right := len(meta) - 1
	for i := 0; i < len(meta); i++ {
		if meta[left]+meta[right] > target {
			right--
		} else if meta[left]+meta[right] < target {
			left++
		} else {
			fmt.Println(fmt.Sprintf("%d, %d", meta[left], meta[right]))
			return
		}
	}
	fmt.Println("未找到匹配数据")
}
```


- 给定一个数组代表股票每天的价格，请问只能买卖一次的情况下，最大化利润是多少？日期不重叠的情况下，可以买卖多次呢？输入：{100,80,120,130,70,60,100,125}，只能买一次：65(60买进，125卖出)；可以买卖多次：115(80买进，130卖出；60买进，125卖出)？



- 40亿个不重复的unsigned int的整数，没排过序的，然后再给一个数，如何快速判断这个数是否在那40亿个数当中？

1. 10亿约等于1G,40亿x4B约等于16GB,最多有2^32个数，每个数占用一位，则不到4GB就够用了，这样建立bitmap,O(n),判断O(1)
2. 将40亿个数分成1024份，按后10数划分，可以确定所在的文件，然后对这个文件中的数，再次按次10位数划分成1024个文件，同样可以确定出所在的文件，最后在1024个数中找到目标；这个方法的好处是可以提前判断出不存在，时间复杂度O(N),深度是O(logN)级别的
或者简单点，按位划分，首先最高位0，1分成两组，需要再次确定一组，然后划分次等位的0/1，最后确定数据。

但是，我认为这道题本身有问题，目标数不应该一个，而应该一组，否则O(n)就结束了，类似的应该是URL过滤问法。
题3本身就有问题，遍历就是最快的；题目应该加上一个条件，目标是一组数，而不应该是一个；它想问的类似于URL过滤这种吧。
题干已经脱离了实际，我想这种题最先来自于类似URL过滤这种，但后来慢慢演变到没有意义了。


---
设计题

- 秒杀系统要注意什么

秒杀页面->服务端控制器(网关)->服务层->数据库层

前端：
1. 页面静态化，尽量减少动态元素，通过CDN来抗峰值；
2. 禁止重复提交；
3 用户限流，在某段时间内，只允许请求一次，可以采取ip限流

服务端（网关）：限制uid访问频率，前端只是拦截了用于的请求，但是对于恶意攻击或者其他插件，需要服务端控制

服务层：
1. 采用消息队列缓存请求，数据库层订阅消息减库存，减库存成功请求秒杀成功，失败返回秒杀结束
2. 利用缓存应对读请求，比如12306等购票业务，大多数是查询请求，可以利用缓存分担数据库压力
3. 利用缓存应对写请求： 比如将数据库中的库存数据转移到redis缓存中，减库存操作在redis中进行，然后同步到数据库中

数据库层：数据库层是最脆弱的一层，一般在应用设计时在上游就把请求拦截掉，数据库只承担能力范围内的访问请求，所以上面通过在服务层引入队列和缓存，让底层数据库安全


- 设计一个类似微信红包架构系统要注意什么


南北分布：按订单纬度处理，南北系统分摊流量，降低系统风险

两地服务器，南部发送红包，流量进入南部处理，北部发红包，流量进入北部处理；

用户数据写多读少，全量存深圳，异步队列写入，查时这边跨城。

DB故障时流量转移：当一地发生故障，可以将红包业务调到另一边，实现容灾

拆红包入账异步化，信息流与资金流分离，拆红包时，db中记下凭证，然后异步队列请求入账，失败后通过补偿队列补偿，通过红包凭证与用户账户入账流水队长，保证最终一致性。

快慢分离,红包的入账是一个分布事务，属于慢接口，而拆红包凭证落地则速度快。实际应用中，用户只关心最佳手气，很少高薪抢到的零钱是否入账，因为展示用户的拆红包凭证即可。

发拆落地，其他操作双层cache：
1. cache住所有查询，两层chache，ckv做全量缓存，在数据访问层dao中增加本机内存cache做二级缓存，cache所有读请求，查询失败或不存在，降级内存cache;内存chache查询失败或记录不存在时降级db。
db本身不做读写分离
2. db写同步cache，容忍少量不一致

失败有异步队列补偿，定时的ckv与db备机对账，保证最终一致

DB双冲纬度分库表，冷热分离，红包热，其他数据放在冷数据库中（慢）

红包算法：

为保证每个人都可以领到红包，最多可以领取多少为上水位，每个人最少领取额为下水位，为保持均衡，可以调整上下水位。主要是红包也是一个一个的抢。


----
架构
- etcd满足了cap原理中哪两个特性？ cp，允许暂时不可用

- etcd v2和v3版本区别？

接口不一样，存储不一样，数据相互隔离；
v2是纯内存是心啊，未实时落地，v3是内存索引（b树）+后端数据库;
v2过期时间只能设置到每个key上，v3通过租期lease，可以为每个key设置相同的过期id；
v2 只能watch某个key及子节点，不能进行多个watch；v3支持某个固定key,也支持watch一个范围；
v2 体统http接口，v3提供grpc

- 选型etcd考量，和zk有那些区别

相同点：1. 应用场景：配置管理、服务注册发现，选主，调度，分布式嘟咧，分布式锁
不同点：
1. etcd 使用raft协议，zk使用paxos，前者易于理解，方便工程实现
2. etcd相对来说部署方便，zk比较复杂
3. etcd提供http+json,grpc接口，跨平台，zk需要使用客户端
4. etcd支持https，zk在这访民啊确实

- 服务治理包含哪些？
1. 服务注册、发现
2. 服务监控
3. 集群容错
4. 负载均衡

- 负载均衡分类
1. dns负载均衡（地理负载均衡）
2. 硬件lb
3. 软件lb（nginx,lvs)

并发量大于1000万，可以考虑配合使用

- nginx和lvs的区别：7层和4层

