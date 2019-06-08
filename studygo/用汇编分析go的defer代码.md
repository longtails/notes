### 用汇编分析go的defer闭包处理

首先如下代码是我在网上看到的关于defer的代码，当时判断错了很多。

```go
package main

import _ "fmt"

func main() {
	a := DeferFunc1(1)
	b := DeferFunc2(1)
	c := DeferFunc3(1)
	println(a) //4
	println(b) //1
	println(c) //3
}
func DeferFunc1(i int) (t int) { //4
	t = i
	defer func() {
		t += 3
	}()
	return t
}
func DeferFunc2(i int) int { //1
	t := i
	defer func() {
		t += 3
	}()
	return t
}
func DeferFunc3(i int) (t int) { //3
	defer func() {
		t += i
	}()
	return 2
}
```

函数DeferFunc1(1)返回了4，DeferFunc2(1)返回了1，DeferFunc3(1)返回了3，三个函数都是在defer操作了返回值，所以就造成分析难度的提升，注意呀，defer/recover一般是用来关闭资源的，不要进行一些骚操作！   
不管怎么样，我们先来分析一下为什么，要想搞明白上述的问题，我们先要理解：
1. return x不是一个原子命令，return x分为了两步，第一步将返回值置为x，最后RET，使PC恢复到调用位置的下一个指令位置；
1. 返回值，在程序中是如何处理的，更深入点，就是在机器码或者汇编上是如何处理的。要知道在调用函数前，首先要处理参数和返回值，go语言的参数和返回值都是通过栈传递的，调用前，返回值入栈，参数N入栈,...,参数1入栈。所以return x，就是要将x传递到函数调用前的栈中；
3. defer是在返回前调用的，即在RET前。 

