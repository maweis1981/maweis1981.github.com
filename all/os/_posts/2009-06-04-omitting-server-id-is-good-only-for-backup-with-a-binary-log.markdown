--- 
wordpress_id: 484
layout: post
title: " omitting server-id is good only for backup with a binary log."
wordpress_url: http://maweis.com/2009/06/04/omitting-server-id-is-good-only-for-backup-with-a-binary-log/
---
Note

If you omit server-id (or set it explicitly to 0), a master refuses connections from all slaves, and a slave refuses to connect to a master. Thus, omitting server-id is good only for backup with a binary log.
