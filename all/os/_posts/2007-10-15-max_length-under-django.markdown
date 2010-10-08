--- 
wordpress_id: 123
layout: post
title: "'max_length' Under Django"
wordpress_url: http://maweis.com/index.php/archives/123.html
---
<p>早上写程序的时候忽然发现原来运行正常的程序竟然有了错误：</p>  <p>TypeError: __init__() got an unexpected keyword argument 'max_length'</p>  <p>不禁有些诧异，找来找去也没发现问题，就像最近作了什么？于是大抵也就是从svn更新了一份新的而已。</p>  <p>于是就到邮件列表里去翻了一下，原来是django 开发者改了变量名称，</p>  <p>原来定义数据类型的时候，CharField的最大长度用max_length定义，而我更新的最新版本改成maxlength了，</p>  <p>不知道是作者笔误还是其他什么意思。</p>  <p>&#xA0;</p>  <p>将max_length改成maxlength就好了。</p>