[引用：defer插入return x](https://tiancaiamao.gitbooks.io/go-internals/content/zh/03.4.html),defer的插入，就如下列的表示。
>返回值 = xxx  
调用defer函数  
空的return  


有了以上三点的认知，我们就能分析出三个函数为什么返回4、1、3了：
1. DeferFunc1调用前，在main函数的占中押入了变量t，第一步t=i,在return t指令中间加入了defer，即在RET前调用了defer,defer中对t+=3,这都是直接对main中栈存储t的位置直接修改的，故返回4；  
2. DeferFunc2,在其函数栈中申请了一个变量t初始为i，defer插入在return t中，即RET前，但defer的操作都是对变量t进行的，不像第一函数直接对main栈上的返回值操作，那函数二的返回值在哪里操作的呢，return t分为两步，第一步是设置返回值，函数二就是将局部变量t的值传递掉main栈中的DeferFunc2的返回值，但是这一步在defer前，所以后续defer对t的操作，也仅仅是操作了局部变量t,未影响返回值；    
3. DeferFunc3(1),defer插入return 2中，首先return对设置返回值为2,之后defer插入到RET前，defer中的t是main栈中的DeferFunc3的返回值，是直接操作返回值的，所以在RET时，返回值成为2+i,即3。



为了更好的理解go是如何处理参数和返回值的，绘制如下的栈空间，在X86中，栈空间是从高地址向低地址方向增长的，理解好参数、返回值的处理，对我们分析上述代码的汇编带有有很大帮助。我们要理解为什么返回值在前参数在后，试想，在函数调用处理完后，返回值放在什么地方合适，当然先放返回值，这样返回值之下的空间我们直接丢弃即可，不用再处理，要是返回值在参数后，那调用结束，sp恢复到哪呢，恢复到返回值位置，那多余的参数岂不没有用了，浪费栈空间。所以这样我们就可以理解为什么返回值在前，以及为什么返回值、参数在调用者栈上。
```
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
```

#### 汇编分析上述defer代码

生成汇编文件有两种方式，一种是对二进制文件反汇编，一种是对.go文件生成汇编文件。

方法一：使用```go tool objdump```
```bash
liudeMacBook-Pro:go liu$ go build defer_ret.go 
liudeMacBook-Pro:go liu$ go tool objdump defer_ret >test.S
liudeMacBook-Pro:go liu$ cat test.S |grep DeferFunc1 -n5
--
122853-  :-1			0x107ef7c		cc			INT $0x3				
122854-  :-1			0x107ef7d		cc			INT $0x3				
122855-  :-1			0x107ef7e		cc			INT $0x3				
122856-  :-1			0x107ef7f		cc			INT $0x3				
122857-
122858:TEXT main.DeferFunc1(SB) /Users/liu/work/test/go/defer_ret.go
122859-  defer_ret.go:13	0x107ef80		65488b0c2530000000	MOVQ GS:0x30, CX			
122860-  defer_ret.go:13	0x107ef89		483b6110		CMPQ 0x10(CX), SP			
122861-  defer_ret.go:13	0x107ef8d		7667			JBE 0x107eff6				
122862-  defer_ret.go:13	0x107ef8f		4883ec20		SUBQ $0x20, SP				
122863-  defer_ret.go:13	0x107ef93		48896c2418		MOVQ BP, 0x18(SP)			
--
```

方法二：使用```go tool compile -S ```
```bash
liudeMacBook-Pro:go liu$ go tool compile -S defer_ret.go >test.S
liudeMacBook-Pro:go liu$ cat test.S |grep DeferFunc1 -n5
10-	0x0021 00033 (defer_ret.go:5)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
11-	0x0021 00033 (defer_ret.go:5)	FUNCDATA	$3, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
12-	0x0021 00033 (defer_ret.go:6)	PCDATA	$2, $0
13-	0x0021 00033 (defer_ret.go:6)	PCDATA	$0, $0
14-	0x0021 00033 (defer_ret.go:6)	MOVQ	$1, (SP)
15:	0x0029 00041 (defer_ret.go:6)	CALL	"".DeferFunc1(SB)
16-	0x002e 00046 (defer_ret.go:6)	MOVQ	8(SP), AX
17-	0x0033 00051 (defer_ret.go:6)	MOVQ	AX, "".a+32(SP)
18-	0x0038 00056 (defer_ret.go:7)	MOVQ	$1, (SP)
19-	0x0040 00064 (defer_ret.go:7)	CALL	"".DeferFunc2(SB)
20-	0x0045 00069 (defer_ret.go:7)	MOVQ	8(SP), AX
--
```

这里使用方法生成汇编文件，接着我们分析汇编文件，汇编文件中各指令的功能都已经注释，就是对上述DeferFuncX(1)调用过程的汇编显示和分析。需要我们注意的是，defer的调用，defer分为两步：  
1. 调用runtime.deferproc,将defer fn中的fn添加到表中，启动延迟调用的作用，在deferproc调用前，我们需要处理好deferproc的两个参数，siz和fn,siz表示延迟调用函数fn所需要的参数的大小（bytes），所以，我们就会发现在下入的汇编代码中，有MOVQ $8 (SP)就是设置的参数1，参数2设置在8(SP)位置。   
```func deferproc(siz int32, fn *funcval) // arguments of fn follow fn```
2. 调用runtime.deferreturn,这是真正调用defer后的函数fn,操作结果设置在deferproc前为defer设置的参数、返回值栈中。之后函数便可恢复调用这的BP、SP，然后通过RET,修改PC回到调用函数的下一个位置。

**对于闭包，整个分析没有仔细分析，需要查阅相关资料和分析。另外还有个疑问，为什么DeferFunc1和DeferFunc2在deferproc前设置其参数1为8，而DeferFunc3设置为16?待确定。**
<font color=red>那是因为函数3的闭包使用了两个外部变量，分别是t和i,而前两个函数只只用了一个外部变量t</font>所以，我们从这可以看出闭包中外部变量对于闭包中的那个匿名函数来说，其实就是它的传入参数。

**汇编代码:**

```x86asm
"".main STEXT size=209 args=0x0 locals=0x30
	0x0000 00000 (defer_ret.go:5)	TEXT	"".main(SB), $48-0  ;48:main函数栈大小,主要是函数中的变量等，0是指main的参数大小
	0x0000 00000 (defer_ret.go:5)	MOVQ	(TLS), CX
	0x0009 00009 (defer_ret.go:5)	CMPQ	SP, 16(CX)
	0x000d 00013 (defer_ret.go:5)	JLS	199
	0x0013 00019 (defer_ret.go:5)	SUBQ	$48, SP             ;函数执行前，SP在函数栈底，在main的虚拟地址中是48,而栈大小为48,所以SP应为48-48=0
	0x0017 00023 (defer_ret.go:5)	MOVQ	BP, 40(SP)          ;BP记录在栈40位置,保存调用函数的BP
	0x001c 00028 (defer_ret.go:5)	LEAQ	40(SP), BP          ;并把当前函数的BP为栈的40位置地址
	0x0021 00033 (defer_ret.go:5)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0021 00033 (defer_ret.go:5)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0021 00033 (defer_ret.go:5)	FUNCDATA	$3, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0021 00033 (defer_ret.go:6)	PCDATA	$2, $0
	0x0021 00033 (defer_ret.go:6)	PCDATA	$0, $0
	0x0021 00033 (defer_ret.go:6)	MOVQ	$1, (SP)            ;参数放在栈的0位置上
	0x0029 00041 (defer_ret.go:6)	CALL	"".DeferFunc1(SB)
	0x002e 00046 (defer_ret.go:6)	MOVQ	8(SP), AX           ;栈的8位置是DeferFunc1的返回值
	0x0033 00051 (defer_ret.go:6)	MOVQ	AX, "".a+32(SP)     ;将调用结果赋值给a
	0x0038 00056 (defer_ret.go:7)	MOVQ	$1, (SP)            ;main函数中，接下去同理
	0x0040 00064 (defer_ret.go:7)	CALL	"".DeferFunc2(SB)
	0x0045 00069 (defer_ret.go:7)	MOVQ	8(SP), AX
	0x004a 00074 (defer_ret.go:7)	MOVQ	AX, "".b+24(SP)
	0x004f 00079 (defer_ret.go:8)	MOVQ	$1, (SP)
	0x0057 00087 (defer_ret.go:8)	CALL	"".DeferFunc3(SB)
	0x005c 00092 (defer_ret.go:8)	MOVQ	8(SP), AX
	0x0061 00097 (defer_ret.go:8)	MOVQ	AX, "".c+16(SP)
	0x0066 00102 (defer_ret.go:9)	CALL	runtime.printlock(SB)
	0x006b 00107 (defer_ret.go:9)	MOVQ	"".a+32(SP), AX
	0x0070 00112 (defer_ret.go:9)	MOVQ	AX, (SP)
	0x0074 00116 (defer_ret.go:9)	CALL	runtime.printint(SB)
	0x0079 00121 (defer_ret.go:9)	CALL	runtime.printnl(SB)
	0x007e 00126 (defer_ret.go:9)	CALL	runtime.printunlock(SB)
	0x0083 00131 (defer_ret.go:10)	CALL	runtime.printlock(SB)
	0x0088 00136 (defer_ret.go:10)	MOVQ	"".b+24(SP), AX
	0x008d 00141 (defer_ret.go:10)	MOVQ	AX, (SP)
	0x0091 00145 (defer_ret.go:10)	CALL	runtime.printint(SB)
	0x0096 00150 (defer_ret.go:10)	CALL	runtime.printnl(SB)
	0x009b 00155 (defer_ret.go:10)	CALL	runtime.printunlock(SB)
	0x00a0 00160 (defer_ret.go:11)	CALL	runtime.printlock(SB)
	0x00a5 00165 (defer_ret.go:11)	MOVQ	"".c+16(SP), AX
	0x00aa 00170 (defer_ret.go:11)	MOVQ	AX, (SP)
	0x00ae 00174 (defer_ret.go:11)	CALL	runtime.printint(SB)
	0x00b3 00179 (defer_ret.go:11)	CALL	runtime.printnl(SB)
	0x00b8 00184 (defer_ret.go:11)	CALL	runtime.printunlock(SB)
	0x00bd 00189 (defer_ret.go:12)	MOVQ	40(SP), BP
	0x00c2 00194 (defer_ret.go:12)	ADDQ	$48, SP
	0x00c6 00198 (defer_ret.go:12)	RET
	0x00c7 00199 (defer_ret.go:12)	NOP
	0x00c7 00199 (defer_ret.go:5)	PCDATA	$0, $-1
	0x00c7 00199 (defer_ret.go:5)	PCDATA	$2, $-1
	0x00c7 00199 (defer_ret.go:5)	CALL	runtime.morestack_noctxt(SB)
	0x00cc 00204 (defer_ret.go:5)	JMP	0
	0x0000 65 48 8b 0c 25 00 00 00 00 48 3b 61 10 0f 86 b4  eH..%....H;a....
	0x0010 00 00 00 48 83 ec 30 48 89 6c 24 28 48 8d 6c 24  ...H..0H.l$(H.l$
	0x0020 28 48 c7 04 24 01 00 00 00 e8 00 00 00 00 48 8b  (H..$.........H.
	0x0030 44 24 08 48 89 44 24 20 48 c7 04 24 01 00 00 00  D$.H.D$ H..$....
	0x0040 e8 00 00 00 00 48 8b 44 24 08 48 89 44 24 18 48  .....H.D$.H.D$.H
	0x0050 c7 04 24 01 00 00 00 e8 00 00 00 00 48 8b 44 24  ..$.........H.D$
	0x0060 08 48 89 44 24 10 e8 00 00 00 00 48 8b 44 24 20  .H.D$......H.D$ 
	0x0070 48 89 04 24 e8 00 00 00 00 e8 00 00 00 00 e8 00  H..$............
	0x0080 00 00 00 e8 00 00 00 00 48 8b 44 24 18 48 89 04  ........H.D$.H..
	0x0090 24 e8 00 00 00 00 e8 00 00 00 00 e8 00 00 00 00  $...............
	0x00a0 e8 00 00 00 00 48 8b 44 24 10 48 89 04 24 e8 00  .....H.D$.H..$..
	0x00b0 00 00 00 e8 00 00 00 00 e8 00 00 00 00 48 8b 6c  .............H.l
	0x00c0 24 28 48 83 c4 30 c3 e8 00 00 00 00 e9 2f ff ff  $(H..0......./..
	0x00d0 ff                                               .
	rel 5+4 t=16 TLS+0
	rel 42+4 t=8 "".DeferFunc1+0
	rel 65+4 t=8 "".DeferFunc2+0
	rel 88+4 t=8 "".DeferFunc3+0
	rel 103+4 t=8 runtime.printlock+0
	rel 117+4 t=8 runtime.printint+0
	rel 122+4 t=8 runtime.printnl+0
	rel 127+4 t=8 runtime.printunlock+0
	rel 132+4 t=8 runtime.printlock+0
	rel 146+4 t=8 runtime.printint+0
	rel 151+4 t=8 runtime.printnl+0
	rel 156+4 t=8 runtime.printunlock+0
	rel 161+4 t=8 runtime.printlock+0
	rel 175+4 t=8 runtime.printint+0
	rel 180+4 t=8 runtime.printnl+0
	rel 185+4 t=8 runtime.printunlock+0
	rel 200+4 t=8 runtime.morestack_noctxt+0
"".DeferFunc1 STEXT size=125 args=0x10 locals=0x20
	0x0000 00000 (defer_ret.go:13)	TEXT	"".DeferFunc1(SB), $32-16   ;函数栈大小32，参数大小16,很想搞清楚，给了几个参数是怎么区分的
	0x0000 00000 (defer_ret.go:13)	MOVQ	(TLS), CX
	0x0009 00009 (defer_ret.go:13)	CMPQ	SP, 16(CX)
	0x000d 00013 (defer_ret.go:13)	JLS	118
	0x000f 00015 (defer_ret.go:13)	SUBQ	$32, SP           ;开始SP应该在本函数的虚拟地址32位置，运行时应指到32-32=0的位置
	0x0013 00019 (defer_ret.go:13)	MOVQ	BP, 24(SP)        ;调用DeferFunc1的函数，这里即main函数的BP，保存在当前函数栈24(SP)下
	0x0018 00024 (defer_ret.go:13)	LEAQ	24(SP), BP        ;lea不解引用，即直接把24(sp)的地址复制到BP,而不是24(SP)的内容给BP,即BP指向24位置
	0x001d 00029 (defer_ret.go:13)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x001d 00029 (defer_ret.go:13)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x001d 00029 (defer_ret.go:13)	FUNCDATA	$3, gclocals·9fb7f0986f647f17cb53dda1484e0f7a(SB)
	0x001d 00029 (defer_ret.go:13)	PCDATA	$2, $0
	0x001d 00029 (defer_ret.go:13)	PCDATA	$0, $0
	0x001d 00029 (defer_ret.go:13)	MOVQ	$0, "".t+48(SP)   ;变量t在48位置，而本函数栈最高32,即t在该函数外，即是调用者的栈中
	0x0026 00038 (defer_ret.go:14)	MOVQ	"".i+40(SP), AX   ;参数i在40位置，同样在调用者栈中
	0x002b 00043 (defer_ret.go:14)	MOVQ	AX, "".t+48(SP)   ;将i复制到t中
	0x0030 00048 (defer_ret.go:17)	PCDATA	$2, $1
	0x0030 00048 (defer_ret.go:17)	LEAQ	"".t+48(SP), AX   ;48(sp)的地址复制到AX中，这里我们就认为是48了,这是虚拟地址
	0x0035 00053 (defer_ret.go:17)	PCDATA	$2, $0
	0x0035 00053 (defer_ret.go:17)	MOVQ	AX, 16(SP)        ;16(SP)记录的是t的地址
	0x003a 00058 (defer_ret.go:15)	MOVL	$8, (SP)          ;8复制到0(SP)上，这是什么意思？deferproc有两个参数，这里可能是其参数1,表示defer的函数f1需要8B大小的参数，即那个闭包参数t
	0x0041 00065 (defer_ret.go:15)	PCDATA	$2, $1
	0x0041 00065 (defer_ret.go:15)	LEAQ	"".DeferFunc1.func1·f(SB), AX ;将函数地址复制到AX中
	0x0048 00072 (defer_ret.go:15)	PCDATA	$2, $0
	0x0048 00072 (defer_ret.go:15)	MOVQ	AX, 8(SP)         ;函数DeferFunc1.func1放在栈的8位置上,因为没有参数，所以接下来我们没有看到处理参数部分
	0x004d 00077 (defer_ret.go:15)	CALL	runtime.deferproc(SB) ;调用deferproc,并不是执行defer而是将defer内容记录在表中
	0x0052 00082 (defer_ret.go:15)	TESTL	AX, AX            ;判断AX是否为0,然后选择分支
	0x0054 00084 (defer_ret.go:15)	JNE	102
	0x0056 00086 (defer_ret.go:18)	XCHGL	AX, AX            ;读屏障？啥的，我不知道，不懂
	0x0057 00087 (defer_ret.go:18)	CALL	runtime.deferreturn(SB) ;真正的调用defer,闭包中的t值会在这改变
	0x005c 00092 (defer_ret.go:18)	MOVQ	24(SP), BP        ;24(SP)记录的是DeferFunc1的调用者main的BP值，所以，这是要返回了
	0x0061 00097 (defer_ret.go:18)	ADDQ	$32, SP           ;SP=SP+32,回到调用DeferFunc1的位置
	0x0065 00101 (defer_ret.go:18)	RET
	0x0066 00102 (defer_ret.go:15)	XCHGL	AX, AX
	0x0067 00103 (defer_ret.go:15)	CALL	runtime.deferreturn(SB)
	0x006c 00108 (defer_ret.go:15)	MOVQ	24(SP), BP
	0x0071 00113 (defer_ret.go:15)	ADDQ	$32, SP
	0x0075 00117 (defer_ret.go:15)	RET                       ;return返回，PC跳到调用函数的下一条指令，defer在RET前，但返回值的赋值在defer之前
	0x0076 00118 (defer_ret.go:15)	NOP                       ;占位，没有什么意思
	0x0076 00118 (defer_ret.go:13)	PCDATA	$0, $-1
	0x0076 00118 (defer_ret.go:13)	PCDATA	$2, $-1
	0x0076 00118 (defer_ret.go:13)	CALL	runtime.morestack_noctxt(SB)  ;栈空间不够，申请大一点的栈
	0x007b 00123 (defer_ret.go:13)	JMP	0
	0x0000 65 48 8b 0c 25 00 00 00 00 48 3b 61 10 76 67 48  eH..%....H;a.vgH
	0x0010 83 ec 20 48 89 6c 24 18 48 8d 6c 24 18 48 c7 44  .. H.l$.H.l$.H.D
	0x0020 24 30 00 00 00 00 48 8b 44 24 28 48 89 44 24 30  $0....H.D$(H.D$0
	0x0030 48 8d 44 24 30 48 89 44 24 10 c7 04 24 08 00 00  H.D$0H.D$...$...
	0x0040 00 48 8d 05 00 00 00 00 48 89 44 24 08 e8 00 00  .H......H.D$....
	0x0050 00 00 85 c0 75 10 90 e8 00 00 00 00 48 8b 6c 24  ....u.......H.l$
	0x0060 18 48 83 c4 20 c3 90 e8 00 00 00 00 48 8b 6c 24  .H.. .......H.l$
	0x0070 18 48 83 c4 20 c3 e8 00 00 00 00 eb 83           .H.. ........
	rel 5+4 t=16 TLS+0
	rel 68+4 t=15 "".DeferFunc1.func1·f+0
	rel 78+4 t=8 runtime.deferproc+0
	rel 88+4 t=8 runtime.deferreturn+0
	rel 104+4 t=8 runtime.deferreturn+0
	rel 119+4 t=8 runtime.morestack_noctxt+0
"".DeferFunc2 STEXT size=138 args=0x10 locals=0x28
	0x0000 00000 (defer_ret.go:20)	TEXT	"".DeferFunc2(SB), $40-16   ;函数栈大小40，参数和返回值大小16
	0x0000 00000 (defer_ret.go:20)	MOVQ	(TLS), CX
	0x0009 00009 (defer_ret.go:20)	CMPQ	SP, 16(CX)
	0x000d 00013 (defer_ret.go:20)	JLS	128
	0x000f 00015 (defer_ret.go:20)	SUBQ	$40, SP         ;都是类似的操作,SP指向栈顶40-40=0
	0x0013 00019 (defer_ret.go:20)	MOVQ	BP, 32(SP)      ;栈32位置记录调用者的BP，这属于现场保护的内容
	0x0018 00024 (defer_ret.go:20)	LEAQ	32(SP), BP      ;BP指向该函数栈的32，即栈底
	0x001d 00029 (defer_ret.go:20)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x001d 00029 (defer_ret.go:20)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x001d 00029 (defer_ret.go:20)	FUNCDATA	$3, gclocals·9fb7f0986f647f17cb53dda1484e0f7a(SB)
	0x001d 00029 (defer_ret.go:20)	PCDATA	$2, $0
	0x001d 00029 (defer_ret.go:20)	PCDATA	$0, $0
	0x001d 00029 (defer_ret.go:20)	MOVQ	$0, "".~r1+56(SP) ;返回值存储位置，在调用者栈上
	0x0026 00038 (defer_ret.go:21)	MOVQ	"".i+48(SP), AX  ;将i赋值给t
	0x002b 00043 (defer_ret.go:21)	MOVQ	AX, "".t+24(SP)  ;t是在函数内新创建的变量，占用栈空间
	0x0030 00048 (defer_ret.go:24)	PCDATA	$2, $1
	0x0030 00048 (defer_ret.go:24)	LEAQ	"".t+24(SP), AX  ;虚地址24放到AX中,即是t的地址,在从AX复制到16（SP)中，接下来的闭包操作吧
	0x0035 00053 (defer_ret.go:24)	PCDATA	$2, $0
	0x0035 00053 (defer_ret.go:24)	MOVQ	AX, 16(SP)       ;t的地址放在16(SP)，需要经过AX，内存和内存无法直接操作
	0x003a 00058 (defer_ret.go:22)	MOVL	$8, (SP)         ;这是干啥的?闭包参数，将虚地址8放到0(SP)中,放栈顶?deferproc的参数1，使用的外部参数t
	0x0041 00065 (defer_ret.go:22)	PCDATA	$2, $1
	0x0041 00065 (defer_ret.go:22)	LEAQ	"".DeferFunc2.func1·f(SB), AX ;匿名函数地址经AX到8(SP)中
	0x0048 00072 (defer_ret.go:22)	PCDATA	$2, $0
	0x0048 00072 (defer_ret.go:22)	MOVQ	AX, 8(SP)        ;匿名函数地址放到8(SP)中，即是defer的参数
	0x004d 00077 (defer_ret.go:22)	CALL	runtime.deferproc(SB) ;deferproc调用，将defer记录到表中
	0x0052 00082 (defer_ret.go:22)	TESTL	AX, AX
	0x0054 00084 (defer_ret.go:22)	JNE	112
	0x0056 00086 (defer_ret.go:25)	MOVQ	"".t+24(SP), AX  ;对应25行，将变量t的值放到AX中
	0x005b 00091 (defer_ret.go:25)	MOVQ	AX, "".~r1+56(SP);然后将AX,放到返回值的位置，即调用栈上，注意之所以用到中间AX，是因为不支持内存间直接MOV
	0x0060 00096 (defer_ret.go:25)	XCHGL	AX, AX
	0x0061 00097 (defer_ret.go:25)	CALL	runtime.deferreturn(SB);defer调用插入在return t中，真正执行defer调用，修改了t值
	0x0066 00102 (defer_ret.go:25)	MOVQ	32(SP), BP       ;函数返回，恢复为调用者的BP
	0x006b 00107 (defer_ret.go:25)	ADDQ	$40, SP          ;SP恢复到，函数调用前的位置，即退栈
	0x006f 00111 (defer_ret.go:25)	RET
	0x0070 00112 (defer_ret.go:22)	XCHGL	AX, AX
	0x0071 00113 (defer_ret.go:22)	CALL	runtime.deferreturn(SB)
	0x0076 00118 (defer_ret.go:22)	MOVQ	32(SP), BP
	0x007b 00123 (defer_ret.go:22)	ADDQ	$40, SP
	0x007f 00127 (defer_ret.go:22)	RET
	0x0080 00128 (defer_ret.go:22)	NOP
	0x0080 00128 (defer_ret.go:20)	PCDATA	$0, $-1
	0x0080 00128 (defer_ret.go:20)	PCDATA	$2, $-1
	0x0080 00128 (defer_ret.go:20)	CALL	runtime.morestack_noctxt(SB)
	0x0085 00133 (defer_ret.go:20)	JMP	0
	0x0000 65 48 8b 0c 25 00 00 00 00 48 3b 61 10 76 71 48  eH..%....H;a.vqH
	0x0010 83 ec 28 48 89 6c 24 20 48 8d 6c 24 20 48 c7 44  ..(H.l$ H.l$ H.D
	0x0020 24 38 00 00 00 00 48 8b 44 24 30 48 89 44 24 18  $8....H.D$0H.D$.
	0x0030 48 8d 44 24 18 48 89 44 24 10 c7 04 24 08 00 00  H.D$.H.D$...$...
	0x0040 00 48 8d 05 00 00 00 00 48 89 44 24 08 e8 00 00  .H......H.D$....
	0x0050 00 00 85 c0 75 1a 48 8b 44 24 18 48 89 44 24 38  ....u.H.D$.H.D$8
	0x0060 90 e8 00 00 00 00 48 8b 6c 24 20 48 83 c4 28 c3  ......H.l$ H..(.
	0x0070 90 e8 00 00 00 00 48 8b 6c 24 20 48 83 c4 28 c3  ......H.l$ H..(.
	0x0080 e8 00 00 00 00 e9 76 ff ff ff                    ......v...
	rel 5+4 t=16 TLS+0
	rel 68+4 t=15 "".DeferFunc2.func1·f+0
	rel 78+4 t=8 runtime.deferproc+0
	rel 98+4 t=8 runtime.deferreturn+0
	rel 114+4 t=8 runtime.deferreturn+0
	rel 129+4 t=8 runtime.morestack_noctxt+0
"".DeferFunc3 STEXT size=137 args=0x10 locals=0x28
	0x0000 00000 (defer_ret.go:27)	TEXT	"".DeferFunc3(SB), $40-16  ;栈大小40，参数和返回值大小16
	0x0000 00000 (defer_ret.go:27)	MOVQ	(TLS), CX
	0x0009 00009 (defer_ret.go:27)	CMPQ	SP, 16(CX)
	0x000d 00013 (defer_ret.go:27)	JLS	127
	0x000f 00015 (defer_ret.go:27)	SUBQ	$40, SP
	0x0013 00019 (defer_ret.go:27)	MOVQ	BP, 32(SP)                 ;同上
	0x0018 00024 (defer_ret.go:27)	LEAQ	32(SP), BP
	0x001d 00029 (defer_ret.go:27)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x001d 00029 (defer_ret.go:27)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x001d 00029 (defer_ret.go:27)	FUNCDATA	$3, gclocals·9fb7f0986f647f17cb53dda1484e0f7a(SB)
	0x001d 00029 (defer_ret.go:27)	PCDATA	$2, $0
	0x001d 00029 (defer_ret.go:27)	PCDATA	$0, $0
	0x001d 00029 (defer_ret.go:27)	MOVQ	$0, "".t+56(SP)            ;返回值t,在调用者栈上,初始化为0
	0x0026 00038 (defer_ret.go:30)	PCDATA	$2, $1
	0x0026 00038 (defer_ret.go:30)	LEAQ	"".t+56(SP), AX            ;闭包用，AX中记录t的地址
	0x002b 00043 (defer_ret.go:30)	PCDATA	$2, $0
	0x002b 00043 (defer_ret.go:30)	MOVQ	AX, 16(SP)                 ;t记录到16(SP)中，
	0x0030 00048 (defer_ret.go:30)	MOVQ	"".i+48(SP), AX            ;i是参数，在调用者栈上
	0x0035 00053 (defer_ret.go:30)	MOVQ	AX, 24(SP)                 ;栈24位置记录i的值,这应该是现场保护
	0x003a 00058 (defer_ret.go:28)	MOVL	$16, (SP)                  ;闭包参数，这是干啥的？deferproc的参数1，之所以是16是因为使用了两个外部变量t和i
	0x0041 00065 (defer_ret.go:28)	PCDATA	$2, $1
	0x0041 00065 (defer_ret.go:28)	LEAQ	"".DeferFunc3.func1·f(SB), AX ;匿名函数地址记录到AX中
	0x0048 00072 (defer_ret.go:28)	PCDATA	$2, $0
	0x0048 00072 (defer_ret.go:28)	MOVQ	AX, 8(SP)                  ;匿名函数地址记录在8(SP)中,defer调用的参数
	0x004d 00077 (defer_ret.go:28)	CALL	runtime.deferproc(SB)      ;调用deferproc将defer记录在表中，并不执行defer
	0x0052 00082 (defer_ret.go:30)	TESTL	AX, AX
	0x0054 00084 (defer_ret.go:30)	JNE	111
	0x0056 00086 (defer_ret.go:31)	MOVQ	$2, "".t+56(SP)            ;将2复制到返回值上,这是return 2的代码
	0x005f 00095 (defer_ret.go:31)	XCHGL	AX, AX
	0x0060 00096 (defer_ret.go:31)	CALL	runtime.deferreturn(SB)    ;真正执行defer的内容,将i加到t上
	0x0065 00101 (defer_ret.go:31)	MOVQ	32(SP), BP                 ;函数返回,恢复现场
	0x006a 00106 (defer_ret.go:31)	ADDQ	$40, SP
	0x006e 00110 (defer_ret.go:31)	RET
	0x006f 00111 (defer_ret.go:28)	XCHGL	AX, AX
	0x0070 00112 (defer_ret.go:28)	CALL	runtime.deferreturn(SB)
	0x0075 00117 (defer_ret.go:30)	MOVQ	32(SP), BP
	0x007a 00122 (defer_ret.go:30)	ADDQ	$40, SP
	0x007e 00126 (defer_ret.go:30)	RET                                ;PC会到调用函数指令的下一个位置
	0x007f 00127 (defer_ret.go:30)	NOP
	0x007f 00127 (defer_ret.go:27)	PCDATA	$0, $-1
	0x007f 00127 (defer_ret.go:27)	PCDATA	$2, $-1
	0x007f 00127 (defer_ret.go:27)	CALL	runtime.morestack_noctxt(SB)
	0x0084 00132 (defer_ret.go:27)	JMP	0
	0x0000 65 48 8b 0c 25 00 00 00 00 48 3b 61 10 76 70 48  eH..%....H;a.vpH
	0x0010 83 ec 28 48 89 6c 24 20 48 8d 6c 24 20 48 c7 44  ..(H.l$ H.l$ H.D
	0x0020 24 38 00 00 00 00 48 8d 44 24 38 48 89 44 24 10  $8....H.D$8H.D$.
	0x0030 48 8b 44 24 30 48 89 44 24 18 c7 04 24 10 00 00  H.D$0H.D$...$...
	0x0040 00 48 8d 05 00 00 00 00 48 89 44 24 08 e8 00 00  .H......H.D$....
	0x0050 00 00 85 c0 75 19 48 c7 44 24 38 02 00 00 00 90  ....u.H.D$8.....
	0x0060 e8 00 00 00 00 48 8b 6c 24 20 48 83 c4 28 c3 90  .....H.l$ H..(..
	0x0070 e8 00 00 00 00 48 8b 6c 24 20 48 83 c4 28 c3 e8  .....H.l$ H..(..
	0x0080 00 00 00 00 e9 77 ff ff ff                       .....w...
	rel 5+4 t=16 TLS+0
	rel 68+4 t=15 "".DeferFunc3.func1·f+0
	rel 78+4 t=8 runtime.deferproc+0
	rel 97+4 t=8 runtime.deferreturn+0
	rel 113+4 t=8 runtime.deferreturn+0
	rel 128+4 t=8 runtime.morestack_noctxt+0
"".DeferFunc1.func1 STEXT nosplit size=10 args=0x8 locals=0x0  ;DeferFunc1中的defer位置，匿名函数定义
	0x0000 00000 (defer_ret.go:15)	TEXT	"".DeferFunc1.func1(SB), NOSPLIT, $0-8  
	0x0000 00000 (defer_ret.go:15)	FUNCDATA	$0, gclocals·1a65e721a2ccc325b382662e7ffee780(SB)
	0x0000 00000 (defer_ret.go:15)	FUNCDATA	$1, gclocals·69c1753bd5f81501d95132d08af04464(SB)
	0x0000 00000 (defer_ret.go:15)	FUNCDATA	$3, gclocals·9fb7f0986f647f17cb53dda1484e0f7a(SB)
	0x0000 00000 (defer_ret.go:16)	PCDATA	$2, $1
	0x0000 00000 (defer_ret.go:16)	PCDATA	$0, $1
	0x0000 00000 (defer_ret.go:16)	MOVQ	"".&t+8(SP), AX  ;闭包，对于func1来说，就是参数，变量t的地址记录在调用栈上，复制到AX
	0x0005 00005 (defer_ret.go:16)	PCDATA	$2, $0
	0x0005 00005 (defer_ret.go:16)	ADDQ	$3, (AX)         ;AX=3+(AX)
	0x0009 00009 (defer_ret.go:17)	RET                      ;返回操作，回到调用位置的下一个位置
	0x0000 48 8b 44 24 08 48 83 00 03 c3                    H.D$.H....
"".DeferFunc2.func1 STEXT nosplit size=10 args=0x8 locals=0x0
	0x0000 00000 (defer_ret.go:22)	TEXT	"".DeferFunc2.func1(SB), NOSPLIT, $0-8
	0x0000 00000 (defer_ret.go:22)	FUNCDATA	$0, gclocals·1a65e721a2ccc325b382662e7ffee780(SB)
	0x0000 00000 (defer_ret.go:22)	FUNCDATA	$1, gclocals·69c1753bd5f81501d95132d08af04464(SB)
	0x0000 00000 (defer_ret.go:22)	FUNCDATA	$3, gclocals·9fb7f0986f647f17cb53dda1484e0f7a(SB)
	0x0000 00000 (defer_ret.go:23)	PCDATA	$2, $1
	0x0000 00000 (defer_ret.go:23)	PCDATA	$0, $1
	0x0000 00000 (defer_ret.go:23)	MOVQ	"".&t+8(SP), AX  ;同上
	0x0005 00005 (defer_ret.go:23)	PCDATA	$2, $0
	0x0005 00005 (defer_ret.go:23)	ADDQ	$3, (AX)
	0x0009 00009 (defer_ret.go:24)	RET
	0x0000 48 8b 44 24 08 48 83 00 03 c3                    H.D$.H....
"".DeferFunc3.func1 STEXT nosplit size=17 args=0x10 locals=0x0
	0x0000 00000 (defer_ret.go:28)	TEXT	"".DeferFunc3.func1(SB), NOSPLIT, $0-16
	0x0000 00000 (defer_ret.go:28)	FUNCDATA	$0, gclocals·1a65e721a2ccc325b382662e7ffee780(SB)
	0x0000 00000 (defer_ret.go:28)	FUNCDATA	$1, gclocals·69c1753bd5f81501d95132d08af04464(SB)
	0x0000 00000 (defer_ret.go:28)	FUNCDATA	$3, gclocals·568470801006e5c0dc3947ea998fe279(SB)
	0x0000 00000 (defer_ret.go:29)	PCDATA	$2, $0
	0x0000 00000 (defer_ret.go:29)	PCDATA	$0, $0
	0x0000 00000 (defer_ret.go:29)	MOVQ	"".i+16(SP), AX ;变量i是DeferFunc3的参数，在栈的16位置上
	0x0005 00005 (defer_ret.go:29)	PCDATA	$2, $1
	0x0005 00005 (defer_ret.go:29)	PCDATA	$0, $1
	0x0005 00005 (defer_ret.go:29)	MOVQ	"".&t+8(SP), CX ;闭包，变量t是DeferFunc3的返回值的地址，在栈的8位置上,对于func1来说
	0x000a 00010 (defer_ret.go:29)	ADDQ	(CX), AX        ;实现t=t+i
	0x000d 00013 (defer_ret.go:29)	PCDATA	$2, $0
	0x000d 00013 (defer_ret.go:29)	MOVQ	AX, (CX)
	0x0010 00016 (defer_ret.go:30)	RET
	0x0000 48 8b 44 24 10 48 8b 4c 24 08 48 03 01 48 89 01  H.D$.H.L$.H..H..
	0x0010 c3                                               .
"".init STEXT size=92 args=0x0 locals=0x8                   ;init函数，尽管我们没有定义
	0x0000 00000 (<autogenerated>:1)	TEXT	"".init(SB), $8-0
	0x0000 00000 (<autogenerated>:1)	MOVQ	(TLS), CX
	0x0009 00009 (<autogenerated>:1)	CMPQ	SP, 16(CX)
	0x000d 00013 (<autogenerated>:1)	JLS	85
	0x000f 00015 (<autogenerated>:1)	SUBQ	$8, SP
	0x0013 00019 (<autogenerated>:1)	MOVQ	BP, (SP)
	0x0017 00023 (<autogenerated>:1)	LEAQ	(SP), BP
	0x001b 00027 (<autogenerated>:1)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x001b 00027 (<autogenerated>:1)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x001b 00027 (<autogenerated>:1)	FUNCDATA	$3, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x001b 00027 (<autogenerated>:1)	PCDATA	$2, $0
	0x001b 00027 (<autogenerated>:1)	PCDATA	$0, $0
	0x001b 00027 (<autogenerated>:1)	MOVBLZX	"".initdone·(SB), AX
	0x0022 00034 (<autogenerated>:1)	CMPB	AL, $1
	0x0025 00037 (<autogenerated>:1)	JLS	48
	0x0027 00039 (<autogenerated>:1)	PCDATA	$2, $-2
	0x0027 00039 (<autogenerated>:1)	PCDATA	$0, $-2
	0x0027 00039 (<autogenerated>:1)	MOVQ	(SP), BP
	0x002b 00043 (<autogenerated>:1)	ADDQ	$8, SP
	0x002f 00047 (<autogenerated>:1)	RET
	0x0030 00048 (<autogenerated>:1)	JNE	57
	0x0032 00050 (<autogenerated>:1)	PCDATA	$2, $0
	0x0032 00050 (<autogenerated>:1)	PCDATA	$0, $0
	0x0032 00050 (<autogenerated>:1)	CALL	runtime.throwinit(SB)
	0x0037 00055 (<autogenerated>:1)	UNDEF
	0x0039 00057 (<autogenerated>:1)	MOVB	$1, "".initdone·(SB)
	0x0040 00064 (<autogenerated>:1)	CALL	fmt.init(SB)
	0x0045 00069 (<autogenerated>:1)	MOVB	$2, "".initdone·(SB)
	0x004c 00076 (<autogenerated>:1)	MOVQ	(SP), BP
	0x0050 00080 (<autogenerated>:1)	ADDQ	$8, SP
	0x0054 00084 (<autogenerated>:1)	RET
	0x0055 00085 (<autogenerated>:1)	NOP
	0x0055 00085 (<autogenerated>:1)	PCDATA	$0, $-1
	0x0055 00085 (<autogenerated>:1)	PCDATA	$2, $-1
	0x0055 00085 (<autogenerated>:1)	CALL	runtime.morestack_noctxt(SB)
	0x005a 00090 (<autogenerated>:1)	JMP	0
	0x0000 65 48 8b 0c 25 00 00 00 00 48 3b 61 10 76 46 48  eH..%....H;a.vFH
	0x0010 83 ec 08 48 89 2c 24 48 8d 2c 24 0f b6 05 00 00  ...H.,$H.,$.....
	0x0020 00 00 80 f8 01 76 09 48 8b 2c 24 48 83 c4 08 c3  .....v.H.,$H....
	0x0030 75 07 e8 00 00 00 00 0f 0b c6 05 00 00 00 00 01  u...............
	0x0040 e8 00 00 00 00 c6 05 00 00 00 00 02 48 8b 2c 24  ............H.,$
	0x0050 48 83 c4 08 c3 e8 00 00 00 00 eb a4              H...........
	rel 5+4 t=16 TLS+0
	rel 30+4 t=15 "".initdone·+0
	rel 51+4 t=8 runtime.throwinit+0
	rel 59+4 t=15 "".initdone·+-1
	rel 65+4 t=8 fmt.init+0
	rel 71+4 t=15 "".initdone·+-1
	rel 86+4 t=8 runtime.morestack_noctxt+0
go.loc."".main SDWARFLOC size=213
	0x0000 ff ff ff ff ff ff ff ff 00 00 00 00 00 00 00 00  ................
	0x0010 33 00 00 00 00 00 00 00 45 00 00 00 00 00 00 00  3.......E.......
	0x0020 01 00 50 45 00 00 00 00 00 00 00 d1 00 00 00 00  ..PE............
	0x0030 00 00 00 02 00 91 68 00 00 00 00 00 00 00 00 00  ......h.........
	0x0040 00 00 00 00 00 00 00 ff ff ff ff ff ff ff ff 00  ................
	0x0050 00 00 00 00 00 00 00 4a 00 00 00 00 00 00 00 5c  .......J.......\
	0x0060 00 00 00 00 00 00 00 01 00 50 5c 00 00 00 00 00  .........P\.....
	0x0070 00 00 d1 00 00 00 00 00 00 00 02 00 91 60 00 00  .............`..
	0x0080 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff ff  ................
	0x0090 ff ff ff ff ff ff 00 00 00 00 00 00 00 00 61 00  ..............a.
	0x00a0 00 00 00 00 00 00 6b 00 00 00 00 00 00 00 01 00  ......k.........
	0x00b0 50 6b 00 00 00 00 00 00 00 d1 00 00 00 00 00 00  Pk..............
	0x00c0 00 02 00 91 58 00 00 00 00 00 00 00 00 00 00 00  ....X...........
	0x00d0 00 00 00 00 00                                   .....
	rel 8+8 t=1 "".main+0
	rel 79+8 t=1 "".main+0
	rel 150+8 t=1 "".main+0
go.info."".main SDWARFINFO size=69
	0x0000 02 22 22 2e 6d 61 69 6e 00 00 00 00 00 00 00 00  ."".main........
	0x0010 00 00 00 00 00 00 00 00 00 01 9c 00 00 00 00 01  ................
	0x0020 0a 61 00 06 00 00 00 00 00 00 00 00 0a 62 00 07  .a...........b..
	0x0030 00 00 00 00 00 00 00 00 0a 63 00 08 00 00 00 00  .........c......
	0x0040 00 00 00 00 00                                   .....
	rel 9+8 t=1 "".main+0
	rel 17+8 t=1 "".main+209
	rel 27+4 t=29 gofile../Users/liu/work/test/go/defer_ret.go+0
	rel 36+4 t=28 go.info.int+0
	rel 40+4 t=28 go.loc."".main+0
	rel 48+4 t=28 go.info.int+0
	rel 52+4 t=28 go.loc."".main+71
	rel 60+4 t=28 go.info.int+0
	rel 64+4 t=28 go.loc."".main+142
go.range."".main SDWARFRANGE size=0
go.isstmt."".main SDWARFMISC size=0
	0x0000 04 13 04 0e 03 08 01 0f 02 08 01 0f 02 08 01 0f  ................
	0x0010 02 05 01 18 02 05 01 18 02 05 01 18 02 14 00     ...............
go.loc."".DeferFunc1 SDWARFLOC size=52
	0x0000 ff ff ff ff ff ff ff ff 00 00 00 00 00 00 00 00  ................
	0x0010 26 00 00 00 00 00 00 00 7d 00 00 00 00 00 00 00  &.......}.......
	0x0020 02 00 91 08 00 00 00 00 00 00 00 00 00 00 00 00  ................
	0x0030 00 00 00 00                                      ....
	rel 8+8 t=1 "".DeferFunc1+0
