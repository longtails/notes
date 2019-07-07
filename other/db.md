### DB的基本操作

交、并、差、笛卡尔积；
选择、投影、连接（笛卡尔积的进一步）、除；

数据查询

select [distinct] */col1,col2,col3...
from table/view [as aliasname]
where
groupby [col1] having    --聚集函数
order by [col2] asc|desc;

查询条件

比较 =,!=,<,>,...
范围 between and,not between and
集合 in,not in
字符串匹配 like,not like
控制 is null, is not null
多重条件 and,or,not


聚集函数：
count(*)
count(distinct |all col1)
sumdistinct |all col1)
avg(distinct |all col1)
max(distinct |all col1)
min(distinct |all col1)


where子句中不能用用聚集函数作为条件表达式的，聚集函数只能用于select子句和group中的having子句

groupby将查询的结果按某一列或者多列的值分组，值相等的为一组

查询各课程选修的人数
select cno,count(sno)
from sc
group by cno

查询选修了三门以上课程的学生的学号

select sno
from sc
group by sno
having count(*)>3;
先用group by 子句按sno进行分组，再用聚集函数count对每一组技术；having给出了选择组的条件。

where子句与having短语的区别在于作用对象不同，where子句作用域基本表或试图，从中选择满足条件的元祖。
having短语作用于组，从中选择满足条件的组。

查询平均成绩大于等于90分的学生学号和平均成绩

select sno,avg(grade)
from sc
group by sno
having avg(grade)>90;


连接查询：等值于非等值连接

select student.*,sc.*   ->改成自然连接，就是这里把显示输出不重复的 //select student.sno,sname,ssex,sage,sdept,cno,grade
from student.sc
where student.sno=sc.sno;

在数据库中连接操作的一种可能过程：现在学生表中找到第一个元组，然后扫描第二个表，将于student元组sno相等的拼接，扫描完第二个表；再接着扫描第一个表的下一个元组，同样的操作。--->思想就是嵌套循环连接算法的基本思想。



自身连接

比如查所有课程的先修课程

select first.cno,second.cpno
from course first,course second 
where firet.cpno=second.cno

外连接：

在通常的连接操作中，只有满足连接条件的元组才能作为结果输出，但是一旦一个表中缺失信息，那连接条件不满足，就会被舍弃

外连接，可以把student的悬浮元组保存在结果关系中。

select student,sno,sname,ssex,sage,sdept,cno,grade
from student left outer join sc on(student.sno=sc.sno)

也可以使用using去掉结果中的重复值：from sutdent left outer join sc using(sno);

多表连接：...

嵌套查询：
select name
from student
where sno in
(select sno from sc where cno='2')

select-from-where称为一个查询块，将一个查询块套在另一个查询块的where子句或having短语的条件中的查询称为嵌套查询。
子查询的select语句不能使用order by子句，orderer by子句只能对最终查询结果排序。

子查询谓词：IN,

子查询的查询条件不依赖于父查询，称为不相关子查询；
子查询的查询条件依赖于父查询，称为相关子查询。

带有比较运算符的子查询

select sno,cno
from sc x
where grade>=(select avg(grade) from sc y where y.sno=x.sno)

带有any(some)或all谓词的子查询

查询非计算机专业比计算机专业任意学生年龄小的学生姓名和年龄

select sname,sage
from student
where sage < any
(select sage from student where sdep='cs') and sdep !='cs';


带有EXISTS谓词的子查询，存在量词

select sname 
from sutdent
where exists/not exists
( select * from sc where sno=student.sno and cno='1' )

集合查询

select sno from sc where cno='1'
union/intersect/except
select sno from sc where cno='2'

基于派生表的查询

select sno,cno
from sc,(select sno,avg(grade) from sc group by sno) as avg_sc(avg_sno,avg_grade)

数据更新

insert  into tableA[col1,col2]
values (val1,val2)

insert
into student(sno,sname,ssex)
values('2018','abc','man')

插入子查询结果

insert into table[(col1,col2,...)]
子查询

insert into dept_age(sdep,avg_age)
select sdep,avg(sage)
from student 
group by sdept;

修改数据
update table
set cols=vals
where 

update student
set age=22
where sno='2018';

修改多个值，所有学生年龄加1
update student
set age=age+1;

删除

delete 
from table
where 条件。

delete from student where sno='2018'

删除多个元组的值

delete from sc;

带有子查询的删除

delete from sc
where sno in
( select sno from student where sdep='cs');

空值处理：NULL

insert into sc(sno,cno,grade)
values('2015','1',NULL);

update student
set sdep=NULL
where sno=2015'

控制判断 IS NULL, IS NOT NULL


视图

create view name [(col1,col2,...)]
as <子查询>
[with check option]

with check 表示对视图进行update,insert,delete操作时要保证更新、插入、删除的行满足视图定义中的谓词条件。

删除
drop view name [cascade];级联删除由它导出的所有视图。

更新
update is_student
set sname='abc'
where sno='2018';

insert into is_student
values('2018','abc',20);

delete from is_student where sno='2018';








---


### 176. 第二高的薪水

```
编写一个 SQL 查询，获取 Employee 表中第二高的薪水（Salary） 。

+----+--------+
| Id | Salary |
+----+--------+
| 1  | 100    |
| 2  | 200    |
| 3  | 300    |
+----+--------+
例如上述 Employee 表，SQL查询应该返回 200 作为第二高的薪水。如果不存在第二高的薪水，那么查询应返回 null。

+---------------------+
| SecondHighestSalary |
+---------------------+
| 200                 |
+---------------------+

```

select if(sva=1,"男","女") as ssva from taname where id = '111';

IFNULL(expr1,expr2)

SELECT * FROM table  LIMIT [offset,] rows | rows OFFSET offset;
mysql> SELECT * FROM orange LIMIT 5;     //检索前5条记录(1-5)
mysql> SELECT * from orange LIMIT 0,5;  
两个参数，第一个参数表示offset, 第二个参数为记录数。

