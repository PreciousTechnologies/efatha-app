from django.contrib import admin
from .models import (
    Sermon, Event, EventRegistration, PrayerRequest,
    PrayerSupport, PrayerRequestImage, PrayerComment,
    Testimony, TestimonyPraise, Giving, PaymentTransaction, Announcement, LiveStream, LiveChatMessage
)


@admin.register(Sermon)
class SermonAdmin(admin.ModelAdmin):
    list_display = [
        'title', 'preacher', 'category', 'sermon_date', 'views', 
        'is_featured', 'is_active', 'has_audio', 'has_video', 
        'has_thumbnail', 'uploaded_by', 'created_at'
    ]
    list_filter = ['category', 'is_featured', 'is_active', 'sermon_date', 'preacher']
    search_fields = ['title', 'preacher', 'description', 'topics']
    date_hierarchy = 'sermon_date'
    readonly_fields = ['views', 'created_at', 'updated_at', 'sermon_date']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('title', 'preacher', 'category', 'description', 'topics', 'duration')
        }),
        ('Media Files', {
            'fields': ('audio_file', 'video_file', 'thumbnail')
        }),
        ('Metadata', {
            'fields': ('uploaded_by', 'views', 'is_featured', 'is_active', 'sermon_date', 'created_at', 'updated_at')
        }),
    )
    
    def has_audio(self, obj):
        return obj.has_audio
    has_audio.boolean = True
    has_audio.short_description = 'Audio'
    
    def has_video(self, obj):
        return obj.has_video
    has_video.boolean = True
    has_video.short_description = 'Video'
    
    def has_thumbnail(self, obj):
        return obj.has_thumbnail
    has_thumbnail.boolean = True
    has_thumbnail.short_description = 'Thumbnail'


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'start_date', 'location', 'requires_registration', 'is_published']
    list_filter = ['category', 'requires_registration', 'is_published']
    search_fields = ['title', 'description', 'location']
    date_hierarchy = 'start_date'


@admin.register(EventRegistration)
class EventRegistrationAdmin(admin.ModelAdmin):
    list_display = ['user', 'event', 'registered_at', 'attended']
    list_filter = ['attended', 'registered_at']
    search_fields = ['user__username', 'event__title']


@admin.register(PrayerRequest)
class PrayerRequestAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'priority', 'category', 'is_anonymous', 'is_answered', 'created_at']
    list_filter = ['priority', 'category', 'is_anonymous', 'is_answered']
    search_fields = ['title', 'description']
    date_hierarchy = 'created_at'


@admin.register(PrayerSupport)
class PrayerSupportAdmin(admin.ModelAdmin):
    list_display = ['prayer_request', 'user', 'created_at']
    search_fields = ['prayer_request__title', 'user__username']


@admin.register(PrayerRequestImage)
class PrayerRequestImageAdmin(admin.ModelAdmin):
    list_display = ['prayer_request', 'caption', 'uploaded_at']
    search_fields = ['prayer_request__title', 'caption']
    date_hierarchy = 'uploaded_at'


@admin.register(PrayerComment)
class PrayerCommentAdmin(admin.ModelAdmin):
    list_display = ['prayer_request', 'user', 'content_preview', 'created_at']
    search_fields = ['prayer_request__title', 'user__username', 'content']
    date_hierarchy = 'created_at'
    
    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'


