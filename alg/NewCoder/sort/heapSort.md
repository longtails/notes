### 堆

什么是堆？
堆是一棵完全二叉树，并满足
${node{_i}>=node_{2*i+1} and node_i>=node_{2*i+2}}$(大顶堆)
或者
${node{_i}<=node_{2*i+1} and node_i<=node_{2*i+2}}$（小顶堆）
![堆](https://images2015.cnblogs.com/blog/1024555/201612/1024555-20161217182750011-675658660.png)
数组存储
![](https://images2015.cnblogs.com/blog/1024555/201612/1024555-20161217182857323-2092264199.png)
堆可以做什么？
可以用来排序，可以用来找到第k大元素

- 构建堆（以大顶堆为例）
0. 整个数据在数组上进行，找到最后一个非叶节点
1. 将该非叶节点和左右孩子比较，若小于孩子则和孩子交换
2. 然后从该节点开始递归检查该子树是否满足大顶堆，若不满足则进行交换，直到叶子
3. 接着从上一个非叶节点检查，重复1、2
4. 直到根节点，整棵树满足大顶堆

```go
//另注意golang有原生的容器heap
//import "container/heap"
package main
import "fmt"

//加入，加入元素到最后，然后上浮操作
func add(nums[]int,val int)[]int{
	nums=append(nums,val)
	for i:=len(nums)-1;i>0;i--{
		if nums[i]>nums[(i-1)/2]{
			tmp:=nums[i]
			nums[i]=nums[(i-1)/2]
			nums[(i-1)/2]=tmp
		}
	}
	return nums
}
func del(nums[]int)int{ //删除，将根和最后的元素交换，然后下沉操作
	s:=len(nums)-1
	max:=nums[0];nums[0]=nums[s];nums[s]=max
	for i:=0;i<s;{
		l:=2*i+1;r:=2*i+2;k:=l
		if l<s&&r<s&&nums[l]<nums[r]{
			k=r
		}
		if k<s&&nums[k]>nums[i]{
			tmp:=nums[i];nums[i]=nums[k];nums[k]=tmp
			i=k
		}else{
			break
		}
	}
	return max
}
func main(){
	nums:=[]int{4,6,8,5,9}
	var bigHead []int
	for i:=0;i<len(nums);i++{
		bigHead=add(bigHead,nums[i])
	}
	fmt.Println(bigHead)
	fmt.Println(del(bigHead))
	fmt.Println(bigHead)
	//去除最后一个
	bigHead=bigHead[:len(bigHead)-1]
	fmt.Println(del(bigHead))
	fmt.Println(bigHead)

}

```
- 堆排序
0. 在堆的基础上，交换根和最后一个节点
1. 在除最后一个节点的节点上，重新调整堆
2. 重复0、1，知道堆只剩下根，这是整个数组就都是有序了（大顶堆的操作结果未非递减，小顶堆的操作结果是非递增）


- 参考
1. [维基百科-堆](https://zh.wikipedia.org/wiki/%E5%A0%86%E7%A9%8D)
2. [图解排序算法(三)之堆排序](https://www.cnblogs.com/chengxiao/p/6129630.html)


```go
//以下是按堆的模式写的程序
//最终是堆，但太浪费了，堆只需要添加和删除两个操作
//并且，以为已经有序，会保持堆的特性，而无序递归检查

package main
import "fmt"
//递归监测，交换到底
func change(nums []int,i,j int){
	s:=j
	if i>=s{
		return
	}
	l:=2*i+1
	if l<s{
	  if nums[l]>nums[i] {
		  tmp := nums[l]
		  nums[l] = nums[i]
		  nums[i] = tmp
	  }
	  change(nums, l,j)
	}
	r:=2*i+2
	if r<s{
		if nums[r]>nums[i] {
			tmp := nums[r]
			nums[r] = nums[i]
			nums[i] = tmp
		}
		change(nums, r,j)
	}
}
//从最后一个非叶节点，换到顶
func build(nums []int)[]int{
	s:=len(nums)
	for i:=s/2-1;i>=0;i--{
		//对于非叶节点，要遍历到叶子，检查是否满足
		change(nums,i,s)
	}
	return nums
}
//堆排序
func findAllMax(nums[]int)[]int{
	s:=len(nums)
	for i:=s-1;i>0;i--{
		tmp:=nums[i]
		nums[i]=nums[0]
		nums[0]=tmp
		change(nums,0,i)
	}
	return nums
}
func main(){
	bigHead:= build([]int{4,6,8,5,9})
	fmt.Println(bigHead)
	fmt.Println(findAllMax(bigHead))
}
/*
[9 6 8 4 5]
[4 5 6 8 9]
*/
```
