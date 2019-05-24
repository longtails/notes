### 打桩

桩函数是干嘛的怎么弄的呢？

什么是桩？
桩即桩代码，值得是
> Stub/Method Stub是指用来替代一部分功能的程序段。桩程序可以用来模拟已有程序的行为或者对将要开发的代码的一种临时替代。因此，打桩计数在程序移植、分布式计算、通用软件开发和测试中用处很大。

wiki给了一个如下的例子，ThermometerRead函数需要去读取硬件设备，而这个函数还没卡法完成，不能正常工作。这里就使用开发了一个桩函数ThermometerRead，只是简单的返回了一个数字，这样主程序就可以正常开发了。
```cpp
BEGIN
    Temperature = ThermometerRead(Outside)
    IF Temperature > 40 THEN
        PRINT "It's HOT!"
    END IF
END

//桩函数
BEGIN ThermometerRead(Source insideOrOutside)
    RETURN 28
END ThermometerRead
```

> 桩程序是一段不执行任何实际功能的程序，只对接受的参数进行声明并返回一个合法值，这个返回值通常只是一个对于调用者来讲可接受的值即可。桩通畅用在一个已有接口的临时替换上，实际的接口程序在未来再对桩函数进行替换。

---

另外在远程调用（RMI)中将客户辅助对象称之为Stub(桩)；将服务辅助对象称之为skeleton（骨架）
RMI的远程过程：客户对象一旦被调用，客户对象调用stub，stub调用网络远端的skeleton，而skeleton最终调用真正的服务对象。这样，在调用客户对象的时候，感觉上就是直接调用了真正的服务对象。


