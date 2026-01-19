from django.db import models
from django.conf import settings


class FavoriteVerse(models.Model):
    """User's favorite Bible verses"""
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='favorite_verses'
    )
    
    book = models.CharField(max_length=50)
    chapter = models.IntegerField()
    verse = models.IntegerField()
    verse_text = models.TextField()
    bible_version = models.CharField(
        max_length=10,
        choices=[('kjv', 'KJV'), ('swahili', 'Swahili')],
        default='kjv'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'book', 'chapter', 'verse', 'bible_version']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.book} {self.chapter}:{self.verse}"


class VerseHighlight(models.Model):
    """Highlighted verses with colors"""
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='verse_highlights'
    )
    
    book = models.CharField(max_length=50)
    chapter = models.IntegerField()
    verse = models.IntegerField()
    color = models.CharField(
        max_length=20,
        choices=[
            ('yellow', 'Yellow'),
            ('green', 'Green'),
            ('blue', 'Blue'),
            ('pink', 'Pink'),
            ('orange', 'Orange'),
            ('purple', 'Purple'),
        ]
    )
    bible_version = models.CharField(
        max_length=10,
        choices=[('kjv', 'KJV'), ('swahili', 'Swahili')],
        default='kjv'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'book', 'chapter', 'verse', 'bible_version']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.book} {self.chapter}:{self.verse} ({self.color})"
