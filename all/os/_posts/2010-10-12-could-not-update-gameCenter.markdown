---
layout : post
title: Developer Could not update the origin app to support game center
---

*Developer Could not update the origin app to support game center feature*

Everybody knows Apple release GameCenter feature in iOS 4.1.
[@tinyfool](http://twitter.com/tinyfool) makes a cute game app named "memory game", by the game center features, player 
can submit their game score to the leader board what is Apple Game Center support.

well, I made a simple game named AttentionPlay! somedays ago, So I plan to add gameCenter support too.

and the feature is so funny and easy to add.

you can test the game center in GameCenter(Sandbox) what is apple support.

now, the work is done . I was ready to uploading the new version game app with game center support.

![ApplicationLoader ScreenShot](http://flic.kr/p/8JpcGt)

Because you could not add new feature in Info.plist for your application, that's mean:
you could not add gamekit=True in your UIRequiredCapabilities in Info.plist. the application
could not use gamekit features.

So, Just make a new game application then upload your game.