@admin.register(Testimony)
class TestimonyAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'category', 'prayer_request', 'is_anonymous', 'is_approved', 'is_featured', 'has_photo', 'has_video', 'created_at']
    list_filter = ['is_approved', 'is_featured', 'is_anonymous', 'category']
    search_fields = ['title', 'content', 'user__username']
    date_hierarchy = 'created_at'
    actions = ['approve_testimonies', 'feature_testimonies']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('user', 'title', 'content', 'category', 'prayer_request')
        }),
        ('Media', {
            'fields': ('photo', 'video')
        }),
        ('Settings', {
            'fields': ('is_anonymous', 'is_approved', 'is_featured')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    readonly_fields = ['created_at', 'updated_at']
    
    def has_photo(self, obj):
        return obj.has_photo
    has_photo.boolean = True
    has_photo.short_description = 'Photo'
    
    def has_video(self, obj):
        return obj.has_video
    has_video.boolean = True
    has_video.short_description = 'Video'
    
    def approve_testimonies(self, request, queryset):
        queryset.update(is_approved=True)
    approve_testimonies.short_description = "Approve selected testimonies"
    
    def feature_testimonies(self, request, queryset):
        queryset.update(is_featured=True)
    feature_testimonies.short_description = "Feature selected testimonies"


@admin.register(TestimonyPraise)
class TestimonyPraiseAdmin(admin.ModelAdmin):
    list_display = ['testimony', 'user', 'created_at']
    search_fields = ['testimony__title', 'user__username']
    date_hierarchy = 'created_at'
    readonly_fields = ['created_at']


@admin.register(Giving)
class GivingAdmin(admin.ModelAdmin):
    list_display = [
        'get_donor_name', 'giving_type', 'amount', 'currency', 
        'payment_method', 'payment_status', 'merchant_reference', 'created_at'
    ]
    list_filter = [
        'giving_type', 'payment_method', 'payment_status', 
        'currency', 'is_anonymous', 'is_recurring'
    ]
    search_fields = [
        'user__username', 'donor_name', 'donor_email', 'donor_phone',
        'transaction_ref', 'merchant_reference', 'confirmation_code'
    ]
    date_hierarchy = 'created_at'
    readonly_fields = ['created_at', 'updated_at', 'completed_at']
    
    fieldsets = (
        ('Donor Information', {
            'fields': ('user', 'donor_name', 'donor_email', 'donor_phone', 'is_anonymous')
        }),
        ('Giving Details', {
            'fields': ('giving_type', 'amount', 'currency', 'notes', 'is_recurring', 'recurring_frequency')
        }),
        ('Payment Information', {
            'fields': (
                'payment_method', 'payment_status', 'transaction_ref',
                'merchant_reference', 'pesapal_tracking_id', 'confirmation_code'
            )
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'completed_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_donor_name(self, obj):
        if obj.is_anonymous:
            return 'Anonymous'
        return obj.donor_name or (obj.user.get_full_name() if obj.user else 'N/A')
    get_donor_name.short_description = 'Donor'
    
    actions = ['mark_as_completed', 'mark_as_failed']
    
    def mark_as_completed(self, request, queryset):
        updated = queryset.update(payment_status='completed')
        self.message_user(request, f'{updated} donations marked as completed.')
    mark_as_completed.short_description = "Mark selected donations as completed"
    
    def mark_as_failed(self, request, queryset):
        updated = queryset.update(payment_status='failed')
        self.message_user(request, f'{updated} donations marked as failed.')
    mark_as_failed.short_description = "Mark selected donations as failed"


@admin.register(PaymentTransaction)
class PaymentTransactionAdmin(admin.ModelAdmin):
    list_display = [
        'transaction_id', 'merchant_reference', 'gateway', 'amount', 
        'currency', 'status', 'payment_method', 'created_at'
    ]
    list_filter = ['gateway', 'status', 'currency', 'payment_method']
    search_fields = [
        'transaction_id', 'order_tracking_id', 'merchant_reference',
        'confirmation_code', 'payment_account'
    ]
    date_hierarchy = 'created_at'
    readonly_fields = ['created_at', 'updated_at', 'completed_at']
    
    fieldsets = (
        ('Transaction Details', {
            'fields': (
                'giving', 'transaction_id', 'order_tracking_id',
                'merchant_reference', 'gateway'
            )
        }),
        ('Payment Information', {
            'fields': (
                'amount', 'currency', 'payment_method', 'payment_account',
                'status', 'confirmation_code', 'payment_status_description'
            )
        }),
        ('Response Data', {
            'fields': ('error_message', 'request_data', 'response_data', 'callback_data'),
            'classes': ('collapse',)
        }),
        ('Security', {
            'fields': ('ip_address', 'user_agent'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'completed_at'),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['mark_as_completed', 'mark_as_failed']
    
    def mark_as_completed(self, request, queryset):
        for transaction in queryset:
            transaction.mark_completed()
        self.message_user(request, f'{queryset.count()} transactions marked as completed.')
    mark_as_completed.short_description = "Mark selected transactions as completed"
    
    def mark_as_failed(self, request, queryset):
        for transaction in queryset:
            transaction.mark_failed('Manually marked as failed by admin')
        self.message_user(request, f'{queryset.count()} transactions marked as failed.')
    mark_as_failed.short_description = "Mark selected transactions as failed"


@admin.register(Announcement)
class AnnouncementAdmin(admin.ModelAdmin):
    list_display = ['title', 'priority', 'publish_date', 'expiry_date', 'is_published']
    list_filter = ['priority', 'is_published']
    search_fields = ['title', 'content']
    date_hierarchy = 'publish_date'


@admin.register(LiveStream)
class LiveStreamAdmin(admin.ModelAdmin):
    list_display = ['title', 'status', 'scheduled_for', 'viewer_count', 'created_by', 'created_at']
    list_filter = ['status', 'scheduled_for']
    search_fields = ['title', 'description', 'youtube_video_id']
    date_hierarchy = 'created_at'
    readonly_fields = ['created_at', 'updated_at', 'youtube_video_id']
    
    fieldsets = (
        ('Stream Information', {
            'fields': ('title', 'description', 'status', 'scheduled_for')
        }),
        ('YouTube Details', {
            'fields': ('youtube_url', 'youtube_video_id', 'thumbnail_url')
        }),
        ('Statistics', {
            'fields': ('viewer_count',)
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['mark_as_live', 'mark_as_ended']
    
    def mark_as_live(self, request, queryset):
        updated = queryset.update(status='live')
        self.message_user(request, f'{updated} streams marked as live.')
    mark_as_live.short_description = "Mark selected streams as LIVE"
    
    def mark_as_ended(self, request, queryset):
        updated = queryset.update(status='ended')
        self.message_user(request, f'{updated} streams marked as ended.')
    mark_as_ended.short_description = "Mark selected streams as ended"


@admin.register(LiveChatMessage)
class LiveChatMessageAdmin(admin.ModelAdmin):
    list_display = ['user_name', 'live_stream', 'message_preview', 'created_at']
    list_filter = ['live_stream', 'created_at']
    search_fields = ['user_name', 'message']
    date_hierarchy = 'created_at'
    readonly_fields = ['user', 'user_name', 'created_at']
    
    fieldsets = (
        ('Message Details', {
            'fields': ('live_stream', 'user', 'user_name', 'message')
        }),
        ('Metadata', {
            'fields': ('created_at',)
        }),
    )
    
    def message_preview(self, obj):
        return obj.message[:50] + '...' if len(obj.message) > 50 else obj.message
    message_preview.short_description = 'Message'