go.info."".DeferFunc1 SDWARFINFO size=62
	0x0000 02 22 22 2e 44 65 66 65 72 46 75 6e 63 31 00 00  ."".DeferFunc1..
	0x0010 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01  ................
	0x0020 9c 00 00 00 00 01 0e 69 00 00 0d 00 00 00 00 00  .......i........
	0x0030 0f 74 00 01 0d 00 00 00 00 00 00 00 00 00        .t............
	rel 15+8 t=1 "".DeferFunc1+0
	rel 23+8 t=1 "".DeferFunc1+125
	rel 33+4 t=29 gofile../Users/liu/work/test/go/defer_ret.go+0
	rel 43+4 t=28 go.info.int+0
	rel 53+4 t=28 go.info.int+0
	rel 57+4 t=28 go.loc."".DeferFunc1+0
go.range."".DeferFunc1 SDWARFRANGE size=0
go.isstmt."".DeferFunc1 SDWARFMISC size=0
	0x0000 04 0f 04 0e 03 0e 01 05 02 05 01 05 02 07 01 11  ................
	0x0010 02 02 01 02 02 06 01 10 02 11 00                 ...........
go.loc."".DeferFunc2 SDWARFLOC size=52
	0x0000 ff ff ff ff ff ff ff ff 00 00 00 00 00 00 00 00  ................
	0x0010 2b 00 00 00 00 00 00 00 8a 00 00 00 00 00 00 00  +...............
	0x0020 02 00 91 68 00 00 00 00 00 00 00 00 00 00 00 00  ...h............
	0x0030 00 00 00 00                                      ....
	rel 8+8 t=1 "".DeferFunc2+0
