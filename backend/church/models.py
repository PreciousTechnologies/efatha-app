from django.db import models
from django.conf import settings
from django.utils import timezone


class Sermon(models.Model):
    """Church Sermons with Enhanced Upload/Edit Features"""
    
    title = models.CharField(max_length=255, help_text="Sermon title")
    preacher = models.CharField(max_length=200, help_text="Pastor/Preacher name", db_column='pastor')
    description = models.TextField(help_text="Sermon description")
    scripture_reference = models.CharField(max_length=100, blank=True)
    
    # Topics (comma-separated)
    topics = models.CharField(
        max_length=500, 
        help_text="Comma-separated topics (e.g., Faith, Prayer, Healing)",
        blank=True,
        default=""
    )
    
    # Duration in MM:SS format
    duration = models.CharField(
        max_length=10, 
        help_text="Duration in MM:SS format (e.g., 45:30)",
        blank=True,
        null=True
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
    sermon_date = models.DateTimeField(auto_now_add=True)
    views = models.IntegerField(default=0, help_text="Number of views")
    
    # Categories
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
    
    # Uploaded by (tracks which editor uploaded)
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='uploaded_sermons',
        help_text="User who uploaded this sermon"
    )
    
    is_featured = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True, help_text="Is sermon active/visible")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Sermon'
        verbose_name_plural = 'Sermons'
        indexes = [
            models.Index(fields=['-created_at']),
            models.Index(fields=['category']),
            models.Index(fields=['preacher']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.preacher}"
    
    def increment_views(self):
        """Increment view count"""
        self.views += 1
        self.save(update_fields=['views'])
    
    @property
    def pastor(self):
        """Alias for preacher (for API compatibility)"""
        return self.preacher
    
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


class Event(models.Model):
    """Church Events"""
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    location = models.CharField(max_length=200)
    
    # Date and time
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    
    # Media
    banner_image = models.ImageField(upload_to='events/', blank=True, null=True)
    
    # Registration
    requires_registration = models.BooleanField(default=False)
    max_attendees = models.IntegerField(blank=True, null=True)
    registration_deadline = models.DateTimeField(blank=True, null=True)
    
    # Category
    category = models.CharField(
        max_length=50,
        choices=[
            ('worship', 'Worship Service'),
            ('conference', 'Conference'),
            ('seminar', 'Seminar'),
            ('fellowship', 'Fellowship'),
            ('outreach', 'Outreach'),
            ('youth', 'Youth Event'),
            ('other', 'Other'),
        ],
        default='other'
    )
    
    organizer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='organized_events'
    )
    
    is_published = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['start_date']
    
    def __str__(self):
        return self.title


class EventRegistration(models.Model):
    """Event registration tracking"""
    
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='registrations')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    
    registered_at = models.DateTimeField(auto_now_add=True)
    attended = models.BooleanField(default=False)
    
    class Meta:
        unique_together = ['event', 'user']
        ordering = ['-registered_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.event.title}"


class PrayerRequest(models.Model):
    """Prayer requests from members"""
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='prayer_requests'
    )
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    
    is_anonymous = models.BooleanField(default=False)
    is_answered = models.BooleanField(default=False)
    
    priority = models.CharField(
        max_length=20,
        choices=[
            ('NORMAL', 'Normal'),
            ('HIGH', 'High Priority'),
            ('URGENT', 'Urgent'),
        ],
        default='NORMAL'
    )
    
    category = models.CharField(
        max_length=50,
        choices=[
            ('health', 'Health'),
            ('family', 'Family'),
            ('finance', 'Finance'),
            ('spiritual', 'Spiritual'),
            ('other', 'Other'),
        ],
        default='other'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        if self.is_anonymous:
            return f"Anonymous - {self.title}"
        return f"{self.user.username} - {self.title}"


class PrayerSupport(models.Model):
    """Track who is praying for requests"""
    
    prayer_request = models.ForeignKey(
        PrayerRequest,
        on_delete=models.CASCADE,
        related_name='supporters'
    )
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['prayer_request', 'user']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} praying for {self.prayer_request.title}"


