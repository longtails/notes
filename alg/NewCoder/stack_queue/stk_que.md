### 队列和栈

基本性质：
1. 栈是先进后出的
2. 队列是先进先出的
3. 栈和队列在实现结构上可以有数组和脸表两种形式：  
    1. 数组结构实习那较容器
    2. 用链表结构复杂，因为牵扯很多指针操作

 栈和队列的基本操作：pop、top/peek、push、size，其时间复杂度都为O(1)。

 双端队列，在首尾都可以压入和弹出元素  
 优先级队列为根据元素的优先级值，决定元素的弹出顺序，优先级队列并不是线性结构而是堆结构   

 与栈和队列相关的还有深度优先遍历DFS和宽度优先遍历BFS。平时使用的递归函数实际上用到了函数系统栈，递归过程可以看作递归函数依次进入函数栈的处理过程，所以任何用递归函数实现的过程都可以用非递归的方式实现。


 #### 案例一

 实现一个特殊的栈，在实现栈的基本功能的基础上，再实现返回栈中最小元素的操作getmin。  
 要求：
 1. pop,push,getMin操作的时间复杂度都是O(1)
 2. 设计的栈类型可以使用现成的栈结构

方法：
1. 双栈  
2. MIN+差值入栈
```cpp
//空间和时间复杂度都是O(1)
#include<iostream>
#include<stack>
using namespace std;
stack<int> stk;
int MIN=0;
void push(int value) {
	if(stk.size()==0){
		MIN=value;
	}
	if(value-MIN<=0){//更新
		stk.push(value-MIN);
		MIN=value;
	}else{
		stk.push(value-MIN);
	}
}
void pop() {
	int t=stk.top();
	if(t<0){
		MIN=MIN-t;
	}
	stk.pop();
}
int top() {
	int t=stk.top();
	if(t<0){
		return MIN;
	}else{
		return stk.top()+MIN;
	}
}
int min() {
	return MIN;
}
int main(){
	push(10);push(2);push(1);push(11);push(7);
	pop();pop();pop();
	push(0);push(14);
	cout<<top()<<endl;
	cout<<min()<<endl;
	return 0;
}
```

 #### 案例二

 编写一个类，只能用两个栈结构实现队列，支持队列的基本操作(add、poll、peek)。 

 注意：   
 1. 如果stackpush要网stackpop中倒入数据，那么必须要把stackpush中的所有数据一次性倒完
 2. 如果stackpop中有数据，则不能发生倒数据的行为

```cpp
#include<iostream>
#include<vector>
#include<stack>
using namespace std;
stack<int>stk_push;
stack<int>stk_pop;
vector<int> twoStack(vector<int> ope, int n) {
	vector<int> p;
	for(int i=0;i<ope.size();i++){
		if(ope[i]>0){
			stk_push.push(ope[i]);
		}else{
			if(stk_pop.empty()){
					while(stk_push.empty()==false){
					stk_pop.push(stk_push.top());
					stk_push.pop();
				}
			}
			p.push_back(stk_pop.top());
			stk_pop.pop();
		}
	}
	return p;
}
int main(){
	int v[]={1,2,3,0,4,0};//output:1 2
	vector<int>ope;
	ope.assign(v,v+sizeof(v)/sizeof(int));
	vector<int>p=twoStack(ope,ope.size());
	for(int i=0;i<p.size();i++){
		cout<<ope[i]<<" ";
	}
	cout<<endl;
	return 0;
}
```

 #### 案例三

 实现一个栈的逆序，但是只能用递归函数和这个栈本身的操作来实现，而不能自己申请另外的数据结构

方法：
1. 实现获取并删除栈底元素Get方法
2. 递归调用Get方法，并在返回时push之前获取的栈底元素
 ```cpp
 #include<iostream>
#include<vector>
#include<stack>
using namespace std;
//获取并删除栈底元素
int get(stack<int>&stk){
	int b=0;
	if(stk.size()==1){
		b=stk.top();
		stk.pop();
		return b;
	}
	int p=stk.top();
	stk.pop();
	b=get(stk);
	stk.push(p);
	return b;
}
//再借助递归函数实现反转,因为随着Get栈底元素逐渐被删，随着函数的深入，获得数越接近栈顶
void reverse(stack<int>&stk){
	if(stk.empty()){
		return;
	}
	int p=get(stk);
	reverse(stk);
	stk.push(p);
}
vector<int> reverseStack(vector<int> A, int n) {
	vector<int>p;
	stack<int>stk;
	for(int i=n-1;i>=0;i--){
		stk.push(A[i]);
	}
	reverse(stk);
	while(stk.empty()==false){
		p.push_back(stk.top());
		stk.pop();
	}
	return p;
}
int main(){
	int v[]={4,3,2,1};
	vector<int> A;
	A.assign(v,v+sizeof(v)/sizeof(int));
	vector<int>B=reverseStack(A,A.size());

	for(int i=0;i<B.size();i++){
		cout<<B[i]<<" ";
	}
	cout<<endl;
	return 0;
}
 ```

