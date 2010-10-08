--- 
wordpress_id: 234
layout: post
title: "Django Model Manager "
wordpress_url: http://maweis.com/index.php/archives/234.html
---
from django.db import models
from mars.users.models import User


class TaskInitManager(models.Manager):
def get_query_set(self):
return super(TaskInitManager, self).get_query_set().filter(state='1')

class TaskWorkingManager(models.Manager):
def get_query_set(self):
return super(TaskWorkingManager, self).get_query_set().filter(state='2')

class TaskSuccessManager(models.Manager):
def get_query_set(self):
return super(TaskSuccessManager, self).get_query_set().filter(state='3')

class TaskGiveUpManager(models.Manager):
def get_query_set(self):
return super(TaskGiveUpManager, self).get_query_set().filter(state='4')

class Task(models.Model):
title=models.CharField(max_length=255)
description=models.TextField()
start_date=models.DateField()
end_date=models.DateField()
state=models.CharField(max_length=1,choices=(('1','Initial'),('2','Working'),('3','Success'),('4','Give Up')))
task_state=models.Manager()
init=TaskInitManager()
working=TaskWorkingManager()
success=TaskSuccessManager()
giveUp=TaskGiveUpManager()
holder=models.ForeignKey(User)
def __unicode__(self):
return self.title
class Admin:
pass
