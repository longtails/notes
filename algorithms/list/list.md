### 链表

1. 链表问题算法难度不高，但考察代码实现能力
2. 链表和数组都是一种线性结构：   
    1. 数组是一段连续的存储空间
    2. 链表空间不一定保证连续，为临时分配的

分类：  
1. 按链接方向：单链表、双链表
2. 按有无环：普通链表、循环链表

关键点：  
1. 链表调整函数的返回值类型，根据要求往往是节点类型  
2. 处理链表过程中，先采用画图的方式理清逻辑
3. 链表问题对于边界条件讨论要求严格  

关于链表插入和删除的注意事项：
1. 特殊处理链表为空，或者链表长度为1的情况
2. 注意插入操作的调整过程
3. 注意删除操作的调整过程

注意点：头尾节点及空节点需要特殊考虑

双链表的插入与删除和单链表类似，但是需要额外考虑previous指针的指向

单链表的翻转操作：  
1. 当链表为空或者长度为1时，特殊处理
2. 对于一般情况，注意记录当前节点的next，用于反转下一个

注意：
1. 大量链表问题可以使用额外数据结构来简化调整过程
2. 但链表问题最优解往往是不使用额外数据结构的方法


#### 案例一

给定一个整数num,如何在节点值有序的环形链表中插入一个节点值为num的节点，并且保证这个环形单链表依然有序。

```cpp
#include<iostream>
#include<vector>
using namespace std;
struct ListNode {
    int val;
    struct ListNode *next;
    ListNode(int x) : val(x), next(NULL) {}
};
ListNode* insert(vector<int> A, vector<int> nxt, int val) {
	if(A.empty()){
		ListNode*p=new ListNode(val);
		p->next=p;
		return p;
	}
	ListNode* head=new ListNode(A[0]);
	ListNode*p=head;
	for(int i=0;i<nxt.size()-1;i++){
		ListNode *tmp=new ListNode(A[nxt[i]]);
		p->next=tmp;
		p=p->next;
	}
	p->next=head;
	//插入
	p=head;
	ListNode*inode=new ListNode(val);
	if(val>head->val){
		while(p->next!=head){
			if(p->next->val>=val){
				break;
			}
			p=p->next;
		}
	}else{
		while(p->next!=head)p=p->next;
		head=inode;
	}
	inode->next=p->next;
	p->next=inode;

	return head;
}
int main(){
	int val[]={1,3,4,5,7};
	int nxt[]={1,2,3,4,0};
	int v=2;
	vector<int>A,B;
	A.assign(val,val+sizeof(val)/sizeof(int));
	B.assign(nxt,nxt+sizeof(val)/sizeof(int));
	ListNode*p=insert(A,B,v);
	ListNode*head=p;
	do{
		if(p!=NULL){
			cout<<p->val<<" ";
		}
		p=p->next;
	}while(p!=head);
	cout<<endl;
	return 0;
}
```
  

#### 案例二

给定一个链表中的节点node，但不给定整个链表的头节点。如何在链表中删除node?请实现这个函数，要求时间复杂度为O(1)。（**其实，这个题目应该是叫删除无头单链表的非尾节点**）

1->2>3->4->null,删除节点3 
一个有问题的思路：单链表，将节点4的内容复制到节点3上，然后删掉节点4。**但存在一个问题，无法删除最后一个节点**，比如删除节点4,我们不知道节点3的next，无法将next设置为null。  
实际，上述思虑并不是删除了该节点，而是进行了值的拷贝：  
1. 结构复杂且拷贝操作受限时，不可行
2. 在工程上会影响外部依赖

```cpp
#include<iostream>
#include<vector>
using namespace std;
struct ListNode {
    int val;
    struct ListNode *next;
    ListNode(int x) : val(x), next(NULL) {}
};
ListNode* removeNode(ListNode* pHead, int delVal) {
	ListNode*p=pHead;
	while(p!=NULL){
		if(p->val==delVal){
			if(p->next!=NULL){
				p->val=p->next->val;
				ListNode*tmp=p->next;
				delete tmp;
				p->next=p->next->next;
				break;
			}
		}
		p=p->next;
	}
	return pHead;
}
int main(){
	ListNode head(1);
	head.next=new ListNode(2);
	head.next->next=new ListNode(3);
	head.next->next=new ListNode(4);
	ListNode*p=&head;
	while(p!=NULL){
		cout<<p->val<<" ";
		p=p->next;
	}
	cout<<endl;
	p=removeNode(&head,2);
	while(p!=NULL){
		cout<<p->val<<" ";
		p=p->next;
	}
	cout<<endl;
	return 0;
}
```
 
  
#### 案例三

