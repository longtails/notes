### 智力题

#### 案例一

涂色1:你要在一个nxm的格子图上涂色，你每次可以选择一个未涂色的格子涂上你开始选定的那种颜色。同时为了美观，我们要求你涂色的格子不能相邻，也就是说，不能有公共边，现在问你，在采取最优策略的情况下，你最多能涂多少个格子？

给定格子图的长n和宽m。请返回最多能涂的格子数目。

测试样例：
1,2
返回：1

通过绘图，显示是二分之一
```cpp
class Paint {
public:
    int getMost(int n, int m) {
        int k=m*n;
        return k%2==1?k/2+1:k/2;
    }
};
//答案
class Paint {
public:
    int getMost(int n, int m) {
        return (m*n+1)>>1;
    }
};
```

#### 案例二

赛马：作为一个马场的主人，你要安排你的n匹赛马和另一个马场的n匹马比赛。你已经知道了对方马场的出战表，即参加每一场的马的强壮程度。当然你也知道你自己的所有马的强壮程度。我们假定比赛的结果直接由马的强壮程度决定，即更壮的马获胜(若相同则双方均不算获胜)，请你设计一个策略，使你能获得尽量多的场次的胜利。

给定对方每场比赛的马的强壮程度oppo及你的所有马的强壮程度horses(强壮程度为整数，且数字越大越强壮)同时给定n，请返回最多能获胜的场次。

测试样例：
[1,2,3],[1,2,3],3
返回：2

方法1：这个题目解法，就是如果horse a存在大于未参赛的对方马，那就跟对方最大的弱于a的马比赛，胜场次+1；若a小于等于所有未参赛的对方马，那就选择未参赛的最大的马比赛。田忌赛马。  
方法2: 这里我们不用考虑弱马战对方强马即平或输的情况，我们只要考虑清楚怎样获得最大的赢的次数，剩下的不管怎么样，随机排就可以。那，我们对双方马按战力排序，逆序找到能够赢的次数，之所以逆序找，是因为这样能使该赢的马赢得对方战力最大的马。跟方法1比，只是不用考虑弱马了，时间复杂度也变为了O(N)。
```cpp
#include<iostream>
#include<vector>
#include<algorithm>
using namespace std;

int winMost(vector<int> oppo, vector<int> horses, int n) {
	sort(horses.begin(),horses.end());
	vector<int>flag;
	flag.assign(oppo.size(),0);
	int c=0;
	for(int i=0;i<horses.size();i++){
		int tmp=-1;
		int max=horses[i];
		int mi=-1;
		for(int j=0;j<oppo.size();j++){
			if(flag[j]==1)continue;
			if(horses[i]>oppo[j]){
				if(tmp==-1)tmp=j;
				else if(oppo[j]>oppo[tmp])tmp=j;
			}
			if(oppo[j]>max){
				max=oppo[j];
				mi=j;
			}
		}
		if(tmp!=-1){
			c++;
			flag[tmp]=1;
		}else if(mi!=-1)flag[max]=1;
	}
	return c;
}
int main(){
	int a[]={1,2,3};
	int b[]={1,2,3};
	vector<int>oppo;
	vector<int>horses;
	oppo.assign(a,a+sizeof(a)/sizeof(int));
	horses.assign(b,b+sizeof(b)/sizeof(int));
	cout<<winMost(oppo,horses,oppo.size());
	return 0;
}
```

改进：
```cpp
#include<iostream>
#include<vector>
#include<algorithm>
using namespace std;
//只需排好序，找到能够赛赢的最大次数即可
int winMost(vector<int> oppo, vector<int> horses, int n) {
	sort(oppo.begin(),oppo.end());
	sort(horses.begin(),horses.end());
	vector<int>flag;
	int r=horses.size()-1;
	int c=0;
	for(int i=oppo.size()-1;i>=0;i--){
		if(horses[r]>oppo[i]){//能够赢的最大战力的马
			c++;r--;
		}
	}
	return c;
}
int main(){
	int a[]={1,2,3};
	int b[]={2,2,3};
	vector<int>oppo;
	vector<int>horses;
	oppo.assign(a,a+sizeof(a)/sizeof(int));
	horses.assign(b,b+sizeof(b)/sizeof(int));
	cout<<winMost(oppo,horses,oppo.size());
	return 0;
}
```

#### 案例三

你和你的朋友正在玩棋子跳格子的游戏，而棋盘是一个由n个格子组成的长条，你们两人轮流移动一颗棋子，每次可以选择让棋子跳1-3格，先将棋子移出棋盘的人获得胜利。我们知道你们两人都会采取最优策略，现在已知格子数目，并且初始时棋子在第一格由你操作。请你计算你是否能获胜。

给定格子的数目n(n为不超过300的正整数)。返回一个整数，1代表能获胜，0代表不能获胜。

