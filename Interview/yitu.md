Java实现一个栈，要求栈的有以下四个操作，时间复杂度都是o(1)
1. pop
2. push
3. getMaxValue()
4. deleteMaxValue（）

```cpp
#include <iostream>
using namespace std;
int data[1024];
int max[1024];
int size=0;
int push(int v){
    data[size]=v;
    if(size==0){
        max[size]=0;//max记录最大值的下标
    }else{
        if(data[size]>data[max[size-1]]){
            max[size]=size;
        }else{
            max[size]=max[size-1];
        }
    }
    size++;      
}
void pop(){
    if(size>0){
        size--
    }
}
int getMaxValue(){
    if(size<0)return -1;//?
    return max[size];
}
void deleteMaxValue(){
    if(size<0)return;
    for(int i=max[size];i<size;i++){
        data[i]=data[i+1];
        if(max[size-1]>max[i+1])max[i]=max[size-1];//判断max[size]之前的是否最大   ？考虑最大值存指针；后边还需要更新吗？
    }
    size--;
}

int main() {
    push(1);
    push(2);
    push(5);
    push(4);
    cout<<getMaxValue()<<endl;
    deleteMaxValue();
    cout<<getMaxValue()<<endl;
    return 0;
}
```

fork之后子父进程之间的内存关系，是复制过来的吗？

c++线程的锁有哪些？多个线程访问一个变量，如何保证线程安全？

c++ map有哪几种？hash和红黑树，如何实现一个range查询，

c++ 多态介绍下，怎么使用

c++怎么实现父类对象调用子类对象的？虚函数列表


tcp三次握手、四次挥手

你用k8s做什么？

k8s中daemonSet和statefulSet，Stateful为什么比较复杂，增加一个机器，再启动一个stateful的应用，怎么处理？

实习的工作内容？你做过的什么任务？

线程间的内存是共享的吗？fork，子进程可以访问父进程的空间，这个空间是怎么创建的。



