--- 
wordpress_id: 413
layout: post
title: RescueTime [80477] carsh report
wordpress_url: http://maweis.com/2009/03/16/rescuetime-80477-carsh-report/
---

Process:         RescueTime [80477]
Path:            /Applications/RescueTime.app/Contents/MacOS/RescueTime
Identifier:      com.rescuetime.RescueTime
Version:         2.0.0 (2.0.0.322)
Code Type:       X86 (Native)
Parent Process:  launchd [221]

Date/Time:       2009-03-17 15:06:03.701 +0800
OS Version:      Mac OS X 10.5.5 (9F33)
Report Version:  6

Exception Type:  EXC_CRASH (SIGABRT)
Exception Codes: 0x0000000000000000, 0x0000000000000000
Crashed Thread:  1

Thread 0:
0   libSystem.B.dylib             	0x908a04a6 mach_msg_trap + 10
1   libSystem.B.dylib             	0x908a7c9c mach_msg + 72
2   com.apple.CoreFoundation      	0x945340ce CFRunLoopRunSpecific + 1790
3   com.apple.CoreFoundation      	0x94534cf8 CFRunLoopRunInMode + 88
4   com.apple.HIToolbox           	0x92cd6480 RunCurrentEventLoopInMode + 283
5   com.apple.HIToolbox           	0x92cd6299 ReceiveNextEventCommon + 374
6   com.apple.HIToolbox           	0x92cd610d BlockUntilNextEventMatchingListInMode + 106
7   com.apple.AppKit              	0x969a83ed _DPSNextEvent + 657
8   com.apple.AppKit              	0x969a7ca0 -[NSApplication nextEventMatchingMask:untilDate:inMode:dequeue:] + 128
9   com.apple.AppKit              	0x969a0cdb -[NSApplication run] + 795
10  com.rescuetime.RescueTime     	0x000445e1 0x1000 + 275937
11  com.rescuetime.RescueTime     	0x00043675 0x1000 + 271989
12  com.rescuetime.RescueTime     	0x0003139f 0x1000 + 197535
13  com.rescuetime.RescueTime     	0x00024c7c 0x1000 + 146556
14  com.rescuetime.RescueTime     	0x000029d6 0x1000 + 6614

Thread 1 Crashed:
0   libSystem.B.dylib             	0x90973c4a usleep$NOCANCEL$UNIX2003 + 0
1   libSystem.B.dylib             	0x9099548b abort + 85
2   com.rescuetime.RescueTime     	0x000c1bb1 0x1000 + 789425
3   com.rescuetime.RescueTime     	0x000c03b4 boost::gregorian::bad_day_of_month::~bad_day_of_month() + 320340
4   com.rescuetime.RescueTime     	0x000c03f3 boost::gregorian::bad_day_of_month::~bad_day_of_month() + 320403
5   com.rescuetime.RescueTime     	0x0006d8d9 (anonymous namespace)::system_error_category::~system_error_category() + 4281
6   libSystem.B.dylib             	0x908d16f5 _pthread_start + 321
7   libSystem.B.dylib             	0x908d15b2 thread_start + 34

Thread 2:
0   libSystem.B.dylib             	0x908a768e __semwait_signal + 10
1   libSystem.B.dylib             	0x908fdc59 sleep$UNIX2003 + 63
2   com.rescuetime.RescueTime     	0x00002d35 0x1000 + 7477
3   com.rescuetime.RescueTime     	0x00025191 0x1000 + 147857
4   com.rescuetime.RescueTime     	0x0006d79d (anonymous namespace)::system_error_category::~system_error_category() + 3965
5   libSystem.B.dylib             	0x908d16f5 _pthread_start + 321
6   libSystem.B.dylib             	0x908d15b2 thread_start + 34

Thread 3:
0   libSystem.B.dylib             	0x908a768e __semwait_signal + 10
1   libSystem.B.dylib             	0x908fdc59 sleep$UNIX2003 + 63
2   com.rescuetime.RescueTime     	0x00002d9a 0x1000 + 7578
3   com.rescuetime.RescueTime     	0x00025191 0x1000 + 147857
4   com.rescuetime.RescueTime     	0x0006d79d (anonymous namespace)::system_error_category::~system_error_category() + 3965
5   libSystem.B.dylib             	0x908d16f5 _pthread_start + 321
6   libSystem.B.dylib             	0x908d15b2 thread_start + 34

