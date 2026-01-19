# ============================================
# DJANGO BACKEND - SERMONS SERIALIZER
# File: church_app/serializers.py
# ============================================

from rest_framework import serializers
from .models import Sermon

class SermonSerializer(serializers.ModelSerializer):
    """
    Serializer for Sermon model
    Handles file uploads and provides absolute URLs for media files
    """
    uploaded_by_name = serializers.SerializerMethodField()
    audio_url = serializers.SerializerMethodField()
    video_url = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Sermon
        fields = [
            'id',
            'title',
            'pastor',
            'category',
            'description',
            'topics',
            'duration',
            'audio_file',
            'video_file',
            'thumbnail',
            'audio_url',
            'video_url',
            'thumbnail_url',
            'uploaded_by',
            'uploaded_by_name',
            'views',
            'created_at',
            'updated_at',
            'is_active',
        ]
        read_only_fields = ['id', 'uploaded_by', 'views', 'created_at', 'updated_at']
    
    def get_uploaded_by_name(self, obj):
        """Get full name of uploader"""
        if obj.uploaded_by:
            full_name = f"{obj.uploaded_by.first_name} {obj.uploaded_by.last_name}".strip()
            return full_name if full_name else obj.uploaded_by.username
        return "Unknown"
    
    def get_audio_url(self, obj):
        """Get absolute URL for audio file"""
        if obj.audio_file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.audio_file.url)
            return obj.audio_file.url
        return None
    
    def get_video_url(self, obj):
        """Get absolute URL for video file"""
        if obj.video_file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.video_file.url)
            return obj.video_file.url
        return None
    
    def get_thumbnail_url(self, obj):
        """Get absolute URL for thumbnail"""
        if obj.thumbnail:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.thumbnail.url)
            return obj.thumbnail.url
        return None
    
    def create(self, validated_data):
        """Create sermon and set uploaded_by to current user"""
        validated_data['uploaded_by'] = self.context['request'].user
        return super().create(validated_data)
    
    def validate_duration(self, value):
        """Validate duration format (MM:SS)"""
        import re
        if not re.match(r'^\d{1,3}:\d{2}$', value):
            raise serializers.ValidationError(
                "Duration must be in MM:SS format (e.g., 45:30)"
            )
        return value
    
    def validate(self, data):
        """Ensure at least audio or video file is provided for new sermons"""
        # Only check on creation
        if not self.instance:
            audio = data.get('audio_file')
            video = data.get('video_file')
            if not audio and not video:
                raise serializers.ValidationError(
                    "Please provide at least an audio or video file"
                )
        return data
