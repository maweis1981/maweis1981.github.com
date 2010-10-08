--- 
wordpress_id: 47
layout: post
title: the Bug about Canon On Ubuntu
wordpress_url: http://maweis.com/?p=47
---
<p id="bug-description" style="font-family: monospace">Binary package hint: libgphoto2-2

The file /etc/udev/<wbr></wbr>rules.d/<wbr></wbr>45-libgphoto2.<wbr></wbr>rules says in line 3:

BUS!="usb*", GOTO="libgphoto<wbr></wbr>2_rules_<wbr></wbr>end"

while recenly updated udev doesn't produce BUS properties in corresponding event. Thus this line makes the whole file useless, because BUS!="usb*" is never true.

Something like

SUBSYSTEM!<wbr></wbr>="usb_device"<wbr></wbr>, GOTO="libgphoto<wbr></wbr>2_rules_<wbr></wbr>end"

instead would work.