go.info."".DeferFunc2 SDWARFINFO size=73
	0x0000 02 22 22 2e 44 65 66 65 72 46 75 6e 63 32 00 00  ."".DeferFunc2..
	0x0010 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01  ................
	0x0020 9c 00 00 00 00 01 0e 69 00 00 14 00 00 00 00 00  .......i........
	0x0030 0a 74 00 15 00 00 00 00 00 00 00 00 0e 7e 72 31  .t...........~r1
	0x0040 00 01 14 00 00 00 00 00 00                       .........
	rel 15+8 t=1 "".DeferFunc2+0
	rel 23+8 t=1 "".DeferFunc2+138
	rel 33+4 t=29 gofile../Users/liu/work/test/go/defer_ret.go+0
	rel 43+4 t=28 go.info.int+0
	rel 52+4 t=28 go.info.int+0
	rel 56+4 t=28 go.loc."".DeferFunc2+0
	rel 67+4 t=28 go.info.int+0
go.range."".DeferFunc2 SDWARFRANGE size=0
go.isstmt."".DeferFunc2 SDWARFMISC size=0
	0x0000 04 0f 04 0e 03 0e 01 05 02 05 01 05 02 07 01 11  ................
	0x0010 02 02 01 02 02 05 01 1b 02 14 00                 ...........
