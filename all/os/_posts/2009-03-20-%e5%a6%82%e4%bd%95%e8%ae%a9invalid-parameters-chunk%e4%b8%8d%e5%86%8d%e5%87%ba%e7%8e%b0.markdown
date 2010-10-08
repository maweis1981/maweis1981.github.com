--- 
wordpress_id: 420
layout: post
title: !binary |
  5aaC5L2V6K6pSW52YWxpZCBQYXJhbWV0ZXJzIENodW5r5LiN5YaN5Ye6546w

wordpress_url: http://maweis.com/2009/03/20/%e5%a6%82%e4%bd%95%e8%ae%a9invalid-parameters-chunk%e4%b8%8d%e5%86%8d%e5%87%ba%e7%8e%b0/
---
在tomcat的conf目录里有个文件，名字叫做
logging.properties

在这个文件的最底下加一行配置
org.apache.tomcat.util.http.Parameters.level=SEVERE

问题就解决了，清净了，tomcat5，6 以前的版本请到jdk目录中增加配置。
