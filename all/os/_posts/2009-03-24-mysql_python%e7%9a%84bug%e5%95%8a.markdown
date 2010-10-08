--- 
wordpress_id: 423
layout: post
title: "mysql_python\xE7\x9A\x84bug\xE5\x95\x8A"
wordpress_url: http://maweis.com/2009/03/24/mysql_python%e7%9a%84bug%e5%95%8a/
---
[root@chongwu ~]# easy_install-2.6 MySQL_python-1.2.3b2-py2.6-linux-i686.egg 
Processing MySQL_python-1.2.3b2-py2.6-linux-i686.egg
Removing /usr/local/lib/python2.6/site-packages/MySQL_python-1.2.3b2-py2.6-linux-i686.egg
Copying MySQL_python-1.2.3b2-py2.6-linux-i686.egg to /usr/local/lib/python2.6/site-packages
MySQL-python 1.2.3b2 is already the active version in easy-install.pth

Installed /usr/local/lib/python2.6/site-packages/MySQL_python-1.2.3b2-py2.6-linux-i686.egg
Processing dependencies for MySQL-python==1.2.3b2
Searching for MySQL-python==1.2.3b2
Reading http://pypi.python.org/simple/MySQL-python/
Reading http://sourceforge.net/projects/mysql-python
Reading http://sourceforge.net/projects/mysql-python/
Best match: MySQL-python 1.2.3b2
Downloading http://osdn.dl.sourceforge.net/sourceforge/mysql-python/MySQL-python-1.2.3b2.tar.gz
Processing MySQL-python-1.2.3b2.tar.gz
Running MySQL-python-1.2.3b2/setup.py -q bdist_egg --dist-dir /tmp/easy_install-fhEEVz/MySQL-python-1.2.3b2/egg-dist-tmp-GX2gO2
在包含自 /usr/local/include/python2.6/Python.h：58 的文件中，
                 从 pymemcompat.h：10，
                 从 _mysql.c：29:
/usr/local/include/python2.6/pyport.h:685:2: 错误：#error "LONG_BIT definition appears wrong for platform (bad gcc/glibc config?)."
在包含自 _mysql.c：35 的文件中:
/usr/include/mysql/my_config.h:1104:1: 警告：“SIZEOF_LONG”重定义
在包含自 /usr/local/include/python2.6/Python.h：8 的文件中，
                 从 pymemcompat.h：10，
                 从 _mysql.c：29:
/usr/local/include/python2.6/pyconfig.h:889:1: 警告：这是先前定义的位置
error: Setup script exited with error: command 'gcc' failed with exit status 1
[root@chongwu ~]# 
