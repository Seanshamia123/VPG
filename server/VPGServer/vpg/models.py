from django.db import models

class UserProfile(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    number = models.CharField(max_length=15)
    location = models.CharField(max_length=255)
    gender = models.CharField(max_length=10, choices=[
        ('male', 'Male'),
        ('female', 'Female'),
        ('other', 'Other'),
    ])

    def __str__(self):
        return self.name
