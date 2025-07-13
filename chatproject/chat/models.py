from django.db import models

# Create your models here.
class SharedFile(models.Model):
    file = models.FileField(upload_to='shared_files/')
    sender = models.CharField(max_length=100)
    timestamp = models.DateTimeField(auto_now_add=True)