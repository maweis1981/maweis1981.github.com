--- 
wordpress_id: 514
layout: post
title: add syntax highlighting
wordpress_url: http://maweis.com/2009/09/01/add-syntax-highlighting/
---
I've recently discovered how to add syntax highlighting to the wiki
(http://wiki.github.com/dpp/liftweb).

First, you simply added this to the top of the article:
<pre lang="html">
<link href='http://scala-tools.org/scaladocs/liftweb/1.0/_highlighter/SyntaxHighlighter.css'
rel='stylesheet' type='text/css'/>
</pre>
Next, you added these two lines to the bottom of the page:
<pre lang="html">
<script src='http://scala-tools.org/scaladocs/liftweb/1.0/_highlighter/shAll.js'></script>
<script>dp.SyntaxHighlighter.HighlightAll('code');</script>
</pre>
Finally, just surround and code snippets with:
<pre lang="html">
<pre name="code" class="scala:nocontrols">Your scala code...</pre>
</pre>

