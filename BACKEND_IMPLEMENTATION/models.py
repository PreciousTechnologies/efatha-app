# ============================================
# DJANGO BACKEND - SERMONS MODEL
# File: church_app/models.py
# ============================================

from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class Sermon(models.Model):
    """
    Sermon model for storing church sermons with audio/video files and thumbnails
    All files are stored in the database media folder
    """
    # Basic Information
    title = models.CharField(max_length=255, help_text="Sermon title")
    pastor = models.CharField(max_length=200, help_text="Pastor name")
    category = models.CharField(
        max_length=100,
        choices=[
            ('Sunday Service', 'Sunday Service'),
            ('Midweek Service', 'Midweek Service'),
            ('Youth Service', 'Youth Service'),
            ('Special Event', 'Special Event'),
            ('Conference', 'Conference'),
            ('Revival', 'Revival'),
            ('Worship Night', 'Worship Night'),
            ('Bible Study', 'Bible Study'),
        ],
        default='Sunday Service',
        help_text="Sermon category"
    )
    description = models.TextField(help_text="Sermon description")
    topics = models.CharField(
        max_length=500, 
        help_text="Comma-separated topics (e.g., Faith, Prayer, Healing)"
    )
    duration = models.CharField(
        max_length=10, 
        help_text="Duration in MM:SS format (e.g., 45:30)"
    )
    
    # Media Files (stored in database media folder)
    audio_file = models.FileField(
        upload_to='sermons/audio/%Y/%m/',
        null=True,
        blank=True,
        help_text="Audio file (MP3, WAV, M4A, etc.)",
        max_length=500
    )
    video_file = models.FileField(
        upload_to='sermons/video/%Y/%m/',
        null=True,
        blank=True,
        help_text="Video file (MP4, MOV, AVI, etc.)",
        max_length=500
    )
    thumbnail = models.ImageField(
        upload_to='sermons/thumbnails/%Y/%m/',
        null=True,
        blank=True,
        help_text="Sermon thumbnail image (JPG, PNG, etc.)",
        max_length=500
    )
    
    # Metadata
    uploaded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='uploaded_sermons',
        help_text="User who uploaded this sermon"
    )
    views = models.IntegerField(default=0, help_text="Number of views")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True, help_text="Is sermon active/visible")
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Sermon'
        verbose_name_plural = 'Sermons'
        indexes = [
            models.Index(fields=['-created_at']),
            models.Index(fields=['category']),
            models.Index(fields=['pastor']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.pastor}"
    
    def increment_views(self):
        """Increment view count"""
        self.views += 1
        self.save(update_fields=['views'])
    
    @property
    def has_audio(self):
        """Check if sermon has audio file"""
        return bool(self.audio_file)
    
    @property
    def has_video(self):
        """Check if sermon has video file"""
        return bool(self.video_file)
    
    @property
    def has_thumbnail(self):
        """Check if sermon has thumbnail"""
        return bool(self.thumbnail)