给定一个链表的头节点head,再给定一个数num,请把链表调整成节点值小于num的节点都放在链表的左边，值等于num的节点都放在链表中间，值大于num的节点，都放在链表的右边。

简单做法：  
1. 将链表的所有节点放入到数组中，然后将数组进行快排划分的调整过程  
2. 然后将数组中的节点一次重新串连


最优解：不需要额外空间，只需要分成三个链表，最后串连起来。

```cpp
#include<iostream>
using namespace std;
struct ListNode {
    int val;
    struct ListNode *next;
    ListNode(int x) : val(x), next(NULL) {}
};
ListNode* listDivide(ListNode* head, int val) {
	ListNode small(-1);
	ListNode big(-1);
	ListNode*sp=&small;
	ListNode*bp=&big;

	while(head!=NULL){
		if(head->val<=val){
			sp->next=head;
			sp=sp->next;
		}else{
			bp->next=head;
			bp=bp->next;
		}
		head=head->next;
	}
	bp->next=NULL;
	sp->next=big.next;
	return small.next;
}
int main(){
	ListNode*h1=new ListNode(1);
	ListNode*h2=new ListNode(4);
	ListNode*h3=new ListNode(2);
	ListNode*h4=new ListNode(5);
	h1->next=h2;h2->next=h3;h3->next=h4;
	int val=3;
	ListNode*p=listDivide(h1,val);
	while(p!=NULL){
		cout<<p->val<<" ";
		p=p->next;
	}
	cout<<endl;

	return 0;
}
```


#### 案例四

给定两个有序链表的头节点head1和head2，打印两个有序链表的公共部分。

做法：  
1. 如果两个链表有任何一个为空，直接返回即可  
2. 如果两个链表都不为空，因为有序，所以从head1,head2开始相后调整遇到相等为止

```cpp
#include<iostream>
#include<vector>
using namespace std;
struct ListNode {
    int val;
    struct ListNode *next;
    ListNode(int x) : val(x), next(NULL) {}
};
vector<int> findCommonParts(ListNode* headA, ListNode* headB) {
	vector<int>v;
	if(headA==NULL||headB==NULL){
		return v;
	}
	while(headA!=NULL&&headB!=NULL){
		if(headA->val==headB->val){
			v.push_back(headA->val);
			headA=headA->next;
			headB=headB->next;
		}else if(headA->val>headB->val){
			headB=headB->next;
		}else if(headB->val>headA->val){
			headA=headA->next;
		}
	}
	return v;
}
int main(){
	//1,2,3,4,5,6,7
	ListNode*h1=new ListNode(1);
	ListNode*h2=new ListNode(2);
	ListNode*h3=new ListNode(3);
	ListNode*h4=new ListNode(4);
	ListNode*h5=new ListNode(5);
	ListNode*h6=new ListNode(6);
	ListNode*h7=new ListNode(7);
	h1->next=h2;h2->next=h3;h3->next=h4;
	h4->next=h5;h5->next=h6;h6->next=h7;
	ListNode*h11=new ListNode(2);
	ListNode*h22=new ListNode(4);
	ListNode*h33=new ListNode(6);
	ListNode*h44=new ListNode(8);
	ListNode*h55=new ListNode(10);
	h11->next=h22;h22->next=h33;h33->next=h44;h44->next=h55;
	vector<int>v=findCommonParts(h1,h11);
	for(int i=0;i<v.size();i++){
		cout<<v[i]<<" ";
	}
	cout<<endl;
	return 0;
}
```

#### 案例五

给定一个单链表的头节点head,实现一个调整单链表的函数，使得每k个节点之间逆序，如果最后不够k个节点一组，则不调整最后几个节点。

例如链表：    
1->2->3->4->5->6->7->8->null,K=3   
调整后:   
3->2->1->6->5->4->7->8->null  
因为K==3,所以每三个节点之间逆序，但其中的7、8不调整，因为只有两个节点不够一组。  

如果链表为空，或长度为1,或k<2,链表不用进行调整

方法一：时间复杂度为O(n),额外空间复杂度为O(k)  
方法二：时间复杂度为O(n),额外空间复杂度为O(1)

方法一：利用栈，入栈K个元素后，就一次弹出，需要注意最后不够k个的情况。  
方法二：基本过程和方法一类似，依然是每收集k个元素就做逆序调整，需要更多的边界讨论及代码实现技巧。从头节点开始一旦收集到k个元素，就开始逆序并返回头，连接到上一组元素的尾部。

