--- 
wordpress_id: 445
layout: post
title: !binary |
  QW5kcm9pZCDoh6rlrprkuYl2aWV357uE5Lu2

wordpress_url: http://maweis.com/2009/04/10/android-%e8%87%aa%e5%ae%9a%e4%b9%89view%e7%bb%84%e4%bb%b6/
---
写一个View继承anroid的view

在layout中定义，以自己写的view的全包名为xml element name，
如下：

<com.maweis.PaintView android:id="@+id/textContent" android:layout_width="fill_parent" android:layout_height="fill_parent"></com.maweis.PaintView>

public class PaintView extends View 
重写onDraw方法

就ok了