go.loc."".DeferFunc3 SDWARFLOC size=52
	0x0000 ff ff ff ff ff ff ff ff 00 00 00 00 00 00 00 00  ................
	0x0010 26 00 00 00 00 00 00 00 89 00 00 00 00 00 00 00  &...............
	0x0020 02 00 91 08 00 00 00 00 00 00 00 00 00 00 00 00  ................
	0x0030 00 00 00 00                                      ....
	rel 8+8 t=1 "".DeferFunc3+0
go.info."".DeferFunc3 SDWARFINFO size=62
	0x0000 02 22 22 2e 44 65 66 65 72 46 75 6e 63 33 00 00  ."".DeferFunc3..
	0x0010 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01  ................
	0x0020 9c 00 00 00 00 01 0e 69 00 00 1b 00 00 00 00 00  .......i........
	0x0030 0f 74 00 01 1b 00 00 00 00 00 00 00 00 00        .t............
	rel 15+8 t=1 "".DeferFunc3+0
	rel 23+8 t=1 "".DeferFunc3+137
	rel 33+4 t=29 gofile../Users/liu/work/test/go/defer_ret.go+0
	rel 43+4 t=28 go.info.int+0
	rel 53+4 t=28 go.info.int+0
	rel 57+4 t=28 go.loc."".DeferFunc3+0
