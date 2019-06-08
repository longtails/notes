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

