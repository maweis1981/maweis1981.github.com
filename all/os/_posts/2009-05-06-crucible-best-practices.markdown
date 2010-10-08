--- 
wordpress_id: 462
layout: post
title: Crucible Best Practices
wordpress_url: http://maweis.com/2009/05/06/crucible-best-practices/
---
<h6><a name="5.BestPracticesforCrucibleConfiguration-1.DonotgiveCrucibleprojectsthesamekeyasyourJIRAprojects."></a>1. Do not give Crucible projects the same key as your JIRA projects.</h6>  <p>When naming projects, take care to ensure that the key you assign to them is not the same as any of your JIRA projects. The reason for this is, if one of your Crucible projects has the same key as one of your projects in JIRA, then all links with that key will lead back to Crucible, rather than leading to JIRA, removing the ability to navigate between the two applications. </p>  <p>To avoid this, name your Crucible project keys differently. For example, you could place the following text at the beginning of each project key: <tt>CR-</tt> to distinguish it. So, for this case, if you have an existing JIRA key of '<tt>RHUBARB</tt>', you would create a Crucible key called '<tt>CR-RHUBARB</tt>' so that they do not conflict.</p>
