--- 
wordpress_id: 558
layout: post
title: !binary |
  c25vdyBsZW9wYXJkIHN0YXJ0IDY0Yml0IOmFjee9ruWQr+WKqOWIsDY05L2N
  5qih5byP

wordpress_url: http://maweis.com/index.php/2009/12/02/snow-leopard-start-64bit-%e9%85%8d%e7%bd%ae%e5%90%af%e5%8a%a8%e5%88%b064%e4%bd%8d%e6%a8%a1%e5%bc%8f/
---
/Library/Preferences/SystemConfiguration/com.apple.Boot.plist

find there:

<key>Kernel Flags</key>
<string></string>

and change it to

<key>Kernel Flags</key>
<string>arch=x86_64</string>