go.range."".DeferFunc3 SDWARFRANGE size=0
go.isstmt."".DeferFunc3 SDWARFMISC size=0
	0x0000 04 0f 04 0e 03 0e 01 0f 02 07 01 11 02 02 01 02  ................
	0x0010 02 09 01 10 02 01 01 05 02 14 00                 ...........
go.loc."".DeferFunc1.func1 SDWARFLOC size=0
go.info."".DeferFunc1.func1 SDWARFINFO size=56
	0x0000 02 22 22 2e 44 65 66 65 72 46 75 6e 63 31 2e 66  ."".DeferFunc1.f
	0x0010 75 6e 63 31 00 00 00 00 00 00 00 00 00 00 00 00  unc1............
	0x0020 00 00 00 00 00 01 9c 00 00 00 00 01 0e 26 74 00  .............&t.
	0x0030 00 0f 00 00 00 00 00 00                          ........
	rel 21+8 t=1 "".DeferFunc1.func1+0
	rel 29+8 t=1 "".DeferFunc1.func1+10
	rel 39+4 t=29 gofile../Users/liu/work/test/go/defer_ret.go+0
	rel 50+4 t=28 go.info.*int+0
go.range."".DeferFunc1.func1 SDWARFRANGE size=0
go.isstmt."".DeferFunc1.func1 SDWARFMISC size=0
	0x0000 04 05 01 04 02 01 00                             .......
