### 二分搜索

常见应用场景：  
1. 在有序序列中找一个数
2. 并不一定非要在有序序列中才能得到应用（只要二分之后能够淘汰一半）

常见的考察点：  
1. 对于边界条件的考察以及代码实现的能力。

常见题目的变化：  
1. 给定处理或查找的对象不同（比如有重复的/无重复的）
2. 判断条件不同
3. 要求返回的内容不同

在有序循环数组中进行二分搜索,比如1,2,3,4,5循环之后是:
```
1,2,3,4,5
2,3,4,5,1
3,4,5,1,2
``` 
重要提醒：
```
mid=(left+right)/2 left+right可能溢出
更安全的写法：mid=left+(right-left)/2
```

---

#### 案例一

给定一个无序数组arr,已知任意相邻的两个元素值都不重复。请返回任意一个局部最小的位置。  
所谓局部最小的位置是指，如果arr[0] < arr[1]，那么位置0就是一个局部最小的位置。如果arr[N-1] (也就是arr最右的数)小于arr[N-2],那么位置N-1也是局部最小的位置。如果位置i既不是最左位置也不是最右位置。那么只要满足arr[i]同时小于它左右两侧的值即(arr[i-1]和arr[i+1])，那么位置i也是一个局部最小的位置。  

分析：本题依然可以用二分搜索来实现，时间复杂度为O(logN)  
1. arr为空或者长度为0，返回-1，表示局部最小位置不存在
2. 如果arr长度为1，返回0，因此此时0是局部最小位置
3. 如果arr长度大于1，先判断两端，再判断mid和两端：
    1) mid < l && mid < r,说明mid就是局部最小  
    2) mid>l,mid>r,两端小，说明左右都存在局部最小  
    3) l < mid < r,说明在[l,mid]之间一定存在局部最小，[mid,r]不确定  
    4) l > mid > r,说明在[mid,r]之间一定存在局部最小，[l,mid]不确定  

```cpp
#include<iostream>
#include<vector>
using namespace std;
int getLessIndex(vector<int> arr) {
	int n=arr.size();
	if(n==0){
		return -1;
	}
	if(n==1||arr[0]<arr[1]){
		return 0;
	}
	if(arr[n-1]<arr[n-2]){
		return n-1;
	}
	int l=1,r=n-2;
	int mid=0;
	while(l<r){
		mid=(l+r)/2;
		//这是用来判断mid趋势的,题目前提，相邻两个数都不相等
		if(arr[mid]>arr[mid-1]){
			r=mid-1;
		}else if(arr[mid]>arr[mid+1]){
			l=mid+1;
		}else{//中间小两边大
			return mid;
		}
	}
	return l;
}
int main(){
	int v[]={4,3,2,3,2,1,3,4};
	//int v[]={3,2,9,2,1,4,0,10,9,0,8,3,5,6,7,1,9,2,4,0,7};
	vector<int>arr;
	arr.assign(v,v+sizeof(v)/sizeof(int));
	cout<<getLessIndex(arr)<<endl;
	return 0;
}
```

#### 案例二

给定一个有序数组arr,再给定一个整数num,请在arr中找到num这个数出现的最左边的位置。  
分析： 二分搜索num，并记录找到的位置，直到二分搜索完毕。

```cpp
#include<iostream>
#include<vector>
using namespace std;

int findPos(vector<int> arr, int n, int num) {
	int l=0,r=n-1,m=0;
	while(l<=r){//边界很难控制,边界控制要用两个元素测试l\r\m
		m=(l+r)/2;
		if(arr[m]>num){
			r=m-1;
		}else if(arr[m]<num){
			l=m+1;
		}else{
			break;
		}
	}
	for(int i=m;i>0;i--){
		if(arr[i-1]==num){
			m=i-1;
		}else{
			break;
		}
	}
	return m;
}
int main(){
	int v[]={36,62,146,208,210,369,616};
	int num=616;
	vector<int> arr;
	arr.assign(v,v+sizeof(v)/sizeof(int));
	cout<<findPos(arr,arr.size(),num)<<endl;
	return 0;
}
```

#### 案例三

给定一个有序循环数组arr,返回arr中的最小值。有序循环数组是指，有序数组左边任意长度的部分放到右边去，右边的部分拿到左边来。比如数组[1,2,3,3,4],是有序循环数组，【4,1,2,3,3]也是。

