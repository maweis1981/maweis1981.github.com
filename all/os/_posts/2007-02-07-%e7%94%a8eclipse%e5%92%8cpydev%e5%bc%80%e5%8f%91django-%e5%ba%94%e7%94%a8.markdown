--- 
wordpress_id: 18
layout: post
title: !binary |
  55SoRWNsaXBzZeWSjFB5RGV25byA5Y+RRGphbmdvIOW6lOeUqA==

wordpress_url: http://maweis.com/?p=18
---
针对读者：
已安装了Python,Eclipse，PyDev和Django。
使用Eclipse 3.2，PyDev 1.2.4 Django 0.95 和Python 2.4

第一步，Window-&gt;Preferences-&gt;Preferences-&gt;PyDev-&gt;Python Interpretter

<img src="http://maweis.com/wp-content/uploads/2007/02/django1.jpg" id="image8" alt="django1.jpg" />
第二步，创建一个新的PyDev项目. 并且把create src folder选项取消

<img src="http://maweis.com/wp-content/uploads/2007/02/django2.jpg" id="image15" alt="django2.jpg" />
第三步，通过命令行创建一个Django项目， 例如：django-admin.py startproject mysite

<img src="http://maweis.com/wp-content/uploads/2007/02/django3.jpg" id="image14" alt="django3.jpg" />
第四步，把刚才django生成的代码copy到刚才用Eclipse创建的PyDev项目里，并且创建一个src目录。

<img src="http://maweis.com/wp-content/uploads/2007/02/django4.jpg" id="image13" alt="django4.jpg" />
第五步，在eclipse中刷新这个项目。

<img src="http://maweis.com/wp-content/uploads/2007/02/django5.jpg" id="image12" alt="django5.jpg" />
第六步，右键单击项目，在属性中选择PyDev，PYTHONPATH，然后将src目录添加到项目代码中去

<img src="http://maweis.com/wp-content/uploads/2007/02/django6.jpg" id="image11" alt="django6.jpg" />

这些做完后，打开manage.py,然后按下F9，console中出现usage消息，此时选择

<img src="http://maweis.com/wp-content/uploads/2007/02/django8.jpg" id="image10" alt="django8.jpg" />
Run-&gt;Run..., 在Arguments选项栏中给manage.py参数设定<em><strong>runserver --noreload.(此处是两个短横)</strong></em>

<img src="http://maweis.com/wp-content/uploads/2007/02/django7.jpg" id="image17" alt="django7.jpg" />
一切完成了

<img src="http://maweis.com/wp-content/uploads/2007/02/django9.jpg" id="image9" alt="django9.jpg" />

这时候就是要好好写Django应用的时候了。