go.loc."".DeferFunc2.func1 SDWARFLOC size=0
go.info."".DeferFunc2.func1 SDWARFINFO size=56
	0x0000 02 22 22 2e 44 65 66 65 72 46 75 6e 63 32 2e 66  ."".DeferFunc2.f
	0x0010 75 6e 63 31 00 00 00 00 00 00 00 00 00 00 00 00  unc1............
	0x0020 00 00 00 00 00 01 9c 00 00 00 00 01 0e 26 74 00  .............&t.
	0x0030 00 16 00 00 00 00 00 00                          ........
	rel 21+8 t=1 "".DeferFunc2.func1+0
	rel 29+8 t=1 "".DeferFunc2.func1+10
	rel 39+4 t=29 gofile../Users/liu/work/test/go/defer_ret.go+0
	rel 50+4 t=28 go.info.*int+0
go.range."".DeferFunc2.func1 SDWARFRANGE size=0
go.isstmt."".DeferFunc2.func1 SDWARFMISC size=0
	0x0000 04 05 01 04 02 01 00                             .......
go.loc."".DeferFunc3.func1 SDWARFLOC size=0
go.info."".DeferFunc3.func1 SDWARFINFO size=66
	0x0000 02 22 22 2e 44 65 66 65 72 46 75 6e 63 33 2e 66  ."".DeferFunc3.f
	0x0010 75 6e 63 31 00 00 00 00 00 00 00 00 00 00 00 00  unc1............
	0x0020 00 00 00 00 00 01 9c 00 00 00 00 01 0e 26 74 00  .............&t.
	0x0030 00 1c 00 00 00 00 00 0e 69 00 00 1d 00 00 00 00  ........i.......
	0x0040 00 00                                            ..
	rel 21+8 t=1 "".DeferFunc3.func1+0
	rel 29+8 t=1 "".DeferFunc3.func1+17
	rel 39+4 t=29 gofile../Users/liu/work/test/go/defer_ret.go+0
	rel 50+4 t=28 go.info.*int+0
	rel 60+4 t=28 go.info.int+0