class PrayerRequestImage(models.Model):
    """Images attached to prayer requests (multiple images per prayer)"""
    
    prayer_request = models.ForeignKey(
        PrayerRequest,
        on_delete=models.CASCADE,
        related_name='images'
    )
    image = models.ImageField(upload_to='prayer_requests/')
    caption = models.CharField(max_length=200, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['uploaded_at']
    
    def __str__(self):
        return f"Image for {self.prayer_request.title}"


class PrayerComment(models.Model):
    """Comments on prayer requests"""
    
    prayer_request = models.ForeignKey(
        PrayerRequest,
        on_delete=models.CASCADE,
        related_name='comments'
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='prayer_comments'
    )
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} on {self.prayer_request.title}"


class Testimony(models.Model):
    """Member testimonies"""
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='testimonies'
    )
    
    # Link to prayer request (optional)
    prayer_request = models.ForeignKey(
        'PrayerRequest',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='testimonies',
        help_text='Link testimony to a prayer request'
    )
    
    title = models.CharField(max_length=200)
    content = models.TextField()
    
    # Media files
    photo = models.ImageField(upload_to='testimonies/photos/', blank=True, null=True)
    video = models.FileField(upload_to='testimonies/videos/', blank=True, null=True)
    thumbnail = models.ImageField(upload_to='testimonies/thumbnails/', blank=True, null=True, help_text='Thumbnail for Sunday Service testimonies')
    
    # Testimony type
    TESTIMONY_TYPE_CHOICES = [
        ('regular', 'Regular Testimony'),
        ('sunday_service', 'Sunday Service Testimony'),
    ]
    testimony_type = models.CharField(
        max_length=20,
        choices=TESTIMONY_TYPE_CHOICES,
        default='regular',
        help_text='Type of testimony - regular or Sunday service'
    )
    
    # Category
    CATEGORY_CHOICES = [
        ('healing', 'Healing'),
        ('financial', 'Financial Breakthrough'),
        ('family', 'Family Restoration'),
        ('salvation', 'Salvation'),
        ('deliverance', 'Deliverance'),
        ('career', 'Career/Job'),
        ('answered_prayer', 'Answered Prayer'),
        ('other', 'Other'),
    ]
    category = models.CharField(
        max_length=50,
        choices=CATEGORY_CHOICES,
        default='other'
    )
    
    is_anonymous = models.BooleanField(default=False)
    is_approved = models.BooleanField(default=False)
    is_featured = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name_plural = 'Testimonies'
    
    def __str__(self):
        if self.is_anonymous:
            return f"Anonymous - {self.title}"
        return f"{self.user.username} - {self.title}"
    
    @property
    def has_photo(self):
        """Check if testimony has photo"""
        return bool(self.photo)
    
    @property
    def has_video(self):
        """Check if testimony has video"""
        return bool(self.video)