```cpp
//方法二
#include<iostream>
using namespace std;
struct ListNode {
    int val;
    struct ListNode *next;
    ListNode(int x) : val(x), next(NULL) {}
};
//方法一栈，这里不使用，方法二直接反转
ListNode* reverse(ListNode*preTail,ListNode*head,int k){
	if(k<=1)return head;
	ListNode*tail=head;
	ListNode*p=head->next;
	ListNode*pre=head;
	ListNode*nxt=NULL;
	for(int i=1;i<k&&p!=NULL;i++){
		nxt=p->next;
		p->next=pre;
		pre=p;//记录上一个node
		p=nxt;
	}
	if(preTail!=NULL)preTail->next=pre;
	tail->next=nxt;
	return tail;
}
//1,4,2,5
ListNode* inverse(ListNode* head, int k) {
	ListNode preTail(-1);//加一个哨兵，方便链表操作
	preTail.next=head;
	ListNode*pre=&preTail;
	ListNode*p=head;
	int i=0;
	while(p!=NULL){
		p=p->next;
		if(++i==k){
			pre=reverse(pre,pre->next,k);
			i=0;
		}
	}
	//最后不满足k个，不调整
	return preTail.next;
}
int main(){
	ListNode*h1=new ListNode(1);
	ListNode*h2=new ListNode(2);
	ListNode*h3=new ListNode(3);
	ListNode*h4=new ListNode(4);
	ListNode*h5=new ListNode(5);
	ListNode*h6=new ListNode(6);
	ListNode*h7=new ListNode(7);
	ListNode*h8=new ListNode(8);
	h1->next=h2;h2->next=h3;h3->next=h4;h4->next=h5;
	//h5->next=h6;h6->next=h7;h7->next=h8;
	ListNode*p=inverse(h1,3);
	while(p!=NULL){
		cout<<p->val<<" ";
		p=p->next;
	}
	cout<<endl;
	return 0;
}
```

#### 案例六

给定一个单链表的头节点head,链表中每个节点保存一个整数，再给定一个值val,把所有等于val的节点删掉。  
一个清晰的思路是:当成重新构建链表，原链表作为输入元素一个个加入到新链表中，这样思路清晰。

```cpp
#include<iostream>
using namespace std;
struct ListNode {
    int val;
    struct ListNode *next;
    ListNode(int x) : val(x), next(NULL) {}
};

ListNode* clear(ListNode* head, int val) {
	ListNode preHead(val-1);preHead.next=head;
	ListNode* pre=&preHead;
	while(head!=NULL){
		ListNode*tmp=head;
		head=head->next;
		if(tmp->val!=val){
			pre->next=tmp;
			pre=pre->next;
		}else{
			delete tmp;
		}
	}
	return preHead.next;
}
int main(){
	ListNode*h1=new ListNode(1);
	ListNode*h2=new ListNode(2);
	ListNode*h3=new ListNode(3);
	ListNode*h4=new ListNode(4);
	ListNode*h5=new ListNode(3);
	ListNode*h6=new ListNode(2);
	ListNode*h7=new ListNode(1);
	h1->next=h2;h2->next=h3;h3->next=h4;
	h4->next=h5;h5->next=h6;h6->next=h7;
	int v=2;
	ListNode*p=clear(h1,v);
	while(p!=NULL){
		cout<<p->val<<" ";
		p=p->next;
	}
	cout<<endl;
	return 0;
}

```

#### 案例七

判断一个链表是否为回文结构。  
例如：1->2->3->2->1,是回文结构，返回true，1->2->3->1不是回文结构，返回false。

方法一：时间复杂度为O(n),使用了n个额外空间。  
方法二：时间复杂度为O(n),使用了N/2的额外空间。  
方法三：时间复杂度为O(n),额外空间复杂度为O(1)。

方法一： 申请一个栈，顺序读取链表元素并入栈，接着，再次读取链表，并和栈弹出的元素比较是否相等，直到链表读取完全和栈空。  

方法二：申请一个栈，并使用快慢两个指针同时遍历，快指针一次走两步，慢指针一次走一步，满指针访问过的元素入栈；当快指针访问完毕，则满指针到达链表中间为止，若是回文这慢指针剩下要访问的部分应该和前半部分已经访问过的出栈元素相等，注意若元素个数为计数，则中间元素不入栈。 

