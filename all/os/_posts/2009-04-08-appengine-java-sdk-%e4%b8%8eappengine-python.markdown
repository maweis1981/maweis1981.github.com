--- 
wordpress_id: 436
layout: post
title: "appengine-java-sdk \xE4\xB8\x8Eappengine python"
wordpress_url: http://maweis.com/?p=436
---
今天试用了一下google新发布的appengine-java-sdk。

总体感觉没什么新意，只是一个servlet容器，使用JDO，JPA这个我很纳闷，为什么不用hibernate呢，至少这个目前还是市场占有率最高的持久层解决方案。

memcache，email，image，user这些和python版本的也差不多。

回到语言问题上来，开发同样的应用python的工作量要比java的小很多，这次1.2版本的提供了一个zip文件，连tar.gz 都没搞一个，让我觉得好像是中国团队开发的。然后采用ant没有使用maven我也很不爽，这个当然应该用maven来从appengine的官方服务器上直接down depend lib。

总体让我感觉就是比当前的java应用落后很多。

如果这个云计算平台同时也实现了osgi，那倒是很有意思，大家开发的组件可以串在一起玩，有点像前些年热推的构件开发。

有现有的java开发的应用部署到appengien上还是一个不错的选择，但是重新开发新的，我还是建议采用python版本的，至少减少你来回切换文件的次数。