class TestimonyPraise(models.Model):
    """Testimony praise/like system"""
    
    testimony = models.ForeignKey(
        Testimony,
        on_delete=models.CASCADE,
        related_name='praises'
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='testimony_praises'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['testimony', 'user']
        ordering = ['-created_at']
        verbose_name_plural = 'Testimony Praises'
    
    def __str__(self):
        return f"{self.user.username} praised {self.testimony.title}"


class Giving(models.Model):
    """Track giving/donations with comprehensive payment tracking"""
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='donations',
        null=True,
        blank=True,
        help_text='User who made the donation (null for anonymous)'
    )
    
    # Donor Information
    donor_name = models.CharField(max_length=200, blank=True, help_text='Name of donor (for anonymous or guest donations)')
    donor_email = models.EmailField(blank=True)
    donor_phone = models.CharField(max_length=20, blank=True)
    
    # Amount and Currency
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(
        max_length=3,
        default='USD',
        choices=[
            ('USD', 'US Dollar'),
            ('EUR', 'Euro'),
            ('GBP', 'British Pound'),
            ('KES', 'Kenyan Shilling'),
            ('TZS', 'Tanzanian Shilling'),
            ('UGX', 'Ugandan Shilling'),
            ('RWF', 'Rwandan Franc'),
        ]
    )
    
    # Giving Details
    giving_type = models.CharField(
        max_length=50,
        choices=[
            ('tithe', 'Tithe'),
            ('offering', 'Offering'),
            ('special', 'Special Offering'),
            ('pledge', 'Pledge'),
            ('mission', 'Mission'),
            ('building', 'Building Fund'),
            ('other', 'Other'),
        ]
    )
    
    # Payment Information
    payment_method = models.CharField(
        max_length=50,
        choices=[
            ('mpesa', 'M-Pesa'),
            ('airtel_money', 'Airtel Money'),
            ('mtn_money', 'MTN Mobile Money'),
            ('tigo_pesa', 'Tigo Pesa'),
            ('credit_card', 'Credit Card'),
            ('debit_card', 'Debit Card'),
            ('bank_transfer', 'Bank Transfer'),
            ('cash', 'Cash'),
            ('other', 'Other'),
        ]
    )
    
    # Transaction References
    transaction_ref = models.CharField(
        max_length=100, 
        blank=True,
        help_text='Payment gateway transaction reference'
    )
    merchant_reference = models.CharField(
        max_length=100,
        unique=True,
        blank=True,
        null=True,
        help_text='Internal merchant reference for the transaction'
    )
    pesapal_tracking_id = models.CharField(
        max_length=100,
        blank=True,
        help_text='Pesapal order tracking ID'
    )
    confirmation_code = models.CharField(
        max_length=100,
        blank=True,
        help_text='Payment confirmation code from payment provider'
    )
    
    # Payment Status
    PAYMENT_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
        ('refunded', 'Refunded'),
    ]
    payment_status = models.CharField(
        max_length=20,
        choices=PAYMENT_STATUS_CHOICES,
        default='pending'
    )
    
    # Additional Details
    notes = models.TextField(blank=True, help_text='Additional notes from donor')
    is_anonymous = models.BooleanField(default=False)
    is_recurring = models.BooleanField(default=False)
    recurring_frequency = models.CharField(
        max_length=20,
        blank=True,
        choices=[
            ('weekly', 'Weekly'),
            ('monthly', 'Monthly'),
            ('quarterly', 'Quarterly'),
            ('yearly', 'Yearly'),
        ]
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Giving'
        verbose_name_plural = 'Givings'
    
    def __str__(self):
        donor = self.donor_name if self.is_anonymous else (self.user.username if self.user else 'Anonymous')
        return f"{donor} - {self.giving_type} - {self.currency} {self.amount}"
    
    def mark_completed(self):
        """Mark donation as completed"""
        self.payment_status = 'completed'
        self.completed_at = timezone.now()
        self.save()
    
    def mark_failed(self):
        """Mark donation as failed"""
        self.payment_status = 'failed'
        self.save()


class PaymentTransaction(models.Model):
    """Detailed payment transaction log - stores ALL transaction attempts"""
    
    giving = models.ForeignKey(
        Giving,
        on_delete=models.CASCADE,
        related_name='transactions',
        help_text='Related giving record'
    )
    
    # Transaction Details
    transaction_id = models.CharField(max_length=200, unique=True)
    order_tracking_id = models.CharField(max_length=200, blank=True)
    merchant_reference = models.CharField(max_length=200)
    
    # Payment Gateway Info
    gateway = models.CharField(
        max_length=50,
        choices=[
            ('pesapal', 'Pesapal'),
            ('mpesa', 'M-Pesa STK Push'),
            ('stripe', 'Stripe'),
            ('paypal', 'PayPal'),
            ('manual', 'Manual Entry'),
        ],
        default='pesapal'
    )
    
    # Transaction Status
    status = models.CharField(
        max_length=20,
        choices=[
            ('initiated', 'Initiated'),
            ('pending', 'Pending'),
            ('processing', 'Processing'),
            ('completed', 'Completed'),
            ('failed', 'Failed'),
            ('cancelled', 'Cancelled'),
            ('refunded', 'Refunded'),
        ],
        default='initiated'
    )
    
    # Payment Details
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3)
    payment_method = models.CharField(max_length=50, blank=True)
    payment_account = models.CharField(max_length=100, blank=True, help_text='Phone number or card last 4 digits')
    
    # Response Data
    confirmation_code = models.CharField(max_length=200, blank=True)
    payment_status_description = models.TextField(blank=True)
    error_message = models.TextField(blank=True)
    
    # Raw Data (for debugging and auditing)
    request_data = models.JSONField(blank=True, null=True, help_text='Request payload sent to payment gateway')
    response_data = models.JSONField(blank=True, null=True, help_text='Response from payment gateway')
    callback_data = models.JSONField(blank=True, null=True, help_text='Callback/IPN data received')
    
    # IP and User Agent (for security)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Payment Transaction'
        verbose_name_plural = 'Payment Transactions'
        indexes = [
            models.Index(fields=['transaction_id']),
            models.Index(fields=['order_tracking_id']),
            models.Index(fields=['merchant_reference']),
            models.Index(fields=['status']),
        ]
    
    def __str__(self):
        return f"{self.gateway} - {self.merchant_reference} - {self.status}"
    
    def mark_completed(self, confirmation_code='', payment_method=''):
        """Mark transaction as completed"""
        self.status = 'completed'
        self.completed_at = timezone.now()
        if confirmation_code:
            self.confirmation_code = confirmation_code
        if payment_method:
            self.payment_method = payment_method
        self.save()
        
        # Also mark the giving as completed
        self.giving.mark_completed()
    
    def mark_failed(self, error_message=''):
        """Mark transaction as failed"""
        self.status = 'failed'
        if error_message:
            self.error_message = error_message
        self.save()
        
        # Also mark giving as failed
        self.giving.mark_failed()