方法三： 先找到链表中间位置，然后从中间为止逆序调整尾部元素，这样，可以从两端对比看是否相等。注意最后，把链表的结构调整回原来的位置。

```cpp
#include<iostream>
using namespace std;
struct ListNode {
    int val;
    struct ListNode *next;
    ListNode(int x) : val(x), next(NULL) {}
};
bool isPalindrome(ListNode* pHead) {
	if(pHead==NULL){
		return true;
	}
	ListNode*p=pHead;
	int k=0;
	ListNode*pH=pHead;
	ListNode*pL=pHead;
	ListNode*pre=NULL;
	while(pH!=NULL){
		ListNode*p=pL;
		pL=pL->next;
		if(pH->next!=NULL){
			pH=pH->next->next;
		}else{
			//奇数
			break;
		}
		p->next=pre;
		pre=p;
	}
	while(pre!=NULL&&pL!=NULL){
		if(pre->val!=pL->val){
			return false;
		}
		pre=pre->next;
		pL=pL->next;
	}
	return true;
}
int main(){
	ListNode*h1=new ListNode(1);
	ListNode*h2=new ListNode(2);
	ListNode*h3=new ListNode(3);
	ListNode*h4=new ListNode(2);
	ListNode*h5=new ListNode(1);
	h1->next=h2;h2->next=h3;h3->next=h4;
	h4->next=h5;
	cout<<isPalindrome(h1)<<endl;
	return 0;
}
```

#### 案例八

一个链表结构中，每个节点不仅包含有一条指向下一个节点的next指针，同时含有一条rand指针，rand指针可能指向任何一个链表中的节点，请复制这种含有rand指针节点的链表。  

