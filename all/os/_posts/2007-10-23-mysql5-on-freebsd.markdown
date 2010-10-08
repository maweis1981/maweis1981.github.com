--- 
wordpress_id: 135
layout: post
title: mysql5 on FreeBSD
wordpress_url: http://maweis.com/index.php/archives/135.html
---
<p>使用ports安装mysql5.0</p>  <p>portinstall databases/mysql50-server</p>  <p>portinstall databases/mysql50-client</p>  <p>安装db</p>  <p>/usr/local/bin/mysql_install_db</p>  <p>chown -R mysql /var/db/mysql</p>  <p>rehash</p>  <p>增加mysql到系统启动选项</p>  <p>add mysql_enable=&quot;YES&quot; to&#xA0;&#xA0; /etc/rc.conf</p>  <p>重启</p>  <p>reboot</p>  <p>修改密码</p>  <p>/usr/local/bin/mysqladmin -u root password 'your_password'</p>
