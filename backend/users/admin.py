from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, UserProfile
from .models_verification import VerificationCode


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['username', 'email', 'first_name', 'last_name', 'role', 'created_at']
    list_filter = ['role', 'is_staff', 'is_active']
    search_fields = ['username', 'email', 'first_name', 'last_name', 'membership_number']
    
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Church Role', {'fields': ('role',)}),
        ('Church Info', {'fields': ('phone_number', 'membership_number')}),
        ('Personal Info', {'fields': ('profile_picture', 'date_of_birth', 'bio', 'address')}),
        ('Preferences', {'fields': ('receive_notifications', 'preferred_language')}),
    )
    
    def get_readonly_fields(self, request, obj=None):
        # Only admins and leadership can change roles
        if obj and not request.user.can_manage_users():
            return self.readonly_fields + ('role',)
        return self.readonly_fields


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'ministry', 'marital_status', 'salvation_date']
    search_fields = ['user__username', 'user__email', 'ministry']
    list_filter = ['marital_status']


@admin.register(VerificationCode)
class VerificationCodeAdmin(admin.ModelAdmin):
    list_display = ['email', 'code', 'purpose', 'created_at', 'expires_at', 'is_used', 'is_valid_display']
    list_filter = ['purpose', 'is_used', 'created_at']
    search_fields = ['email', 'code']
    readonly_fields = ['created_at', 'expires_at']
    ordering = ['-created_at']
    
    def is_valid_display(self, obj):
        return obj.is_valid()
    is_valid_display.short_description = 'Valid'
    is_valid_display.boolean = True
    
    actions = ['mark_as_used', 'cleanup_expired']
    
    def mark_as_used(self, request, queryset):
        updated = queryset.update(is_used=True)
        self.message_user(request, f'{updated} codes marked as used.')
    mark_as_used.short_description = 'Mark selected codes as used'
    
    def cleanup_expired(self, request, queryset):
        from django.utils import timezone
        expired = queryset.filter(expires_at__lt=timezone.now()).delete()
        self.message_user(request, f'Cleaned up {expired[0]} expired codes.')
    cleanup_expired.short_description = 'Delete expired codes'