分析：  
1. L < R ,说明有序，L即是最小值
2. L > R ,说明最小值在L和R中间，再判断Mid和L、R的关系：确定最小值的区间，然后二分下去
3. L = R ,则无法判断，只能遍历确定，比如[2,2,1,2,2]

```cpp
#include<iostream>
#include<vector>
using namespace std;
int getMin(vector<int> arr, int n) {
	// write code here
	int l=0,m=0,r=n-1;
	while(l<r){
		m=(l+r)/2;
		if(arr[m]>=arr[l]&&arr[m]>arr[r]){
			l=m+1;
		}else if(arr[m]<arr[r]){
			r=m;
		}else{
			break;
		}
	}
	for(int i=r;i>=0;i--){
		if(arr[i]>arr[r]){
			break;
		}else if(arr[i]<arr[r]){
			r=i;
		}
	}
	return arr[r];
}
int main(){
	int v[]={4,5,1,2,3,3,3,3,3,3,3,3};
	vector<int>arr;
	arr.assign(v,v+sizeof(v)/sizeof(int));
	cout<<getMin(arr,arr.size())<<endl;
	return 0;
}
```


#### 案例四

给定一个有序数组arr,其中不含有重复元素，请找满足arr[i]==i条件的最左位置。如果所有位置上的数都不满足条件，返回-1。

```cpp
#include<iostream>
#include<vector>
using namespace std;
int findPos(vector<int> arr, int n) {
	if(n==0||arr[0]>0||arr[n-1]<n-1){
		return -1;
	}
	int l=0,r=n-1,m=0,pos=0;
	//这个等号，可以用两个元素的例子模拟一下测试出来
	while(l<=r){
		m=(l+r)/2;
		if(arr[m]>=m){
			if(arr[m]==m)
				pos=m;
			r=m-1;
		}else{
			l=m+1;
		}
	}
	return pos;
}
int main(){
	int v[]={-1,0,2,3};
	vector<int> arr;
	arr.assign(v,v+sizeof(v)/sizeof(int));
	cout<<findPos(arr,arr.size())<<endl;
	return 0;
}
```

#### 案例五

给定一颗完全二叉树的头节点head,返回这棵树的节点个数。如果完全二叉树的节点为N,请实现时间复杂度低于O(N)的解法。

分析：找到最左节点确定树的高度h1， 找右子树最左节点，确定高度h2，若h1>h2,则可以用公式计算右子树的节点个数;然后对左子树递归进行同样的操作，最终仅剩一个节点可以结束。

```cpp
#include<iostream>
using namespace std;
struct TreeNode {
    int val;
    struct TreeNode *left;
    struct TreeNode *right;
    TreeNode(int x) :
            val(x), left(NULL), right(NULL) {
    }
};
int getLH(TreeNode* root){
	int h=0;
	while(root!=NULL){
		h++;
		root=root->left;
	}
	return h;
}
int count(TreeNode* root) {
	if(root==NULL){
		return 0;
	}
	int c=1;
	int lh=getLH(root->left);
	int rh=getLH(root->right);
	//利用满二叉树公式计算节点个数，其他分支再次递归计算即可
	if(lh+1==rh){
		c+=(2<<(rh-1))-1;
	}else{
		c+=count(root->right);
	}
	c+=count(root->left);
	return c;
}
int main(){
	TreeNode r(0);r.left=NULL;r.right=NULL;
	TreeNode n1(1),n2(2),n3(3),n4(4),n5(5),n6(6),n7(7);
	r.left=&n1;r.right=&n2;
	n1.left=&n3;n1.right=&n4;
	n2.left=&n5;n2.right=&n6;
	n3.left=&n7;
	cout<<count(&r)<<endl;
	return 0;
}
li
```

#### 案例六

如何更快的求一个整数k的N次方。如果两个整数相乘并得到结果的时间复杂度为O(1),得到整数k的N次方的过程请实现时间复杂度为O(logN)的方法。

将指数按二进制方式展开，10^(10_2)=10^(01_2)*10^(01_2)=10^(01_2+01_2)=10^(10_2),这样按指数位长度次数即可。

```cpp
#include<iostream>
using namespace std;
int getPower(int k, int N) {
	// write code here
	long long  m=1,mt=k;
	while(N>0){
		mt%=1000000007;
		if(N%2){
			m*=mt;
			m=m%1000000007;
		}
		N/=2;
		mt*=mt;//logN的原因
	}
	return  m%1000000007;
}
int main(){
	//cout<<getPower(20,7)<<endl;
	cout<<getPower(2,14876069)<<endl;
	return 0;
}
```
 