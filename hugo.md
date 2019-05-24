### hugo


部署过程要在site的根目录进行 
 ```bash
 #/content/post/test.md
 hugo new post/test.md

 #build drafts,the theme is m10c
 hugo server -t=m10c --buildDrafts


```


```bash
liudeMacBook-Pro:site liu$ hugo -t=m10c --buildDrafts  --baseUrl="https://scylhy.github.io/" 

                   | EN  
-------------------+-----
  Pages            | 12  
  Paginator pages  |  0  
  Non-page files   |  0  
  Static files     |  1  
  Processed images |  0  
  Aliases          |  4  
  Sitemaps         |  1  
  Cleaned          |  0  

Total in 21 ms
liudeMacBook-Pro:site liu$ 

liudeMacBook-Pro:site liu$ ls
archetypes  config.toml content     data        layouts     public      resources   static      theme.toml  themes
```



创建github仓库，仓库名字为scylhy/github.io

```bash
echo "# scylhy.github.io" >> README.md
git init
git add README.md
git commit -m "first commit"
git remote add origin https://github.com/scylhy/scylhy.github.io.git
git push -u origin master
```



有个问题，就是博客的迁移，怎么处理添加config参数？


还需要找到合适的博客主题要求有分类、有导航、界面简介。
目前有个wordpress可尝试。