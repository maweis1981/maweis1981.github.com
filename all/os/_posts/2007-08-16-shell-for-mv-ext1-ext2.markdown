--- 
wordpress_id: 101
layout: post
title: shell for mv *.ext1 *.ext2
wordpress_url: http://maweis.com/?p=101
---
<pre>
ls -d *.php|sed -e 's/.*/mv & &/' -e 's/php$/jpg/' |sh
</pre>
