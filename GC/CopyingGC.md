### GC复制算法

GC复制算法(Copying GC)是在1963年提出的一种算法，如果说简单点，就是只把某个空间里的活动对象复制到其他空间，把原空间里的素有对象都回收掉，这是一个很大胆的算法。这里，将两块空间分别称为From空间和To空间。

GC复制算法是利用From空间进行分配的，当From空间被沾满时，GC会将活动对象全部复制到To空间，当复制完成后，该算法会把From空间和To空间互换，GC也就结束了。注意，From空间和To空间大小必须一致，这是为了保证能把From空间中的所有活动对象都收纳到To空间中。

从From到To，GC通过如下的copying()函数完成，$free是知识分块开头的变量，然后复制从根引用的对西那个，copy()函数将最为参数的对象*r复制的同时，也将其子对象进行递归复制。复制结束后返回指针，这里返回的时指向*r所在的新的空间的对象，即该对象在To空间的地址。在GC结束时，原空间的对象会作为垃圾被回收，因此，由根只想原空间对象的指针也会被重写成指向返回值的新对象的指针。最后把From空间和To空间互换，GC就结束了。

```cpp
copying(){
    $free=$to_start
    for(r:$roots)
        *r=copy(*r)
    swap($from_start,$to_start)
}
copy(obj){
    if(obj.tag!=COPIED)
        copy_data($free,obj,obj.size)
        obj.tag=COPIED
        obj.forwarding=$free
        $free+=obj.size

        for(child:children(obj.forwarding))
            *child=copy(*child)
    return obj.forwarding
}
```
copy函数会先检查obj的复制是否已完成，在这里出现的obj.tag是一个域，表示obj的复制是否完成。如果obj.tag==COPIED表示obj的复制完成。如果未被复制，那函数会进行复制obj,返回指向新空间对象的指针，如果复制已经完成，则函数会返回新空间对象的地址。

GC复制算法的分配过程非常简单，见下new_obj函数。注意GC完成后只有一个分块的内存空间，在每次分配时，只要把所申请大小的内存空间从这个分块中分割出来给mutator就行，也就是说它不需要遍历空闲链表。注意HEAP_SIZE表示时把From空间和To空间加起来的大小，也就是说，From空间和To空间大小一样，都是HEAP_SIZE的一半。如果分块的大小不够，如果分块的大小不够，首先应分配足够大的分块，不然一旦分块大小不够，分配就会失败；如果分块足够大，那么程序就会把size大小的空间从这个分块中分割出来，交给mutator，同时，还得把$free移动size个长度。

```cpp
new_obj(size){
    if($free + size > $from_start + HEAP_SIZE/2)
        copying()
        if($free + size > $from_start + HEAP_SIZE/2)
            allocation_fail()
    obj = $free
    obj.size = size
    $free += size
    return obj
}
```

GC复制算法时比较简单，我们来看下其优点：
1. 优秀的吞吐量，GC复制算法只搜索并复制活动对象，所以它能在较短时间内完成GC。
2. 可实现高速分配，GC复制算法不使用空闲连标，因为分块时一个连续的内存空间，因此，调查分块的大小，只要这个分块大小不小于所申请的大小，那么移动$free指针就可以进行分配了。
3. 不会发生碎片化，基于算法性质，活动对象被集中安排在From空间的开对，这样会把对象重新集中，即是一种压缩行为。GC复制算法每次运行GC都会执行压缩。
4. 与缓存兼容，GC复制算法中有引用关系的对象都会被安排在堆里彼此较近的位置，这样读取未见较近的对象，缓存命中率会很高。
再来看下缺点：
1. 堆实用效率地下，GC复制算法把堆二等分，通常只能利用其中的一半来安排对象，即只有一半的堆能被实用，这是GC复制算法的一个重大缺点。
2. 不兼容保守式GC算法，保守式GC算法不会移动对象，这恰好和GC复制算法冲突。
3. 递归调用函数，复制某个对象时，要递归复制它的子对象，因此每次复制都要调用函数，会带来较大的额外负担，若递归深度很大，还有可能出现栈溢出的问题。

同样，GC复制算法也是一个基本算法，有很多针对它的改进算法，能够解决它的缺点，但这里不再介绍。