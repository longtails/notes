### 二叉树遍历


这里分别用递归、非递归+stack、Morris算法对LNR、NLR、LRN进行了遍历


```go
package main
import "fmt"

type Node struct{
	Val int
	Left,Right *Node
}
type stk []*Node
func (s stk)top()*Node{
	if len(s)==0{
		return nil
	}
	return s[len(s)-1]
}
func (s* stk)push(v *Node){
	*s=append(*s,v)
}
func (s *stk)pop()*Node{
	if len(*s)==0{
		return nil
	}
	ret:=(*s)[len(*s)-1]
	*s=(*s)[:len(*s)-1]
	return ret
}
func (s stk)size()int{
	return len(s)
}
//LNR
func LNR(root *Node){
	if root==nil{
		return
	}
	LNR(root.Left)
	fmt.Print(root.Val," ")
	LNR(root.Right)
}
func LNR_Loop(root *Node){
	fmt.Println()
	var sk stk
	tmp:=root
	for tmp!=nil{
		pre:=tmp
		for pre!=nil{
			sk.push(pre)
			pre=pre.Left
		}
		if sk.size()>0{
			tmp=sk.pop()
			fmt.Print(tmp.Val," ")
			tmp=sk.top()
			if tmp!=nil{
				fmt.Print(tmp.Val," ")
				tmp=tmp.Right
				sk.pop()
			}
		}
	}
}
func LNR_Morris(root*Node){
	fmt.Println()
	tmp:=root
	for tmp!=nil{
		if tmp.Left!=nil{
			pre:=tmp.Left
			for pre.Right!=nil&&pre.Right!=tmp{
				pre=pre.Right
			}
			if pre.Right==tmp{//回程再次访问，跳到右侧
				fmt.Print(tmp.Val," ")
				tmp=tmp.Right
				pre.Right=nil
			}else{ //开始未修改索引，向下走
				pre.Right=tmp
				tmp=tmp.Left
			}
		}else{//changed node link，走到连接处
			fmt.Print(tmp.Val," ")
			tmp=tmp.Right
		}
	}
	fmt.Println()
}
//------------------
func NLR(root*Node){
	if root==nil{
		return
	}
	fmt.Print(root.Val," ")
	NLR(root.Left)
	NLR(root.Right)
}
func NLR_Loop(root *Node){
	fmt.Println()
	var sk stk
	sk.push(root)
	for sk.size()>0{
		root=sk.pop()
		fmt.Print(root.Val," ")
		if root.Right!=nil{
			sk.push(root.Right)
		}
		if root.Left!=nil{
			sk.push(root.Left)
		}
	}
}
func NLR_Morris(root*Node){
	fmt.Println()
	tmp:=root
	for tmp!=nil{
		if tmp.Left!=nil{
			pre:=tmp.Left
			for pre.Right!=nil&&pre.Right!=tmp{
				pre=pre.Right
			}
			if pre.Right==tmp{//回程再次访问，跳到右侧
				tmp=tmp.Right
				pre.Right=nil
			}else{ //开始未修改索引，向下走
				fmt.Print(tmp.Val," ")
				pre.Right=tmp
				tmp=tmp.Left
			}
		}else{//changed node link，走到连接处
			fmt.Print(tmp.Val," ")
			tmp=tmp.Right
		}
	}
	fmt.Println()
}
//---------
func LRN(root*Node){
	if root==nil{
		return
	}
	LRN(root.Left)
	LRN(root.Right)
	fmt.Print(root.Val," ")
}
func LRN_Loop(root*Node){//有没有不用双栈的
	fmt.Println()
	var sk stk
	var last *Node=nil//记录last
	sk.push(root)
	for sk.size()>0{
		root=sk.top()
		if (root.Left==nil&&root.Right==nil)||(root.Left!=nil&&root.Left==last)||(root.Right!=nil&&root.Right==last){
			fmt.Print(root.Val," ")
			last=root
			sk.pop()
		}else {
			if root.Right!=nil{
				sk.push(root.Right)
			}
			if root.Left!=nil{
				sk.push(root.Left)
			}
		}
	}
}
func LRN_Loop2(root*Node){//有没有不用双栈的
	fmt.Println()
	var sk stk
	var ret stk
	sk.push(root)
	for sk.size()>0{
		root=sk.pop()
		ret.push(root)
		if root.Left!=nil{
			sk.push(root.Left)
		}
		if root.Right!=nil{
			sk.push(root.Right)
		}
	}
	for ret.size()>0{
		fmt.Print(ret.pop().Val," ")
	}
}

func LRN_Morris(root*Node){
	fmt.Println()
	dummy:=Node{-1,root,nil}
	tmp:=&dummy
	for tmp!=nil{
		if tmp.Left!=nil{//非叶子左右选择
			rgt:=tmp.Left
			for rgt.Right!=nil&&rgt.Right!=tmp{
				rgt=rgt.Right
			}
			if rgt.Right==nil{
				rgt.Right=tmp
				tmp=tmp.Left
			}else{
				rgt.Right=nil
				printEdge(tmp.Left)
				tmp=tmp.Right
			}
		}else{//叶子
			tmp=tmp.Right
		}
	}
	fmt.Println()
}
func printEdge(list *Node){
	list=reverse(list)
	tmp:=list
	for tmp!=nil{
		fmt.Print(tmp.Val," ")
		tmp=tmp.Right
	}
	reverse(list)
	/*
	fmt.Println()
	list=reverse(list)
	tmp=list
	for tmp!=nil{
		fmt.Print(tmp.Val," ")
		tmp=tmp.Right
	}
	fmt.Println()
	 */
}
func reverse(list *Node)*Node{//在list头插入的方式reverse
	dummy:=&Node{0,nil,list}
	tmp,nxt:=list.Right,list.Right
	dummy.Right.Right=nil
	for tmp!=nil{
		nxt=tmp.Right
		tmp.Right=dummy.Right
		dummy.Right=tmp
		tmp=nxt
	}
	return dummy.Right
}
func main() {
	h1:=Node{1,nil,nil}
	h2:=Node{2,nil,nil}
	h3:=Node{3,nil,nil}
	h4:=Node{4,nil,nil}
	h5:=Node{5,nil,nil}
	h6:=Node{6,nil,nil}
	h7:=Node{7,nil,nil}
	h1.Left=&h2;h1.Right=&h3;h2.Left=&h4;h2.Right=&h5;h3.Left=&h6;h3.Right=&h7;root:=&h1
	fmt.Println("LNR:")
	LNR(root)
	LNR_Loop(root)
	LNR_Morris(root)
	fmt.Println("NLR:")
	NLR(root)
	NLR_Loop(root)
	NLR_Morris(root)
	fmt.Println("LRN:")
	LRN(root)
	LRN_Loop(root)
	LRN_Loop2(root)
	LRN_Morris(root)
}

```