方法：第一次遍历，在原链表上复制节点n到next位置能n\`，n\`的rand指针开始为NULL；第二次遍历修改n\`的rand指针，通过n的rand指针访问到nr,那下一个节点就是n\`r,遍历完，即使得所有的n\`rand指向n\`r；第三次遍历，分离处n\`，返回复制的链表即可。时间复杂度O(n)。


```cpp
#include<iostream>
using namespace std;
struct RandomListNode {
    int label;
    struct RandomListNode *next, *random;
    RandomListNode(int x) :
            label(x), next(NULL), random(NULL) {
    }
};
RandomListNode* Clone(RandomListNode* pHead)
{
	RandomListNode*p=pHead;
	while(p!=NULL){
		RandomListNode*cp=new RandomListNode(p->label);
		//RandomListNode*cp=new RandomListNode(10+p->label);//测试用
		cp->next=p->next;
		p->next=cp;
		p=cp->next;
	}
	p=pHead;
	//只能进行random赋值，不能进行抽离
	while(p!=NULL){
		RandomListNode*cp=p->next;
		//发生段错误：为检查random是否为NULL
		cp->random=p->random==NULL?NULL:p->random->next;
		p=cp->next;
	}
	//恢复原链表
	p=pHead;
	RandomListNode pCP(-1);
	RandomListNode*pcp=&pCP;
	while(p!=NULL){
		RandomListNode*cp=p->next;
		p->next=cp->next;
		p=p->next;
		pcp->next=cp;
		pcp=pcp->next;
	}
	return pCP.next;
}
int main(){
	RandomListNode*h1=new RandomListNode(1);
	RandomListNode*h2=new RandomListNode(2);
	RandomListNode*h3=new RandomListNode(3);
	RandomListNode*h4=new RandomListNode(4);
	RandomListNode*h5=new RandomListNode(5);
	h1->next=h2;h2->next=h3;h3->next=h4;h4->next=h5;
	h1->random=h3;h2->random=h4;h3->random=h1;h4->random=h1;h5->random=h2;
	RandomListNode*cp=Clone(h1);
	RandomListNode*p=h1;
	cout<<"next"<<endl;
	while(p!=NULL){
		cout<<p->label<<"\t";
		p=p->next;
	}
	cout<<endl;
	p=cp;
	while(p!=NULL){
		cout<<p->label<<"\t";
		p=p->next;
	}
	cout<<endl;
	cout<<"random"<<endl;
	p=h1;
	while(p!=NULL){
		cout<<p->random->label<<"\t";
		p=p->next;
	}
	cout<<endl;
	p=cp;
	while(p!=NULL){
		cout<<p->random->label<<"\t";
		p=p->next;
	}
	cout<<endl;
	return 0;
}
```

#### 案例九

如何判断一个单链表是否有环？有环的话返回进入环的第一个节点，无环的话返回空。如果链表的长度为N,请做到时间复杂度O(N),额外空间复杂度O(1)。


若无空间的限制，可以用哈希表实现，每遍历一个节点，就记录下一个，遇到重复的九返回该节点，否则遍历完，返回空。

最优额外空间复杂度O(1)的解法，利用快慢指针，快指针一次走两步，慢指针一次走一步，若快指针遇到NULL,则说明五环，返回空；若有环，快指针和慢指针将在环里相遇，然后快指针从头节点一次一步走，慢指针在环里一次一步走，最后再次相遇时，相遇到的节点就是环的入口。

```cpp
#include<iostream>
using namespace std;
struct ListNode {
    int val;
    struct ListNode *next;
    ListNode(int x) : val(x), next(NULL) {}
};
int chkLoop(ListNode* head, int adjust) {
	//快慢指针
	ListNode*a=head;
	ListNode*b=head;
	while(b!=NULL){
		cout<<a->val<<" "<<b->val<<endl;
		b=b->next==NULL?NULL:b->next->next;
		a=a->next;
		if(a==b){
			cout<<"a==b"<<endl;
			break;
		}
	}
	if(b==NULL)return -1;
	b=head;
	while(a!=b){
		b=b->next;
		a=a->next;
	}
	return b->val;
}
int main(){
	ListNode*h1=new ListNode(1);
	ListNode*h2=new ListNode(2);
	ListNode*h3=new ListNode(3);
	ListNode*h4=new ListNode(4);
	ListNode*h5=new ListNode(5);
	h1->next=h2;h2->next=h3;h3->next=h4;h4->next=h5;h5->next=NULL;
	int n=chkLoop(h1,10);
	cout<<n<<endl;
	return 0;
}
```

#### 案例十

如何判断两个五环单链表是否相交？相交的话返回第一个相交的节点，不相交的话返回空。如果两个链表长度分别为N和M，请做到时间复杂度O(N+M),额外空间复杂度O(1)。

若无空间复杂度限制，同样可以用哈希表，先访问第一个链表，记录到哈希表，然后访问第二个链表，若发现节点已经在哈希表中，那么相交，否则遍历完，返回空。

在额外空间复杂度O(1)的要求下，将第一个链表最后一个节点的next指针指向其头节点，形成一个环，然后从第二个节点开始，用快慢指针找环入口的办法进行。

空间复杂度O(1)还有一个方法，分别遍历两个链表，纪录两个链表的长度，假设分别为L1,L2(L1>L2)，接着，再次访问两个链表，链表1先遍历L1-L2个，然后和链表2同时进行，若两个节点相同，则返回该节点，若不同则返回NULL。

```cpp
#include<iostream>
using namespace std;
struct ListNode {
    int val;
    struct ListNode *next;
    ListNode(int x) : val(x), next(NULL) {}
};
ListNode* comNode(int AB,ListNode*headA,ListNode*headB){
	for(int i=0;i<AB;i++){
		headA=headA->next;
	}
	while(headA!=headB){
		headA=headA->next;
		headB=headB->next;
	}
	return headA;
}
bool chkIntersect(ListNode* headA, ListNode* headB) {
	int LA=0,LB=0;
	ListNode*p=headA;
	while(p!=NULL){
		LA++;p=p->next;
	}
	p=headB;
	while(p!=NULL){
		LB++;p=p->next;
	}
	if(LA>=LB)p=comNode(LA-LB,headA,headB);
	else p=comNode(LB-LA,headB,headA);
	return p!=NULL;
}
int main(){
	ListNode*h1=new ListNode(1);
	ListNode*h2=new ListNode(2);
	ListNode*h3=new ListNode(3);
	ListNode*h4=new ListNode(4);
	ListNode*h5=new ListNode(5);
	h1->next=h2;h2->next=h3;h3->next=h4;h4->next=h5;
	ListNode*h11=new ListNode(11);
	ListNode*h21=new ListNode(21);
	h11->next=h21;h21->next=h5;
	cout<<chkIntersect(h1,h11)<<endl;
	return 0;
}
```

#### 案例十一

如何判断两个有环单链表是否相交？相交的话返回第一个相交的节点，不相交的话返回空。如果两个链表长度分别为N和M,请做到时间复杂度O(N+M),额外空间复杂度O(1)。

方法：先分别找到两个链表的环入口n1,n2,若n1==n2,则用案例十的长度的方法找到相交点；若n1!=n2,则可能不相交，则能两个入口不在一个位置，判断方法是，遍历链表1的环，若遇到n2，则说明相交，返回n1或n2都可以，若遇到n1则说明不相交。

```cpp
#include<iostream>
using namespace std;
struct ListNode {
    int val;
    struct ListNode *next;
    ListNode(int x) : val(x), next(NULL) {}
};
ListNode*loopNode(ListNode*head){
	//快慢
	ListNode*a=head;
	ListNode*b=head;
	while(b!=NULL){
		b=b->next==NULL?b->next:b->next->next;
		a=a->next;
		if(a==b){
			break;
		}
	}
	b=head;
	while(a!=b){
		a=a->next;
		b=b->next;
	}
	return a;
}
bool chkInter(ListNode* head1, ListNode* head2, int adjust0, int adjust1) {
	//先找到环入口
	ListNode*h1=loopNode(head1);
	ListNode*h2=loopNode(head2);
	cout<<h1->val<<" "<<h2->val<<endl;
	ListNode*p=h1->next;
	while(p!=h1&&p!=h2){
		p=p->next;
	}
	return p==h2;
}
int main(){
	ListNode*h1=new ListNode(1);
	ListNode*h2=new ListNode(2);
	ListNode*h3=new ListNode(3);
	ListNode*h4=new ListNode(4);
	ListNode*h5=new ListNode(5);
	h1->next=h2;h2->next=h3;h3->next=h4;h4->next=h5;h5->next=h2;
	ListNode*h11=new ListNode(1);
	ListNode*h12=new ListNode(2);
	ListNode*h13=new ListNode(3);
	h11->next=h12;h12->next=h13;h13->next=h2;
	cout<<chkInter(h1,h11,0,0)<<endl;
	return 0;
}
```
#### 案例十二

给定两个单链表的头节点head1和head2,如何判断两个链表是否相交？相交的话返回第一个相交的节点，不相交的话返回空。 

这道题没有说是否有环，所以要先判断环，先找两个链表的环入口n1,n2,若n1,n2都为空，则用无环链表的方式找相交点；若一个为空，另一个不会空，则一定不相交；若n1，n2都不会空，则用有环链表相交的方法找相交点。 

```cpp
#include<iostream>
using namespace std;
struct ListNode {
    int val;
    struct ListNode *next;
    ListNode(int x) : val(x), next(NULL) {}
};
ListNode*comNode(int AB,ListNode*head1,ListNode*head2){
	for(int i=0;i<AB;i++){
		head1=head1->next;
	}
	while(head1!=NULL&&head2!=NULL&&head1!=head2){
		head1=head1->next;
		head2=head2->next;
	}
	return head1;
}
ListNode*loopNode(ListNode*head){
	//快慢
	ListNode*a=head;
	ListNode*b=head;
	while(b!=NULL){
		b=b->next==NULL?b->next:b->next->next;
		a=a->next;
		if(a==b){
			break;
		}
	}
	b=head;
	while(a!=NULL&&a!=b){
		a=a->next;
		b=b->next;
	}
	return a;
}
bool chkInter(ListNode* head1, ListNode* head2, int adjust0, int adjust1) {
	//先找到环入口
	ListNode*h1=loopNode(head1);
	ListNode*h2=loopNode(head2);
	
	if((h1==NULL&&h2!=NULL)||(h1!=NULL&&h2==NULL)){
		return false;
	}
	if(h1==NULL&&h2==NULL){
		int LA=0;int LB=0;
		ListNode*p=head1;
		while(p!=NULL){
			LA++;p=p->next;
		}
		p=head2;
		while(p!=NULL){
			LB++;p=p->next;
		}
		if(LA>=LB)p=comNode(LA-LB,head1,head2);
		else p=comNode(LB-LA,head2,head1);
		if(p!=NULL)return true;
		else return false;
	}
	ListNode*p=h1->next;
	while(p!=h1&&p!=h2){
		p=p->next;
	}
	return p==h2;
}
int main(){
	ListNode*h1=new ListNode(1);
	ListNode*h2=new ListNode(2);
	ListNode*h3=new ListNode(3);
	ListNode*h4=new ListNode(4);
	ListNode*h5=new ListNode(5);
	h1->next=h2;h2->next=h3;h3->next=h4;h4->next=h5;h5->next=h2;
	ListNode*h11=new ListNode(1);
	ListNode*h12=new ListNode(2);
	ListNode*h13=new ListNode(3);
	h11->next=h12;h12->next=h13;h13->next=h3;
	cout<<chkInter(h1,h11,0,0)<<endl;
	return 0;
}
```