#### 案例四

一个栈中元素类型为整型，现在想将该栈从顶到底按从大到小排序，只许申请一个栈，除此之外可以申请新的变量，但不能申请额外的数据结构。如何完成排序？

用双栈，备用栈放有序的部分，若要加入的元素不符合备用栈的顺序，则将备用栈中的元素弹出到原栈，在合适位置压入该元素，再把刚才的元素弹回备用栈。多次操作后，备用栈中元素有序。
```cpp
#include<iostream>
#include<vector>
#include<stack>
using namespace std;
vector<int> twoStacksSort(vector<int> numbers) {
	stack<int>stk1,stk2;
	for(int i=numbers.size()-1;i>=0;i--){
		stk1.push(numbers[i]);
	}
	int t1=0,t2=0;
	while(stk1.empty()==false){
		t1=stk1.top();
		stk1.pop();
		if(stk2.empty()){
			stk2.push(t1);
		}else{
			t2=stk2.top();
			if(t2<=t1){
				stk2.push(t1);
			}else{
				int c=0;
				while(stk2.empty()==false&&stk2.top()>t1){
					stk1.push(stk2.top());
					stk2.pop();c++;
				}
				stk2.push(t1);
				while(--c>=0){
					stk2.push(stk1.top());
					stk1.pop();
				}
			}
		}
	}
	vector<int>v;
	while(stk2.empty()==false){
		v.push_back(stk2.top());
		stk2.pop();
	}
	return v;
}
int main(){
	int v[]={1,2,3,4,5};
	vector<int> arr;
	arr.assign(v,v+sizeof(v)/sizeof(int));
	vector<int>b=twoStacksSort(arr);
	for(int i=0;i<b.size();i++){
		cout<<b[i]<<" ";
	}
	cout<<endl;
	return 0;
}
```


#### 案例五

有一个整型数组arr和一个大小为w的窗口从数组的最左边滑到最右边，窗口每次向右滑一个位置。返回一个长度为n-w+1的数组res，res[i]表示每一种窗口状态下的最大值。  
以数组为[4,3,5,4,3,3,6,7]，w=3为例。因为第一个窗口[4,3,5]的最大值为5，第二个窗口[3,5,4]的最大值为5，第三个窗口[5,4,3]的最大值为5，第四个窗口[4,3,3]的最大值为4，第五个窗口[3,3,6]的最大值为6，第六个窗口[3,6,7]的最大值为7，所以最终返回[5,5,5,4,6,7]。

普通解法的时间复杂带O(N*w),也就是每次对窗口遍历，选出最大值。但是本题的最优解可以做到时间复杂度O(N),用一个大小为w的队列记录当前位置w各元素在窗口前沿到该元素中的最大值，向右华东一个位置，则弹出队首元素，队尾元素和新加的元素比较，将大的数追加到队尾。  

方法：使用双端队列动态记录窗口下的最大值  
双端队列qmax={}，在双端队列存放着数组中的下标值，假设当前数为arr[i],放入规则如下：  

	1. 如果qmax为空，直接把下标i放入qmax中  
	2. 如果qmax不为空，取出当前qmax队尾存放的下标j。如果arr[j]>arr[i]，直接把下标i放进qmax的队尾。  
	3. 如果arr[j]<=arr[i],则一直从qmax的队尾弹出下标，知道某个下标在qmax中对应的值大于arr[i],把i放入qmax的队尾。   
	
弹出规则如下：  
如果qmax队头的下标等于i-w,弹出qmax当前队头下标。

