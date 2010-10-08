--- 
wordpress_id: 523
layout: post
title: app crash report
wordpress_url: http://maweis.com/index.php/2009/09/08/app-crash-report/
---
#
# An unexpected error has been detected by HotSpot Virtual Machine:
#
#  SIGSEGV (0xb) at pc=0x00a83a60, pid=2939, tid=1430170528
#
# Java VM: Java HotSpot(TM) Server VM (1.5.0_05-b05 mixed mode)
# Problematic frame:
# C  [libpthread.so.0+0x8a60]  pthread_kill+0x10
#
# Can not save log file, dump to screen..
#
# An unexpected error has been detected by HotSpot Virtual Machine:
#
#  SIGSEGV (0xb) at pc=0x00a83a60, pid=2939, tid=1430170528
#
# Java VM: Java HotSpot(TM) Server VM (1.5.0_05-b05 mixed mode)
# Problematic frame:
# C  [libpthread.so.0+0x8a60]  pthread_kill+0x10
#

---------------  T H R E A D  ---------------

Current thread (0x587e1b78):  JavaThread "MaintThread" daemon [_thread_in_native, id=27186]

siginfo:si_signo=11, si_errno=0, si_code=1, si_addr=0x4ac9ebe8

Registers:
EAX=0x4ac9eba0, EBX=0x67538c30, ECX=0x08767f00, EDX=0x00000003
ESP=0x553e9b08, EBP=0x553e9b10, ESI=0x0000003d, EDI=0x587e1b78
EIP=0x00a83a60, CR2=0x4ac9ebe8, EFLAGS=0x00010216

Top of Stack: (sp=0x553e9b08)
0x553e9b08:   6f142ce8 587e1b78 553e9b30 675375d7
0x553e9b18:   4ac9eba0 0000003d 6f142ce8 6f142ce8
0x553e9b28:   587e1b78 6f142ce8 553e9b64 b26d9838
0x553e9b38:   587e1c34 553e9b6c 4ac9eba0 00000000
0x553e9b48:   553e9b48 6f142ce8 553e9b78 6f142fb8
0x553e9b58:   00000000 6f142ce8 553e9b74 553e9ba0
0x553e9b68:   b26d3aeb 6f142f60 b26d7639 4ac9eba0
0x553e9b78:   00000000 00000001 73904fc0 553e9b7c 

Instructions: (pc=0x00a83a60)
0x00a83a50:   55 ba 03 00 00 00 89 e5 57 8b 45 08 56 8b 75 0c
0x00a83a60:   8b 48 48 85 c9 7e 4b 8d 7e e0 ba 16 00 00 00 83 

Stack: [0x5536a000,0x553eb000),  sp=0x553e9b08,  free space=510k
Native frames: (J=compiled Java code, j=interpreted, Vv=VM code, C=native code)
C  [libpthread.so.0+0x8a60]  pthread_kill+0x10
C  [libnio.so+0x55d7]  Java_sun_nio_ch_NativeThread_signal+0x27
j  sun.nio.ch.NativeThread.signal(J)V+0
j  sun.nio.ch.SocketChannelImpl.implCloseSelectableChannel()V+39

Java frames: (J=compiled Java code, j=interpreted, Vv=VM code)
j  sun.nio.ch.NativeThread.signal(J)V+0
j  sun.nio.ch.SocketChannelImpl.implCloseSelectableChannel()V+39
v  ~C2IAdapter
J  java.nio.channels.spi.AbstractSelectableChannel.implCloseChannel()V
v  ~I2CAdapter
j  java.nio.channels.spi.AbstractInterruptibleChannel.close()V+23
j  sun.nio.ch.ChannelInputStream.close()V+4
j  java.io.FilterInputStream.close()V+4
j  com.danga.MemCached.SockIOPool$SockIO.trueClose(Z)V+85
j  com.danga.MemCached.SockIOPool$SockIO.trueClose()V+2
j  com.danga.MemCached.SockIOPool.clearHostFromPool(Ljava/util/Map;Ljava/lang/String;)V+64
j  com.danga.MemCached.SockIOPool.createSocket(Ljava/lang/String;)Lcom/danga/MemCached/SockIOPool$SockIO;+398
v  ~C2IAdapter
J  com.danga.MemCached.SockIOPool.selfMaint()V
J  com.danga.MemCached.SockIOPool$MaintThread.run()V
v  ~OSRAdapter
v  ~StubRoutines::call_stub

---------------  P R O C E S S  ---------------
