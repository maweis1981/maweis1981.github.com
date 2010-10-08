--- 
wordpress_id: 211
layout: post
title: how to resolve JVM error when ubuntu upgrade to 8.04 hardy?
wordpress_url: http://maweis.com/index.php/archives/211.html
---
<p>I found my IDEA could not start when I upgrade ubuntu to 8.04 (hardy).</p><p>
peter@margaret:/opt/tools/idea-7364/bin$ ./idea.sh </p><p>
Locking assertion failure.  Backtrace:</p><p>
#0 /usr/lib/libxcb-xlib.so.0 [0xa1679767]</p><p>
#1 /usr/lib/libxcb-xlib.so.0(xcb_xlib_unlock+0x31) [0xa16798b1]</p><p>
#2 /usr/lib/libX11.so.6(_XReply+0xfd) [0xa16ce29d]</p><p>
#3 /usr/lib/jvm/java-6-sun-1.6.0.04/jre/lib/i386/xawt/libmawt.so [0xa17d28ce]</p><p>
#4 /usr/lib/jvm/java-6-sun-1.6.0.04/jre/lib/i386/xawt/libmawt.so [0xa17af067]</p><p>
#5 /usr/lib/jvm/java-6-sun-1.6.0.04/jre/lib/i386/xawt/libmawt.so [0xa17af318]</p><p>
#6 /usr/lib/jvm/java-6-sun-1.6.0.04/jre/lib/i386/xawt/libmawt.so(Java_sun_awt_X11GraphicsEnvironment_initDisplay+0x2f) [0xa17af61f]</p><p>
#7 [0xb5c6ce9d]</p><p>
#8 [0xb5c65edd]</p><p>
#9 [0xb5c65edd]</p><p>
#10 [0xb5c63249]</p><p>
#11 /usr/lib/jvm/java-6-sun-1.6.0.04/jre/lib/i386/client/libjvm.so [0x621c40d]</p><p>
#12 /usr/lib/jvm/java-6-sun-1.6.0.04/jre/lib/i386/client/libjvm.so [0x6310378]</p><p>
#13 /usr/lib/jvm/java-6-sun-1.6.0.04/jre/lib/i386/client/libjvm.so [0x621c2a0]</p><p>
#14 /usr/lib/jvm/java-6-sun-1.6.0.04/jre/lib/i386/client/libjvm.so(JVM_DoPrivileged+0x363) [0x6272153]</p><p>
#15 /usr/lib/jvm/java-6-sun-1.6.0.04/jre/lib/i386/libjava.so(Java_java_security_AccessController_doPrivileged__Ljava_security_PrivilegedAction_2+0x3d) [0xb7c7e96d]</p><p>
#16 [0xb5c6ce9d]</p><p>
#17 [0xb5c65d77]</p><p>
#18 [0xb5c63249]</p><p>
#19 /usr/lib/jvm/java-6-sun-1.6.0.04/jre/lib/i386/client/libjvm.so [0x621c40d]</p><p>
java: xcb_xlib.c:82: xcb_xlib_unlock: Assertion `c->xlib.lock' failed.</p><p>
Aborted (core dumped)</p><p>
peter@margaret:/opt/tools/idea-7364/bin$ </p><p>
-----------------------------------------------------------------------------------------------------------------------------------------------------</p><p>
so, you need execute the follow command:</p><p>
peter@margaret:/opt/tools/idea-7364/bin$ sudo sed -i 's/XINERAMA/FAKEEXTN/g' /usr/lib/jvm/java-6-sun/jre/lib/i386/xawt/libmawt.so</p><p>
peter@margaret:/opt/tools/idea-7364/bin$ ./idea.sh </p><p>
-----------------------------------------------------------------------------------------------------------------------------------------------------</p><p>
everything works normal.</p><p>
</p><p>
thanks.</p><p>
</p>