测试样例：
3
返回：1

分析，通过画图发现，当遇到四个格子时，双方共同努力，就会让先走的那个人失败。

```go
class Jump {
public:
    int checkWin(int n) {
        return (n-1)%4==0?0:1;
    }
};
```

#### 案例四

A与B做游戏。 在一个n*m的矩阵中的出发点是（1，m），终点是（n,1），规则是只能向左移动一格，向下一格或向左下移动一格，先走到终点的为winner。 A先走。

给定两个整数n和m，请返回最后的获胜者的名字(A或B)。

测试样例：
5 3
返回：B

分析；当m和n都是奇数时，先走A的必输，因为在每个方向上都是后手B先到；那么在其他情况时，A都能走一步（左或下），使B走时走时变成全奇数，这样B必输。
```go
class Game {
public:
    char getWinner(int n, int m) {
        // write code here
        /*if(m%2==1&&n%2==1)return 'B';
        else if(m%2==0&&n%2==0)return 'A';
        else if(m%2==0&&n%2==1)return 'A';
        else if(m%2==1&&n%2==0)return 'A';
        */
        if(m%2==1&&n%2==1)return 'B';//等价于 if(n & 1 && m & 1) return 'B';
        else return 'A';
    }
};
```

#### 案例五

现在有一个整数数组，其元素值均为1-n范围内的某个整数，现在你和你的朋友在玩一个游戏，游戏的目的是把数组清空，你们轮流操作，你是先手，每次操作你可以删除数组中值为某个数的元素任意多个(当然数组中值为这个数的元素个数应大于等于你删除的个数,且你至少要删除一个数)。最先把数组清空的人获得胜利。假设你们都采取最优策略，请你计算你能否获得胜利。

给定一个整数数组A和元素个数n。请返回一个整数，1代表你能获胜，0代表你不能获胜。

测试样例：
[1,1,1]   
返回：1

Nim博弈,原型:n堆石子，每次只能拿其中一堆，可以拿走该队中任意个石子(>=1),对于几大堆石子，先手能否获胜？

分析：如果是两种数字每种个数相同，那么先手取一种数字的x个，后手就能在另一种数字中取x,只要这样，最终后手就会取得胜利；当两种数字不同时，先手先取多的那种数字中多出来的部分，之后的情况就和上一种情况相同，这时先手获胜；再看多种数字的情况，Nim有个判断方法：对每种数字个数异或的结果判断，当异或结果为0时，称为平衡状态，为1,称为不平衡状态，不平衡时（1）先手胜，平衡时（0）后手胜。为什么？    
对每种数字的个数按二进制转化，每位上表示该种数字的一个自划分： 
```
A=An,An-1,...,A2,A1,A0;   
B=Bn,Bn-1,...,B2,B1,B0;   
C=Cn,Cn-1,...,C2,C1,C0;   
D=Dn,Dn-1,...,D2,D1,D0;
...
```

举个例子：A=15(1111),B=13(1101),C=3(0011),D=1(0001);
```
1 1 1 1   
1 1 0 1   
0 0 1 1   
0 0 0 1  
```
res=A^B^C^D;结果为0，表示后手胜；
假如先手拿A-7：
```
1 0 0 0   
1 1 0 1     
0 0 1 1   
0 0 0 1  
```
这时，已经不像两种数字时后手直接复制操作就可以取胜，因为不能同时拿两种数字，那后手怎么拿能够取胜呢？先找到不平衡的最大数，这里是1101,结对对1101-x->1010就又保持了平衡。  
```
1 0 0 0   
1 0 1 0     
0 0 1 1   
0 0 0 1  
```
其他操作见图

![](../../images/20190613.Nim.svg)

**还有一个疑问，为什么初始平衡，一定是后手胜呢？** 双方都在追求平衡，最后一定会剩下两个不一样的数，还都是单个的，平衡的，先拿的肯定输；再回过头看，每次操作都都是平衡到不平衡，或者是不平衡到平衡，从最开始的平衡到最后的平衡，一定是经历偶数次的，拿最后的平衡一定还是先手拿，所以先手输。同样，一开始不平衡，先手只需经历一个操作使其变为平衡，接着是后手操作，就跟上述一样了，所以后手输，先手胜。
```go
class Clear {
public:
    int getWinner(vector<int> A, int n) {
        // write code here
        sort(A.begin(),A.end());
        int res=0;
        for(int i=0;i<n;i++){
            int j=i;int tmp=0;
            for(;j<n&&A[i]==A[j];j++){
                tmp++;
            }
            i=j-1;//跳到下一个数字
            res^=tmp;
        }
        return res != 0;
    }
};
```

[博弈论](https://hrbust-acm-team.gitbooks.io/acm-book/content/game_theory/)