Thread 4:
0   libSystem.B.dylib             	0x908a0506 semaphore_timedwait_signal_trap + 10
1   libSystem.B.dylib             	0x908d284f _pthread_cond_wait + 1244
2   libSystem.B.dylib             	0x908d40d3 pthread_cond_timedwait_relative_np + 47
3   com.apple.Foundation          	0x900fbb1c -[NSCondition waitUntilDate:] + 236
4   com.apple.Foundation          	0x900fb930 -[NSConditionLock lockWhenCondition:beforeDate:] + 144
5   com.apple.Foundation          	0x900fb895 -[NSConditionLock lockWhenCondition:] + 69
6   com.apple.AppKit              	0x96a0e358 -[NSUIHeartBeat _heartBeatThread:] + 753
7   com.apple.Foundation          	0x900b5bad -[NSThread main] + 45
8   com.apple.Foundation          	0x900b5754 __NSThread__main__ + 308
9   libSystem.B.dylib             	0x908d16f5 _pthread_start + 321
10  libSystem.B.dylib             	0x908d15b2 thread_start + 34

Thread 5:
0   libSystem.B.dylib             	0x908a768e __semwait_signal + 10
1   libSystem.B.dylib             	0x908fdc59 sleep$UNIX2003 + 63
2   com.rescuetime.RescueTime     	0x0003f028 0x1000 + 253992
3   com.apple.Foundation          	0x900b5bad -[NSThread main] + 45
4   com.apple.Foundation          	0x900b5754 __NSThread__main__ + 308
5   libSystem.B.dylib             	0x908d16f5 _pthread_start + 321
6   libSystem.B.dylib             	0x908d15b2 thread_start + 34

Thread 1 crashed with X86 Thread State (32-bit):
  eax: 0x00000000  ebx: 0x9099543f  ecx: 0xb00a0e3c  edx: 0x9090eb9e
  edi: 0xa00d0578  esi: 0x165b41fc  ebp: 0xb00a0ea8  esp: 0xb00a0e7c
   ss: 0x0000001f  efl: 0x00010282  eip: 0x90973c4a   cs: 0x00000017
   ds: 0x0000001f   es: 0x0000001f   fs: 0x0000001f   gs: 0x00000037
  cr2: 0x002211dc

Binary Images:
    0x1000 -    0xfefe6 +com.rescuetime.RescueTime 2.0.0 (2.0.0.322) <38529650764e3f59bf7fd51ed3a3b788> /Applications/RescueTime.app/Contents/MacOS/RescueTime
  0x13f000 -   0x16affb  libcurl.4.dylib ??? (???) <54ada27deb3b4ff7043d8836264eca0d> /usr/lib/libcurl.4.dylib
  0x174000 -   0x174ff8  com.apple.AppKitScripting 6.1 (31) <719b099a76e8be506d85db4975a1451e> /System/Library/Frameworks/AppKitScripting.framework/Versions/A/AppKitScripting
  0x178000 -   0x18bfff +org.andymatuschak.Sparkle 1.5 Beta (bzr) (1.5) <c80905489e87b252620f67537812fa06> /Applications/RescueTime.app/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle
  0x1cd000 -   0x1cdffe  com.apple.applescript.component 2.0.1 (2.0.1) /System/Library/Components/AppleScript.component/Contents/MacOS/AppleScript
  0x373000 -   0x3e0fff +com.DivXInc.DivXDecoder 6.6.0 (6.6.0) /Library/QuickTime/DivX Decoder.component/Contents/MacOS/DivX Decoder
  0x3ef000 -   0x476feb  com.apple.applescript 2.0.1 (2.0.1) /System/Library/PrivateFrameworks/AppleScript.framework/Versions/A/AppleScript
  0x5aa000 -   0x5abffa +com.google.GearsEnabler ??? (1.0) <f4619f1c37ae37dfdf6af70894fa2776> /Library/InputManagers/GearsEnabler/GearsEnabler.bundle/Contents/MacOS/GearsEnabler
