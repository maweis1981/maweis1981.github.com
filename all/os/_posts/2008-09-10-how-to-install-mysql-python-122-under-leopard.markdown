--- 
wordpress_id: 242
layout: post
title: How to install MySQL-python-1.2.2 under Leopard?
wordpress_url: http://maweis.com/?p=242
---
You are choose two way:
1,easy_install
2,download the MySQL-python1.2.2.tar.gz to manual build &amp; install.

remember if you choose the second way,you need to remove the

"_mysql.c" Line 38

and then do build operation, well, you should be install xcode first because we need GCC to compile.
