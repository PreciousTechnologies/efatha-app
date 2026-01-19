from django.db import models
from django.conf import settings


class FavoriteHymn(models.Model):
    """User's favorite hymns"""
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='favorite_hymns'
    )
    
    hymn_number = models.IntegerField()
    hymn_title = models.CharField(max_length=200)
    category = models.CharField(max_length=100, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'hymn_number']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.hymn_number}. {self.hymn_title}"