0x1593c000 - 0x15a5aff7  com.apple.RawCamera.bundle 2.0.7 (2.0.7) /System/Library/CoreServices/RawCamera.bundle/Contents/MacOS/RawCamera
0x163b4000 - 0x163dcff4  com.apple.osax.standardadditions 2.0 (???) <5ae299986564570534c5d92afff168a6> /System/Library/ScriptingAdditions/StandardAdditions.osax/Contents/MacOS/StandardAdditions
0x163e9000 - 0x163f3ffe  com.apple.URLMount 3.1.1 (3.1.1) <b4018e683fad4259ee78070e91f35029> /System/Library/PrivateFrameworks/URLMount.framework/Versions/A/URLMount
0x163fb000 - 0x1643afff  com.apple.AppleShareClientCore 1.6.1 (1.6.1) <9efff94ea7a828edf4e050b8843cd018> /System/Library/Frameworks/AppleShareClientCore.framework/Versions/A/AppleShareClientCore
0x1644d000 - 0x16460fff  com.apple.AppleShareClient 1.6.1 (1.6.1) <4e1e7472e3e64ee8de1a53e61924436c> /System/Library/Frameworks/AppleShareClient.framework/Versions/A/AppleShareClient
0x1646c000 - 0x16476ffc  com.apple.framework.AppleTalk 1.2.0 (???) <e0f5f336ad29ca635740ed8b83061234> /System/Library/Frameworks/AppleTalk.framework/Versions/A/AppleTalk
0x8fe00000 - 0x8fe2da53  dyld 96.2 (???) <c254337fa28c7eacb3d3e1d56aa141a4> /usr/lib/dyld
0x90003000 - 0x900aafeb  com.apple.QD 3.11.54 (???) <b743398c24c38e581a86e91744a2ba6e> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/QD.framework/Versions/A/QD
0x900ab000 - 0x90326fe7  com.apple.Foundation 6.5.6 (677.21) <5cfa0aa8b9b43193955d601ba6c2591a> /System/Library/Frameworks/Foundation.framework/Versions/C/Foundation
0x90460000 - 0x90478fff  com.apple.openscripting 1.2.8 (???) <572c7452d7e740e8948a5ad07a99602b> /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/OpenScripting.framework/Versions/A/OpenScripting
0x90479000 - 0x9050cfff  com.apple.ink.framework 101.3 (86) <bf3fa8927b4b8baae92381a976fd2079> /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/Ink.framework/Versions/A/Ink
0x9050d000 - 0x90518fe7  libCSync.A.dylib ??? (???) <86d2f2e167ba6f74f45a186f5c7f8980> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/CoreGraphics.framework/Versions/A/Resources/libCSync.A.dylib
0x90550000 - 0x905dcff7  com.apple.LaunchServices 290 (290) <61af37aac50984d220dd176f777e3b72> /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/LaunchServices
0x905dd000 - 0x90626fef  com.apple.Metadata 10.5.2 (398.22) <a6b676925dd832780daf991e79adfebd> /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/Metadata.framework/Versions/A/Metadata
0x90627000 - 0x906aeff7  libsqlite3.0.dylib ??? (???) <6978bbcca4277d6ae9f042beff643f7d> /usr/lib/libsqlite3.0.dylib
0x906af000 - 0x90751ff3  com.apple.QuickTimeImporters.component 7.4.5 (67) /System/Library/QuickTime/QuickTimeImporters.component/Contents/MacOS/QuickTimeImporters
0x9077d000 - 0x907b4fff  com.apple.SystemConfiguration 1.9.2 (1.9.2) <8b26ebf26a009a098484f1ed01ec499c> /System/Library/Frameworks/SystemConfiguration.framework/Versions/A/SystemConfiguration
0x907b5000 - 0x907bdfff  com.apple.DiskArbitration 2.2.1 (2.2.1) <75b0c8d8940a8a27816961dddcac8e0f> /System/Library/Frameworks/DiskArbitration.framework/Versions/A/DiskArbitration
0x907be000 - 0x9089efff  libobjc.A.dylib ??? (???) <7b92613fdf804fd9a0a3733a0674c30b> /usr/lib/libobjc.A.dylib
0x9089f000 - 0x909ffff3  libSystem.B.dylib ??? (???) <3699b292cde73c2847f87c7e1510d87b> /usr/lib/libSystem.B.dylib
0x90a00000 - 0x90a02ff5  libRadiance.dylib ??? (???) <8a844202fcd65662bb9ab25f08c45a62> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/ImageIO.framework/Versions/A/Resources/libRadiance.dylib
0x90a03000 - 0x90ed4f3e  libGLProgrammability.dylib ??? (???) <fe1a33d4919c121aab831ad516da6a89> /System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/libGLProgrammability.dylib
0x90ee8000 - 0x90f26fff  libGLImage.dylib ??? (???) <f0fe2252f6b1ca341bc7837fe2dcf11a> /System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/libGLImage.dylib
0x90f27000 - 0x9105fff7  libicucore.A.dylib ??? (???) <3d8fdaf51c2664ab620f1688203caf26> /usr/lib/libicucore.A.dylib
0x91065000 - 0x9106cffe  libbsm.dylib ??? (???) <d25c63378a5029648ffd4b4669be31bf> /usr/lib/libbsm.dylib
0x9106d000 - 0x91347ff3  com.apple.CoreServices.CarbonCore 786.6 (786.6) <5682aae1e2cf5ae750d5a4dea98c084c> /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/CarbonCore.framework/Versions/A/CarbonCore
0x91348000 - 0x91352feb  com.apple.audio.SoundManager 3.9.2 (3.9.2) <0f2ba6e891d3761212cf5a5e6134d683> /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/CarbonSound.framework/Versions/A/CarbonSound
0x91353000 - 0x9136effb  libPng.dylib ??? (???) <4780e979d35aa5ec2cea22678836cea5> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/ImageIO.framework/Versions/A/Resources/libPng.dylib
0x91493000 - 0x914bbfff  libcups.2.dylib ??? (???) <bddaa132350e872b9d6d8b7e57f204d1> /usr/lib/libcups.2.dylib
0x91697000 - 0x91698ffc  libffi.dylib ??? (???) <a3b573eb950ca583290f7b2b4c486d09> /usr/lib/libffi.dylib
0x916a3000 - 0x91720fef  libvMisc.dylib ??? (???) /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/libvMisc.dylib
0x91721000 - 0x917acfff  com.apple.framework.IOKit 1.5.1 (???) <324526f69e1443f2f9fb722cc88a23ec> /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
0x917ad000 - 0x917fdff7  com.apple.HIServices 1.7.0 (???) <f7e78891a6d08265c83dca8e378be1ea> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/HIServices
0x917fe000 - 0x91822feb  libssl.0.9.7.dylib ??? (???) <c7359b7ab32b5f8574520746e10a41cc> /usr/lib/libssl.0.9.7.dylib
0x91823000 - 0x9182fff9  com.apple.helpdata 1.0.1 (14.2) /System/Library/PrivateFrameworks/HelpData.framework/Versions/A/HelpData
0x91830000 - 0x918aaff8  com.apple.print.framework.PrintCore 5.5.3 (245.3) <222dade7b33b99708b8c09d1303f93fc> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Versions/A/PrintCore
0x9192c000 - 0x919b6fe3  com.apple.DesktopServices 1.4.7 (1.4.7) <d16642ba22c32f67be793ebfbe67ca3a> /System/Library/PrivateFrameworks/DesktopServicesPriv.framework/Versions/A/DesktopServicesPriv
0x919b7000 - 0x91d75fea  libLAPACK.dylib ??? (???) /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/libLAPACK.dylib
0x91d76000 - 0x92113fe7  com.apple.QuartzCore 1.5.5 (1.5.5) <82435993614a3fff1236be18f82188bf> /System/Library/Frameworks/QuartzCore.framework/Versions/A/QuartzCore
0x922a6000 - 0x922acfff  com.apple.print.framework.Print 218.0.2 (220.1) <8bf7ef71216376d12fcd5ec17e43742c> /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/Print.framework/Versions/A/Print
0x922ad000 - 0x9238eff7  libxml2.2.dylib ??? (???) <1baef3d4972ee789d8fa6c1fa44da45c> /usr/lib/libxml2.2.dylib
0x9238f000 - 0x92394fff  com.apple.CommonPanels 1.2.4 (85) <ea0665f57cd267609466ed8b2b20e893> /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/CommonPanels.framework/Versions/A/CommonPanels
0x923ca000 - 0x92495fff  com.apple.ColorSync 4.5.0 (4.5.0) /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/ColorSync.framework/Versions/A/ColorSync
0x92496000 - 0x924d0fe7  com.apple.coreui 1.2 (62) /System/Library/PrivateFrameworks/CoreUI.framework/Versions/A/CoreUI
0x924d1000 - 0x924d1ff8  com.apple.Cocoa 6.5 (???) <e064f94d969ce25cb7de3cfb980c3249> /System/Library/Frameworks/Cocoa.framework/Versions/A/Cocoa
0x924d3000 - 0x9252cff7  libGLU.dylib ??? (???) /System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/libGLU.dylib
0x925fc000 - 0x9262bfe3  com.apple.AE 402.2 (402.2) <e01596187e91af5d48653920017b8c8e> /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/AE.framework/Versions/A/AE
0x9262c000 - 0x926dcfff  edu.mit.Kerberos 6.0.12 (6.0.12) <da7253e3fb7e47e46cb46d47ed320ffc> /System/Library/Frameworks/Kerberos.framework/Versions/A/Kerberos
0x926dd000 - 0x92739ff7  com.apple.htmlrendering 68 (1.1.3) <fe87a9dede38db00e6c8949942c6bd4f> /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HTMLRendering.framework/Versions/A/HTMLRendering
0x9282f000 - 0x92870fe7  libRIP.A.dylib ??? (???) <1f09316e876fe813271bdfb9eb5b229e> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/CoreGraphics.framework/Versions/A/Resources/libRIP.A.dylib
0x92871000 - 0x929b7ff7  com.apple.ImageIO.framework 2.0.4 (2.0.4) <6a6623d3d1a7292b5c3763dcd108b55f> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/ImageIO.framework/Versions/A/ImageIO
0x929c5000 - 0x92a41feb  com.apple.audio.CoreAudio 3.1.0 (3.1) <70bb7c657061631491029a61babe0b26> /System/Library/Frameworks/CoreAudio.framework/Versions/A/CoreAudio
0x92a42000 - 0x92a42ffa  com.apple.CoreServices 32 (32) <2fcc8f3bd5bbfc000b476cad8e6a3dd2> /System/Library/Frameworks/CoreServices.framework/Versions/A/CoreServices
0x92adc000 - 0x92ae5fff  com.apple.speech.recognition.framework 3.7.24 (3.7.24) <d3180f9edbd9a5e6f283d6156aa3c602> /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/SpeechRecognition.framework/Versions/A/SpeechRecognition
0x92bc7000 - 0x92c8eff2  com.apple.vImage 3.0 (3.0) /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vImage.framework/Versions/A/vImage
0x92ca7000 - 0x92faefff  com.apple.HIToolbox 1.5.4 (???) <5e2af960b53059c648af4adb99471032> /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/HIToolbox
0x92faf000 - 0x93009ff7  com.apple.CoreText 2.0.3 (???) <1f1a97273753e6cfea86c810d6277680> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/CoreText.framework/Versions/A/CoreText
0x93055000 - 0x93058fff  com.apple.help 1.1 (36) <b507b08e484cb89033e9cf23062d77de> /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/Help.framework/Versions/A/Help
0x93059000 - 0x93113fe3  com.apple.CoreServices.OSServices 226.5 (226.5) <2a135d4fb16f4954290f7b72b4111aa3> /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/OSServices.framework/Versions/A/OSServices
0x93114000 - 0x93138fff  libxslt.1.dylib ??? (???) <4933ddc7f6618743197aadc85b33b5ab> /usr/lib/libxslt.1.dylib
0x931bd000 - 0x934ddfe2  com.apple.QuickTime 7.4.5 (67) <520cbf4ae05622466ad1b89f1ba3a4e1> /System/Library/Frameworks/QuickTime.framework/Versions/A/QuickTime
0x934de000 - 0x934fcfff  libresolv.9.dylib ??? (???) <a8018c42930596593ddf27f7c20fe7af> /usr/lib/libresolv.9.dylib
0x934fd000 - 0x935e2ff3  com.apple.CoreData 100.1 (186) <8e28162ef2288692615b52acc01f8b54> /System/Library/Frameworks/CoreData.framework/Versions/A/CoreData
0x935f3000 - 0x936a5ffb  libcrypto.0.9.7.dylib ??? (???) <69bc2457aa23f12fa7d052601d48fa29> /usr/lib/libcrypto.0.9.7.dylib
0x93719000 - 0x93727ffd  libz.1.dylib ??? (???) <5ddd8539ae2ebfd8e7cc1c57525385c7> /usr/lib/libz.1.dylib
0x93728000 - 0x9372cfff  libmathCommon.A.dylib ??? (???) /usr/lib/system/libmathCommon.A.dylib
0x9372d000 - 0x937b1fe3  com.apple.CFNetwork 339.5 (339.5) <c6565c13b0356e1d4bb99a68398d558b> /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/CFNetwork.framework/Versions/A/CFNetwork
0x938b4000 - 0x938b4ffd  com.apple.Accelerate.vecLib 3.4.2 (vecLib 3.4.2) /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/vecLib
0x938b5000 - 0x93a83fff  com.apple.security 5.0.4 (34102) <3a178df3d2ee0bb65cdbfe570618acf4> /System/Library/Frameworks/Security.framework/Versions/A/Security
0x93a84000 - 0x93a84fff  com.apple.Carbon 136 (136) <98a5e3bc0c4fa44bbb09713bb88707fe> /System/Library/Frameworks/Carbon.framework/Versions/A/Carbon
0x93a85000 - 0x93ab2feb  libvDSP.dylib ??? (???) <b232c018ddd040ec4e2c2af632dd497f> /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/libvDSP.dylib
0x93ab3000 - 0x93ab3ffb  com.apple.installserver.framework 1.0 (8) /System/Library/PrivateFrameworks/InstallServer.framework/Versions/A/InstallServer
0x93c34000 - 0x93c48ff3  com.apple.ImageCapture 4.0 (5.0.0) /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/ImageCapture.framework/Versions/A/ImageCapture
0x93c49000 - 0x942e5fff  com.apple.CoreGraphics 1.351.33 (???) <481a77e81d9e53589a05e80cfa90bbb5> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/CoreGraphics.framework/Versions/A/CoreGraphics
0x942e6000 - 0x94379ff3  com.apple.ApplicationServices.ATS 3.4 (???) <a96cd91dabc68545183c11de8f92c7e4> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/ATS.framework/Versions/A/ATS
0x9444e000 - 0x9445bfe7  com.apple.opengl 1.5.7 (1.5.7) <db835aeb1ffca9f5b5647dd0829a5b2c> /System/Library/Frameworks/OpenGL.framework/Versions/A/OpenGL
0x9445c000 - 0x94463fff  com.apple.agl 3.0.9 (AGL-3.0.9) <aeab67ef267f8295ae80fddc197b52a5> /System/Library/Frameworks/AGL.framework/Versions/A/AGL
0x94464000 - 0x944c1ffb  libstdc++.6.dylib ??? (???) <04b812dcec670daa8b7d2852ab14be60> /usr/lib/libstdc++.6.dylib
0x944c2000 - 0x945f4fff  com.apple.CoreFoundation 6.5.4 (476.15) <e2869ad6dc1dd289f21b305b0bea9158> /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation
0x94663000 - 0x94663ffc  com.apple.audio.units.AudioUnit 1.5 (1.5) /System/Library/Frameworks/AudioUnit.framework/Versions/A/AudioUnit
0x94672000 - 0x94672ffd  com.apple.Accelerate 1.4.2 (Accelerate 1.4.2) /System/Library/Frameworks/Accelerate.framework/Versions/A/Accelerate
0x94673000 - 0x9469bff7  com.apple.shortcut 1 (1.0) <057783867138902b52bc0941fedb74d1> /System/Library/PrivateFrameworks/Shortcut.framework/Versions/A/Shortcut
0x9469c000 - 0x946a3ff7  libCGATS.A.dylib ??? (???) <973c01cc14f3d673270e269ccfaec660> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/CoreGraphics.framework/Versions/A/Resources/libCGATS.A.dylib
0x946a4000 - 0x946c3ffa  libJPEG.dylib ??? (???) <e7eb56555109e23144924cd64aa8daec> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/ImageIO.framework/Versions/A/Resources/libJPEG.dylib
0x94715000 - 0x94d65fff  com.apple.WebCore 5525.18.1 (5525.18.1) <9fcf69305c5b48dd8a5cb77107f66c7a> /System/Library/Frameworks/WebKit.framework/Versions/A/Frameworks/WebCore.framework/Versions/A/WebCore
0x94d66000 - 0x94da8fef  com.apple.NavigationServices 3.5.2 (163) <91844980804067b07a0b6124310d3f31> /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/NavigationServices.framework/Versions/A/NavigationServices
0x94da9000 - 0x94da9ff8  com.apple.ApplicationServices 34 (34) <8f910fa65f01d401ad8d04cc933cf887> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/ApplicationServices
0x94daa000 - 0x94e78ff3  com.apple.JavaScriptCore 5525.18 (5525.18) <672d1c7f16a4300addabeff4830f5024> /System/Library/Frameworks/JavaScriptCore.framework/Versions/A/JavaScriptCore
0x94e79000 - 0x94eb8fef  libTIFF.dylib ??? (???) <3589442575ac77746ae99ecf724f5f87> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/ImageIO.framework/Versions/A/Resources/libTIFF.dylib
0x94eb9000 - 0x94eb9ffd  com.apple.vecLib 3.4.2 (vecLib 3.4.2) /System/Library/Frameworks/vecLib.framework/Versions/A/vecLib
0x9520c000 - 0x9521cfff  com.apple.speech.synthesis.framework 3.7.1 (3.7.1) <06d8fc0307314f8ffc16f206ad3dbf44> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/SpeechSynthesis.framework/Versions/A/SpeechSynthesis
0x9521d000 - 0x95248fe7  libauto.dylib ??? (???) <42d8422dc23a18071869fdf7b5d8fab5> /usr/lib/libauto.dylib
0x9524f000 - 0x95256fe9  libgcc_s.1.dylib ??? (???) <f53c808e87d1184c0f9df63aef53ce0b> /usr/lib/libgcc_s.1.dylib
0x95257000 - 0x9525bfff  libGIF.dylib ??? (???) <572a32e46e33be1ec041c5ef5b0341ae> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/ImageIO.framework/Versions/A/Resources/libGIF.dylib
0x9525c000 - 0x9630cff6  com.apple.QuickTimeComponents.component 7.4.5 (67) /System/Library/QuickTime/QuickTimeComponents.component/Contents/MacOS/QuickTimeComponents
0x9630d000 - 0x96431fe3  com.apple.audio.toolbox.AudioToolbox 1.5.1 (1.5.1) /System/Library/Frameworks/AudioToolbox.framework/Versions/A/AudioToolbox
0x96432000 - 0x96842fef  libBLAS.dylib ??? (???) /System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vecLib.framework/Versions/A/libBLAS.dylib
0x96843000 - 0x96859fe7  com.apple.CoreVideo 1.5.0 (1.5.0) <bad2d3a9a92fdecd02e64f0b73a76f27> /System/Library/Frameworks/CoreVideo.framework/Versions/A/CoreVideo
0x9685a000 - 0x9685cfff  com.apple.securityhi 3.0 (30817) <2b2854123fed609d1820d2779e2e0963> /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/SecurityHI.framework/Versions/A/SecurityHI
0x9685d000 - 0x96869ffe  libGL.dylib ??? (???) /System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/libGL.dylib
0x9686a000 - 0x968e9ff5  com.apple.SearchKit 1.2.1 (1.2.1) <3140a605db2abf56b237fa156a08b28b> /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/SearchKit.framework/Versions/A/SearchKit
0x968ea000 - 0x96900fff  com.apple.DictionaryServices 1.0.0 (1.0.0) <ad0aa0252e3323d182e17f50defe56fc> /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/DictionaryServices.framework/Versions/A/DictionaryServices
0x96968000 - 0x97165fef  com.apple.AppKit 6.5.3 (949.34) <4c7af9b12c894d4a528fda29377f143b> /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit
0x97166000 - 0x97176ffc  com.apple.LangAnalysis 1.6.4 (1.6.4) <8b7831b5f74a950a56cf2d22a2d436f6> /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/LangAnalysis.framework/Versions/A/LangAnalysis
0x97177000 - 0x97234fff  com.apple.WebKit 5525.18 (5525.18) <9228870ec6a53b83134fd13a359276a8> /System/Library/Frameworks/WebKit.framework/Versions/A/WebKit
0xfffe8000 - 0xfffebfff  libobjc.A.dylib ??? (???) /usr/lib/libobjc.A.dylib
0xffff0000 - 0xffff1780  libSystem.B.dylib ??? (???) /usr/lib/libSystem.B.dylib


