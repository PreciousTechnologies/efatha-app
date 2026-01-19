# ============================================
# DJANGO BACKEND - ADMIN CONFIGURATION
# File: church_app/admin.py
# ============================================

from django.contrib import admin
from .models import Sermon

@admin.register(Sermon)
class SermonAdmin(admin.ModelAdmin):
    """
    Admin interface for Sermon model
    """
    list_display = [
        'id',
        'title',
        'pastor',
        'category',
        'duration',
        'views',
        'has_audio',
        'has_video',
        'has_thumbnail',
        'uploaded_by',
        'created_at',
        'is_active'
    ]
    
    list_filter = [
        'category',
        'is_active',
        'created_at',
        'pastor'
    ]
    
    search_fields = [
        'title',
        'pastor',
        'topics',
        'description'
    ]
    
    readonly_fields = [
        'id',
        'views',
        'created_at',
        'updated_at',
        'uploaded_by'
    ]
    
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'title',
                'pastor',
                'category',
                'topics',
                'duration',
                'description'
            )
        }),
        ('Media Files', {
            'fields': (
                'audio_file',
                'video_file',
                'thumbnail'
            ),
            'description': 'Upload sermon audio, video, and thumbnail files'
        }),
        ('Metadata', {
            'fields': (
                'uploaded_by',
                'views',
                'is_active',
                'created_at',
                'updated_at'
            ),
            'classes': ('collapse',)
        }),
    )
    
    ordering = ['-created_at']
    
    list_per_page = 25
    
    def has_audio(self, obj):
        """Display whether sermon has audio file"""
        return '✅' if obj.has_audio else '❌'
    has_audio.short_description = 'Audio'
    has_audio.boolean = True
    
    def has_video(self, obj):
        """Display whether sermon has video file"""
        return '✅' if obj.has_video else '❌'
    has_video.short_description = 'Video'
    has_video.boolean = True
    
    def has_thumbnail(self, obj):
        """Display whether sermon has thumbnail"""
        return '✅' if obj.has_thumbnail else '❌'
    has_thumbnail.short_description = 'Thumbnail'
    has_thumbnail.boolean = True
