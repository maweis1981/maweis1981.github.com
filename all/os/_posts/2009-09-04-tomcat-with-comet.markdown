--- 
wordpress_id: 515
layout: post
title: tomcat with comet
wordpress_url: http://maweis.com/2009/09/04/tomcat-with-comet/
---
<pre lang="xml"><Connector　connectionTimeout="20000"　port="8080"　protocol="org.apache.　
coyote.http11.Http11NioProtocol"　redirectPort="8443"/>　
</pre>
<pre lang="java">

　public　class　TomcatWeatherServlet　extends　HttpServlet　implements　CometProcessor{ 
　　private　MessageSender　messageSender　=　null; 
　　private　static　final　Integer　TIMEOUT　=　60　*　1000; 
　　@Override 
　　public　void　destroy()　{ 
　　messageSender.stop(); 
　　messageSender　=　null; 
　　} 
　　@Override 
　　public　void　init()　throws　ServletException　{ 
　　messageSender　=　new　MessageSender(); 
　　Thread　messageSenderThread　= 
　　new　Thread(messageSender,　"MessageSender["　+　getServletContext() 
　　.getContextPath()　+　"]"); 
　　messageSenderThread.setDaemon(true); 
　　messageSenderThread.start(); 
　　} 
　　public　void　event(final　CometEvent　event)　throws　IOException,　ServletException　{ 
　　HttpServletRequest　request　=　event.getHttpServletRequest(); 
　　HttpServletResponse　response　=　event.getHttpServletResponse(); 
　　if　(event.getEventType()　==　CometEvent.EventType.BEGIN)　{ 
　　request.setAttribute("org.apache.tomcat.comet.timeout",　TIMEOUT); 
　　log("Begin　for　session:　"　+　request.getSession(true).getId()); 
　　messageSender.setConnection(response); 
　　Weatherman　weatherman　=　new　Weatherman(95118,　32408); 
　　new　Thread(weatherman).start(); 
　　}　else　if　(event.getEventType()　==　CometEvent.EventType.ERROR)　{ 
　　log("Error　for　session:　"　+　request.getSession(true).getId()); 
　　event.close(); 
　　}　else　if　(event.getEventType()　==　CometEvent.EventType.END)　{ 
　　log("End　for　session:　"　+　request.getSession(true).getId()); 
　　event.close(); 
　　}　else　if　(event.getEventType()　==　CometEvent.EventType.READ)　{ 
　　throw　new　UnsupportedOperationException("This　servlet　does　not　accept 
　　data"); 
　　} 
　　} 
　　}
</pre>
