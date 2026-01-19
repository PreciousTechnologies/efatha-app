"""
Email Verification Models
Handles 4-digit verification codes for user authentication
"""
from django.db import models
from django.utils import timezone
from datetime import timedelta
import random
import string


class VerificationCode(models.Model):
    """
    Stores 4-digit verification codes sent via email
    Codes expire after 10 minutes for security
    """
    email = models.EmailField()
    code = models.CharField(max_length=4)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    purpose = models.CharField(
        max_length=20,
        choices=[
            ('login', 'Login Verification'),
            ('registration', 'Registration Verification'),
            ('password_reset', 'Password Reset'),
        ],
        default='login'
    )

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['email', 'code', 'is_used']),
            models.Index(fields=['expires_at']),
        ]

    def save(self, *args, **kwargs):
        if not self.expires_at:
            # Code expires in 10 minutes
            self.expires_at = timezone.now() + timedelta(minutes=10)
        super().save(*args, **kwargs)

    def is_valid(self):
        """Check if code is still valid (not expired and not used)"""
        return (
            not self.is_used and
            timezone.now() < self.expires_at
        )

    def mark_as_used(self):
        """Mark code as used"""
        self.is_used = True
        self.save(update_fields=['is_used'])

    @staticmethod
    def generate_code():
        """Generate random 4-digit code"""
        return ''.join(random.choices(string.digits, k=4))

    @classmethod
    def create_code(cls, email, purpose='login'):
        """Create a new verification code for email"""
        # Invalidate any existing unused codes for this email and purpose
        cls.objects.filter(
            email=email,
            purpose=purpose,
            is_used=False
        ).update(is_used=True)

        # Generate new code
        code = cls.generate_code()
        
        return cls.objects.create(
            email=email,
            code=code,
            purpose=purpose
        )

    @classmethod
    def verify_code(cls, email, code, purpose='login'):
        """Verify a code for given email and purpose"""
        try:
            verification = cls.objects.get(
                email=email,
                code=code,
                purpose=purpose,
                is_used=False
            )
            
            if verification.is_valid():
                verification.mark_as_used()
                return True
            return False
        except cls.DoesNotExist:
            return False

    @classmethod
    def cleanup_expired(cls):
        """Delete expired codes (run periodically via cron/celery)"""
        expired_time = timezone.now() - timedelta(hours=24)
        cls.objects.filter(created_at__lt=expired_time).delete()

    def __str__(self):
        return f"{self.email} - {self.code} ({self.purpose}) - Valid: {self.is_valid()}"
