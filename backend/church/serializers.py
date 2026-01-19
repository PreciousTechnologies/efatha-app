from rest_framework import serializers
from .models import (
    Sermon, Event, EventRegistration, PrayerRequest,
    PrayerSupport, PrayerRequestImage, PrayerComment, 
    Testimony, Giving, PaymentTransaction, Announcement, LiveStream, LiveChatMessage
)


class SermonSerializer(serializers.ModelSerializer):
    # Computed fields for file URLs
    audio_url = serializers.SerializerMethodField()
    video_url = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()
    uploaded_by_name = serializers.SerializerMethodField()
    # Allow writing to 'pastor' but store in 'preacher'
    pastor = serializers.CharField(source='preacher', required=False, allow_blank=True)
    
    class Meta:
        model = Sermon
        fields = [
            'id', 'title', 'preacher', 'pastor', 'category', 'description', 
            'topics', 'duration', 'audio_file', 'video_file', 'thumbnail',
            'audio_url', 'video_url', 'thumbnail_url', 'uploaded_by', 
            'uploaded_by_name', 'views', 'is_featured', 'is_active',
            'created_at', 'updated_at', 'sermon_date'
        ]
        read_only_fields = ['views', 'created_at', 'updated_at', 'sermon_date', 'uploaded_by', 'preacher']
        extra_kwargs = {
            'preacher': {'required': False, 'allow_blank': True},
        }
    
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
    
    def get_uploaded_by_name(self, obj):
        """Get name of user who uploaded"""
        if obj.uploaded_by:
            return obj.uploaded_by.get_full_name() or obj.uploaded_by.username
        return None
    
    def validate_duration(self, value):
        """Validate duration is in MM:SS format"""
        if value:
            import re
            if not re.match(r'^\d{1,3}:\d{2}$', value):
                raise serializers.ValidationError(
                    "Duration must be in MM:SS format (e.g., 45:30)"
                )
        return value
    
    def validate(self, data):
        """Ensure at least audio or video file is provided"""
        audio = data.get('audio_file') or (self.instance and self.instance.audio_file)
        video = data.get('video_file') or (self.instance and self.instance.video_file)
        
        if not audio and not video:
            raise serializers.ValidationError(
                "At least one media file (audio or video) is required"
            )
        return data
    
    def create(self, validated_data):
        """Set uploaded_by to current user and ensure is_active=True"""
        validated_data['uploaded_by'] = self.context['request'].user
        # Explicitly set is_active to True for new sermons
        validated_data['is_active'] = True
        return super().create(validated_data)


class EventSerializer(serializers.ModelSerializer):
    organizer_name = serializers.CharField(source='organizer.get_full_name', read_only=True)
    registered_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Event
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']
    
    def get_registered_count(self, obj):
        return obj.registrations.count()


class EventRegistrationSerializer(serializers.ModelSerializer):
    event_title = serializers.CharField(source='event.title', read_only=True)
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    
    class Meta:
        model = EventRegistration
        fields = '__all__'
        read_only_fields = ['registered_at']


class PrayerRequestSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    user_profile_picture = serializers.SerializerMethodField()
    prayer_count = serializers.SerializerMethodField()
    is_praying = serializers.SerializerMethodField()
    images = serializers.SerializerMethodField()
    comment_count = serializers.SerializerMethodField()
    supporters_list = serializers.SerializerMethodField()
    
    class Meta:
        model = PrayerRequest
        fields = '__all__'
        read_only_fields = ['user', 'created_at', 'updated_at']
    
    def get_user_name(self, obj):
        if obj.is_anonymous:
            return "Anonymous"
        return obj.user.get_full_name() or obj.user.username
    
    def get_user_profile_picture(self, obj):
        """Return full URL of user's profile picture"""
        if obj.is_anonymous:
            return None
        if obj.user.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.user.profile_picture.url)
            return obj.user.profile_picture.url
        return None
    
    def get_prayer_count(self, obj):
        return obj.supporters.count()
    
    def get_is_praying(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.supporters.filter(user=request.user).exists()
        return False
    
    def get_images(self, obj):
        images = obj.images.all()
        return PrayerRequestImageSerializer(images, many=True, context=self.context).data
    
    def get_comment_count(self, obj):
        return obj.comments.count()
    
    def get_supporters_list(self, obj):
        """Return list of users who are praying for this request"""
        request = self.context.get('request')
        supporters = obj.supporters.select_related('user').all()
        result = []
        for support in supporters:
            profile_picture_url = None
            if support.user.profile_picture:
                if request:
                    profile_picture_url = request.build_absolute_uri(support.user.profile_picture.url)
                else:
                    profile_picture_url = support.user.profile_picture.url
            
            result.append({
                'id': support.user.id,
                'name': support.user.get_full_name() or support.user.username,
                'username': support.user.username,
                'profile_picture': profile_picture_url,
                'prayed_at': support.created_at,
            })
        return result


class PrayerRequestImageSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = PrayerRequestImage
        fields = ['id', 'image', 'image_url', 'caption', 'uploaded_at']
        read_only_fields = ['uploaded_at']
    
    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image and hasattr(obj.image, 'url'):
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None


class PrayerCommentSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    user_initials = serializers.SerializerMethodField()
    user_profile_picture = serializers.SerializerMethodField()
    
    class Meta:
        model = PrayerComment
        fields = ['id', 'prayer_request', 'user', 'user_name', 'user_initials', 
                  'user_profile_picture', 'content', 'created_at', 'updated_at']
        read_only_fields = ['user', 'created_at', 'updated_at']
    
    def get_user_name(self, obj):
        return obj.user.get_full_name() or obj.user.username
    
    def get_user_initials(self, obj):
        name = obj.user.get_full_name() or obj.user.username
        parts = name.split()
        if len(parts) >= 2:
            return f"{parts[0][0]}{parts[1][0]}".upper()
        return name[:2].upper()
    
    def get_user_profile_picture(self, obj):
        """Return full URL of user's profile picture"""
        if obj.user.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.user.profile_picture.url)
            return obj.user.profile_picture.url
        return None


class TestimonySerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    user_profile_picture = serializers.SerializerMethodField()
    photo_url = serializers.SerializerMethodField()
    video_url = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()
    prayer_request_title = serializers.SerializerMethodField()
    user_role = serializers.SerializerMethodField()
    praise_count = serializers.SerializerMethodField()
    user_has_praised = serializers.SerializerMethodField()
    
    class Meta:
        model = Testimony
        fields = '__all__'
        read_only_fields = ['user', 'is_approved', 'created_at', 'updated_at']
    
    def get_user_name(self, obj):
        if obj.is_anonymous:
            return "Anonymous"
        return obj.user.get_full_name() or obj.user.username
    
    def get_user_role(self, obj):
        """Return user's role"""
        return obj.user.role if hasattr(obj.user, 'role') else None
    
    def get_praise_count(self, obj):
        """Return total number of praises"""
        return obj.praises.count()
    
    def get_user_has_praised(self, obj):
        """Check if current user has praised this testimony"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.praises.filter(user=request.user).exists()
        return False
    
    def get_user_profile_picture(self, obj):
        """Return full URL of user's profile picture"""
        if obj.is_anonymous:
            return None
        if obj.user.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.user.profile_picture.url)
            return obj.user.profile_picture.url
        return None
    
    def get_photo_url(self, obj):
        """Return full URL of testimony photo"""
        if obj.photo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.photo.url)
            return obj.photo.url
        return None
    
    def get_video_url(self, obj):
        """Return full URL of testimony video"""
        if obj.video:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.video.url)
            return obj.video.url
        return None
    
    def get_thumbnail_url(self, obj):
        """Return full URL of testimony thumbnail (for Sunday Service)"""
        if obj.thumbnail:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.thumbnail.url)
            return obj.thumbnail.url
        return None
    
    def get_prayer_request_title(self, obj):
        """Return linked prayer request title"""
        if obj.prayer_request:
            return obj.prayer_request.title
        return None


class PaymentTransactionSerializer(serializers.ModelSerializer):
    """Serializer for payment transaction logs"""
    
    class Meta:
        model = PaymentTransaction
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at', 'completed_at']


class GivingSerializer(serializers.ModelSerializer):
    """Comprehensive serializer for giving/donations"""
    user_name = serializers.SerializerMethodField()
    transactions = PaymentTransactionSerializer(many=True, read_only=True)
    
    class Meta:
        model = Giving
        fields = '__all__'
        read_only_fields = [
            'user', 'merchant_reference', 'payment_status',
            'created_at', 'updated_at', 'completed_at'
        ]
    
    def get_user_name(self, obj):
        if obj.is_anonymous:
            return 'Anonymous'
        if obj.donor_name:
            return obj.donor_name
        if obj.user:
            return obj.user.get_full_name() or obj.user.username
        return 'N/A'
    
    def create(self, validated_data):
        # Generate unique merchant reference if not provided
        if 'merchant_reference' not in validated_data or not validated_data['merchant_reference']:
            import uuid
            validated_data['merchant_reference'] = f"EFA-{uuid.uuid4().hex[:12].upper()}"
        
        return super().create(validated_data)


class AnnouncementSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    
    class Meta:
        model = Announcement
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at']


class LiveStreamSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    
    class Meta:
        model = LiveStream
        fields = [
            'id', 'title', 'youtube_url', 'youtube_video_id', 'description',
            'thumbnail_url', 'status', 'scheduled_for', 'viewer_count',
            'created_by', 'created_by_name', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_by', 'created_by_name', 'created_at', 'updated_at']


class LiveChatMessageSerializer(serializers.ModelSerializer):
    user_profile_picture = serializers.SerializerMethodField()
    is_own_message = serializers.SerializerMethodField()
    
    class Meta:
        model = LiveChatMessage
        fields = [
            'id', 'live_stream', 'user', 'user_name', 'message',
            'user_profile_picture', 'is_own_message', 'created_at'
        ]
        read_only_fields = ['user', 'user_name', 'created_at']
    
    def get_user_profile_picture(self, obj):
        """Return full URL of user's profile picture"""
        if obj.user and obj.user.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.user.profile_picture.url)
            return obj.user.profile_picture.url
        return None
    
    def get_is_own_message(self, obj):
        """Check if message belongs to current user"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.user_id == request.user.id
        return False
