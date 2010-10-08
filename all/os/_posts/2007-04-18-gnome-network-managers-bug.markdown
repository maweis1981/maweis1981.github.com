--- 
wordpress_id: 51
layout: post
title: Gnome Network Manager'S Bug
wordpress_url: http://maweis.com/?p=51
---
Gnome Network Manager的wifi有一个bug，无法自动追加restricted字符到wireless-key后面

所以如果你的wifi是非开放式的，请在你的/etc/network/interface中的wireless-key后面跟上restricted

iface eth1 inet dhcp
wireless-essid ByReadWLAN
wireless-key $ourpassword$ <strong>restricted</strong>
