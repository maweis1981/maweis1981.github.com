--- 
wordpress_id: 448
layout: post
title: !binary |
  VG9nZ2xlU2lsZW50IGJldGHniYjmnKzlj5HluIPkuoY=

wordpress_url: http://maweis.com/?p=448
---
我是上周四编译好android cupcake 的，这周一早上拿到我的ADP-1(Android Dev Phone 1)的，去年就付了25美金的 developer license，一直没人从美国回来，找了我老师，想让她帮忙寄，老人家说寄会丢的；找了出差在美国的朋友又因为ship地址无法是hotel，于是一直拖到morgan同学从中国回美国，又恰好近期又要回国，所以在等待了一个季度之后，我终于拿到了，还是我同事去广州给捎回来的。

拿到手第一件事就是upgrade，立刻就升级到firmware 1.1。

甚是喜欢，一直把玩。

要说我运气好，这还一点都不假，睡了一觉起来赶紧看电量，因为在过年前曾经买过一个T-mobile G1，充满电，把功能设备全关，第二天早上醒来一看已经没电自动关机了，而且我还是夜里12点才睡，早上6点半就醒的。

这次没让我失望，睡前电量58，醒来47，很满意。不知道是电池问题还是系统升级后的原因。

于是看邮件，wow，更加开心的事情也发生了，夜里android 已经发布了1.5的正式版，太开心了，上班后第一件事就是升级啊，升级，我是不求最好，但求最新，就像当初把1.5的psp刷成砖那次一样。哈哈。

不过这次没那么惨，一切顺利，系统已经升级到1.5了。这次不是cupcake了，就是android 1.5。

然后就开始开发应用玩了，第一个自然是和公司相关的产品阅读器了，由于前期我已经加入coolreader开发组，于是便把coolreader project中的textview修改成自定义的readerView来实现。

还有一个就是今天早上做的，ToggleSilent，开启此程序后，将手机屏幕朝下放，就自动切换成无声模式，以后就不用我每晚修改手机情景模式了，哈哈哈，Android里也没情景模式一说，是Sound &amp; display。

也不用预先设定声音计划，我要的就是反着放你丫就别给我响，不过还有一个问题的就是此程序目前在后台运行时就无法监听，于是查sdk文档得知原来要定义一个Service，然后和Activity进行bind，试过之后跑了leaked 错误，目前还在研究中。

为了尽早release一个产品到Android Market上去，我不得不把这个feature放到第二版，哈哈。
