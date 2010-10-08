--- 
wordpress_id: 215
layout: post
title: more TIME_WAIT , apache leak
wordpress_url: http://maweis.com/index.php/archives/215.html
---
vi /etc/sysctl.conf
编辑/etc/sysctl.conf文件，增加三行：
<h6>net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1</h6>
<h6>net.ipv4.tcp_tw_recycle = 1</h6>
说明：　　net.ipv4.tcp_syncookies = 1 表示开启SYN Cookies。当出现SYN等待队列溢出时，启用cookies来处理，可防范少量SYN攻击，默认为0，表示关闭；
　　net.ipv4.tcp_tw_reuse = 1 表示开启重用。允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；
　　net.ipv4.tcp_tw_recycle = 1 表示开启TCP连接中TIME-WAIT sockets的快速回收，默认为0，表示关闭。

　　再执行以下命令，让修改结果立即生效：
　　/sbin/sysctl -p

　　用以下语句看了一下服务器的TCP状态：
　　netstat -n | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'

　　返回结果如下：

LAST_ACK 2
SYN_RECV 6
CLOSE_WAIT 2
ESTABLISHED 174
FIN_WAIT1 6
FIN_WAIT2 25
CLOSING 6
TIME_WAIT 584