go.range."".DeferFunc3.func1 SDWARFRANGE size=0
go.isstmt."".DeferFunc3.func1 SDWARFMISC size=0
	0x0000 04 05 01 0b 02 01 00                             .......
go.loc."".init SDWARFLOC size=0
go.info."".init SDWARFINFO size=33
	0x0000 02 22 22 2e 69 6e 69 74 00 00 00 00 00 00 00 00  ."".init........
	0x0010 00 00 00 00 00 00 00 00 00 01 9c 00 00 00 00 01  ................
	0x0020 00                                               .
	rel 9+8 t=1 "".init+0
	rel 17+8 t=1 "".init+92
	rel 27+4 t=29 gofile..<autogenerated>+0
go.range."".init SDWARFRANGE size=0
go.isstmt."".init SDWARFMISC size=0
	0x0000 04 0f 04 0c 03 07 01 05 02 09 01 07 02 09 01 15  ................
	0x0010 02 07 00                                         ...
"".initdone· SNOPTRBSS size=1
"".DeferFunc1.func1·f SRODATA dupok size=8
	0x0000 00 00 00 00 00 00 00 00                          ........
	rel 0+8 t=1 "".DeferFunc1.func1+0
"".DeferFunc2.func1·f SRODATA dupok size=8
	0x0000 00 00 00 00 00 00 00 00                          ........
	rel 0+8 t=1 "".DeferFunc2.func1+0
"".DeferFunc3.func1·f SRODATA dupok size=8
	0x0000 00 00 00 00 00 00 00 00                          ........
	rel 0+8 t=1 "".DeferFunc3.func1+0
type..importpath.fmt. SRODATA dupok size=6
	0x0000 00 00 03 66 6d 74                                ...fmt
gclocals·33cdeccccebe80329f1fdbee7f5874cb SRODATA dupok size=8
	0x0000 01 00 00 00 00 00 00 00                          ........
gclocals·9fb7f0986f647f17cb53dda1484e0f7a SRODATA dupok size=10
	0x0000 02 00 00 00 01 00 00 00 00 01                    ..........
gclocals·1a65e721a2ccc325b382662e7ffee780 SRODATA dupok size=10
	0x0000 02 00 00 00 01 00 00 00 01 00                    ..........
gclocals·69c1753bd5f81501d95132d08af04464 SRODATA dupok size=8
	0x0000 02 00 00 00 00 00 00 00                          ........
gclocals·568470801006e5c0dc3947ea998fe279 SRODATA dupok size=10
	0x0000 02 00 00 00 02 00 00 00 00 02                    ..........
```


**go runtime中deferproc和deferreturn的定义:** 

```go
type funcval struct {
	fn uintptr
	// variable-size, fn-specific data here
}

// Create a new deferred function fn with siz bytes of arguments.
// The compiler turns a defer statement into a call to this.
//go:nosplit
func deferproc(siz int32, fn *funcval) { // arguments of fn follow fn
	if getg().m.curg != getg() {
		// go code on the system stack can't defer
		throw("defer on system stack")
	}

	// the arguments of fn are in a perilous state. The stack map
	// for deferproc does not describe them. So we can't let garbage
	// collection or stack copying trigger until we've copied them out
	// to somewhere safe. The memmove below does that.
	// Until the copy completes, we can only call nosplit routines.
	sp := getcallersp()
	argp := uintptr(unsafe.Pointer(&fn)) + unsafe.Sizeof(fn)
	callerpc := getcallerpc()

	d := newdefer(siz)
	if d._panic != nil {
		throw("deferproc: d.panic != nil after newdefer")
	}
	d.fn = fn
	d.pc = callerpc
	d.sp = sp
	switch siz {
	case 0:
		// Do nothing.
	case sys.PtrSize:
		*(*uintptr)(deferArgs(d)) = *(*uintptr)(unsafe.Pointer(argp))
	default:
		memmove(deferArgs(d), unsafe.Pointer(argp), uintptr(siz))
	}

	// deferproc returns 0 normally.
	// a deferred func that stops a panic
	// makes the deferproc return 1.
	// the code the compiler generates always
	// checks the return value and jumps to the
	// end of the function if deferproc returns != 0.
	return0()
	// No code can go here - the C return register has
	// been set and must not be clobbered.
}

// Run a deferred function if there is one.
// The compiler inserts a call to this at the end of any
// function which calls defer.
// If there is a deferred function, this will call runtime·jmpdefer,
// which will jump to the deferred function such that it appears
// to have been called by the caller of deferreturn at the point
// just before deferreturn was called. The effect is that deferreturn
// is called again and again until there are no more deferred functions.
// Cannot split the stack because we reuse the caller's frame to
// call the deferred function.

// The single argument isn't actually used - it just has its address
// taken so it can be matched against pending defers.
//go:nosplit
func deferreturn(arg0 uintptr) {
	gp := getg()
	d := gp._defer
	if d == nil {
		return
	}
	sp := getcallersp()
	if d.sp != sp {
		return
	}

	// Moving arguments around.
	//
	// Everything called after this point must be recursively
	// nosplit because the garbage collector won't know the form
	// of the arguments until the jmpdefer can flip the PC over to
	// fn.
	switch d.siz {
	case 0:
		// Do nothing.
	case sys.PtrSize:
		*(*uintptr)(unsafe.Pointer(&arg0)) = *(*uintptr)(deferArgs(d))
	default:
		memmove(unsafe.Pointer(&arg0), deferArgs(d), uintptr(d.siz))
	}
	fn := d.fn
	d.fn = nil
	gp._defer = d.link
	freedefer(d)
	jmpdefer(fn, uintptr(unsafe.Pointer(&arg0)))
}
```



参考：
1. [defer参考](https://studygolang.com/articles/10730)  
2. [深入Go的底层，带你走近一群有追求的人](https://juejin.im/post/5c9192c95188252d5f0fd372)
3. [golang 汇编-plan9](https://lrita.github.io/2017/12/12/golang-asm/)
4. [Go 系列文章3 ：plan9 汇编入门,plan9 assembly 完全解析](http://xargin.com/plan9-assembly/)
5. [从汇编角度理解golang多值返回和闭包](http://luodw.cc/2016/09/04/golang03/)



---
接下来要做的：
1. go的调度分析
2. go的gc