class Announcement(models.Model):
    """Church announcements"""
    
    title = models.CharField(max_length=200)
    content = models.TextField()
    
    image = models.ImageField(upload_to='announcements/', blank=True, null=True)
    
    priority = models.CharField(
        max_length=20,
        choices=[
            ('low', 'Low'),
            ('medium', 'Medium'),
            ('high', 'High'),
            ('urgent', 'Urgent'),
        ],
        default='medium'
    )
    
    is_published = models.BooleanField(default=True)
    publish_date = models.DateTimeField()
    expiry_date = models.DateTimeField(blank=True, null=True)
    
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-priority', '-publish_date']
    
    def __str__(self):
        return self.title


class LiveStream(models.Model):
    """YouTube Live Stream Management"""
    
    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('live', 'Live'),
        ('ended', 'Ended'),
    ]
    
    title = models.CharField(max_length=255, help_text="Live stream title")
    youtube_url = models.URLField(help_text="YouTube live stream URL")
    youtube_video_id = models.CharField(max_length=100, help_text="YouTube video ID")
    description = models.TextField(help_text="Stream description")
    thumbnail_url = models.URLField(blank=True, null=True, help_text="Stream thumbnail URL")
    
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='scheduled',
        help_text="Stream status"
    )
    
    scheduled_for = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the stream is scheduled"
    )
    
    viewer_count = models.IntegerField(default=0, help_text="Current viewer count")
    
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_streams',
        help_text="User who created this stream"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Live Stream'
        verbose_name_plural = 'Live Streams'
        indexes = [
            models.Index(fields=['-created_at']),
            models.Index(fields=['status']),
            models.Index(fields=['scheduled_for']),
        ]
    
    def __str__(self):
        return f"{self.title} ({self.status})"


class LiveChatMessage(models.Model):
    """Live chat messages for live streams"""
    
    live_stream = models.ForeignKey(
        LiveStream,
        on_delete=models.CASCADE,
        related_name='chat_messages',
        help_text="Associated live stream"
    )
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='live_chat_messages',
        help_text="User who sent the message"
    )
    
    user_name = models.CharField(
        max_length=100,
        help_text="Name to display (stored for deleted users)"
    )
    
    message = models.TextField(help_text="Chat message content")
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['created_at']
        verbose_name = 'Live Chat Message'
        verbose_name_plural = 'Live Chat Messages'
        indexes = [
            models.Index(fields=['live_stream', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.user_name}: {self.message[:50]}..."
    
    def save(self, *args, **kwargs):
        # Store user's name for display even if user is deleted
        if self.user and not self.user_name:
            self.user_name = self.user.get_full_name() or self.user.username
        super().save(*args, **kwargs)