```cpp
#include<iostream>
#include<vector>
#include<deque>
using namespace std;
//4,3,5,4,3,3,6,7   8 3
//5,5,5,4,6,7
vector<int> slide(vector<int> arr, int n, int w) {
	deque<int>qmax;
	vector<int> p;
	for(int i=0;i+w<=n;i++){
		for(int j=i;j<i+w;j++){
			if(qmax.empty()){
				qmax.push_back(i);
			}else{
				//更新窗口的最大值,采用窗口中靠右的较大值更新
				//这样是的窗口向右移动，qmax中的最大值仍是可用的
				while(qmax.empty()==false){
					int t=qmax[qmax.size()-1];
					if(arr[j]>=arr[t]){
						qmax.pop_back();
					}else{
						break;
					}
				}
				qmax.push_back(j);
			}
		}
		int t=qmax.front();
		p.push_back(arr[t]);
		//qmax中的值的下标要在窗口内
		if(t==i){
			qmax.pop_front();
		}
	}
	return p;
}
int main(){
	int v[]={4,3,5,4,3,3,6,7};
	int w=3;
	vector<int> arr;
	arr.assign(v,v+sizeof(v)/sizeof(int));
	vector<int>p=slide(arr,arr.size(),w);
	for(int i=0;i<p.size();i++){
		cout<<p[i]<<" ";
	}
	cout<<endl;
	return 0;
}
```

#### 案例六

给定一个没有重复元素的数组arr,写出生成这个数组的MaxTree的函数。要求如果数组长度为N,则时间复杂度为O(N)、额外空间复杂度为O(N)。MaxTree的概念如下：  
1. MaxTree是一颗二叉树，数组的每一个值对应一个二叉树节点  
2. 包括MaxTree树在内且在其中的每一棵子树上，值最大节点都是树的头。

分析：这跟大根堆的结构很相似，但不同的是堆是完全二叉树，而MaxTree不是完全二叉树。不就是不断找最大的数，然后划分称左右子树，一次递归下去。到底是左还是右，无法确定，但能确定子树的父亲。这样时间复杂度是O(N*logN)。

现有一建树方法，对于数组中的每个元素，其在树中的父亲为数组中它左边比它大的第一个数和右边比它大的第一个数中更小的一个。若两边都不存在比它大的数，那么它就是树根。请设计O(n)的算法实现这个方法。
```
[3 4 5 1 2]
左边第一个大的数：3->null,4->null,5->null,1->5,2->5;
右边第一个大的数：3->4,4->5,5->null,1->2,2->null;
       
	    5
	   / \
	  4   2
	 /     \
	3       1
```
证明：  
1. 该方法可以生成一棵树，而不是森林。数组中所有数都不同，较小的数一定会以一个较大的数作为父节点， 所以它们会有一个共同的父节点，这样肯定是一棵树，而不是多棵。
2. 生成的这一棵树是二叉树，而不是多叉树。只需证明任何一个数在单独一侧，孩子的数量都不超过一个。
```
....A.....K1.....K2
A>K1,且A>K2,
假设K1<K2,根据A>K2,有K1<K2<A,所以根据我们的方法，K1不可能以A为父节点。  
假设K2<K1,根据A>K1,有K2<K1<A，所以根据我们的方法，K2不可能以A为父节点。
总之，A在单独一侧不可能有超过一个孩子节点的情况。
```  

利用栈得到每个数左右两边第一个比它大的数。

```cpp
#include<iostream>
#include<stack>
#include<vector>
using namespace std;
//3 1 4 2
vector<int> buildMaxTree(vector<int> A, int n) {
	stack<int>stk;
	vector<int> p;
	p.assign(n,0);p[0]=-1;stk.push(0);
	//left
	for(int i=0;i<n;i++){
		int t=stk.top();
		if(A[t]>A[i]){
			p[i]=t;
			stk.push(i);
		}else{
			while(stk.empty()==false&&A[stk.top()]<=A[i])stk.pop();
			if(stk.empty()) p[i]=-1;
			else p[i]=stk.top();
			stk.push(i);
		}
	}
	while(!stk.empty())stk.pop();
	stk.push(n-1);
	//right
	for(int i=n-2;i>=0;i--){
		int t=stk.top();
		if(A[t]>A[i]){
			if(p[i]==-1||A[p[i]]>A[t])p[i]=t;
			stk.push(i);
		}else{
			//找到符合的
			while(stk.empty()==false&&A[stk.top()]<=A[i])stk.pop();
			if((stk.empty()==false)&&(A[stk.top()]<A[p[i]]||p[i]==-1))p[i]=stk.top();
			stk.push(i);
		}
	}
	return p;
}
int main(){
	//int v[]={3,1,4,2};
	//int v[]={3,4,5,1,2};
	int v[]={340,1387,2101,847,1660,733,36,528};
	vector<int>arr;
	arr.assign(v,v+sizeof(v)/sizeof(int));
	vector<int>b=buildMaxTree(arr,arr.size());
	for(int i=0;i<b.size();i++){
		cout<<b[i]<<" ";
	}
	cout<<endl;
	return 0;
}
```


