from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Custom User model for Efatha Church App"""
    
    # Role choices for Efatha Church
    ROLE_CHOICES = [
        ('admin', 'Admin'),
        ('chief_apostle', 'Chief Apostle'),
        ('katibu_kiongozi', 'Katibu Kiongozi'),
        ('apostle', 'Apostle'),
        ('senior_pastor', 'Senior Pastor'),
        ('bishop', 'Bishop'),
        ('editor', 'Editor'),
        ('data_entry', 'Data Entry'),
        ('member', 'Member'),
    ]
    
    # Church Position choices (Swahili)
    CHURCH_POSITION_CHOICES = [
        ('mtume_mkuu', 'Mtume Mkuu'),
        ('msaidizi_binafsi_mtume', 'Msaidizi Binafsi wa Mtume Mkuu'),
        ('mtume', 'Mtume'),
        ('mchungaji_kiongozi', 'Mchungaji Kiongozi'),
        ('mchungaji', 'Mchungaji'),
        ('katibu', 'Katibu'),
        ('mtawala', 'Mtawala'),
        ('askofu', 'Askofu'),
        ('cell_leader', 'Cell Leader'),
        ('mweka_hazina', 'Mweka Hazina'),
        ('mwanakamati', 'Mwanakamati'),
        ('mjumbe_board', 'Mjumbe wa Board'),
        ('funguka', 'Funguka'),
        ('ict', 'ICT'),
        ('tv', 'TV'),
        ('sunday_school_teacher', 'Sunday School Teacher'),
        ('walinzi', 'Walinzi'),
        ('muumini', 'Muumini'),
    ]
    
    # Country choices
    COUNTRY_CHOICES = [
        ('tanzania', 'Tanzania'),
        ('kenya', 'Kenya'),
        ('malawi', 'Malawi'),
        ('zambia', 'Zambia'),
        ('rwanda', 'Rwanda'),
        ('burundi', 'Burundi'),
        ('congo', 'Republic of Congo'),
        ('mozambique', 'Mozambique'),
        ('botswana', 'Botswana'),
        ('south_africa', 'South Africa'),
        ('south_sudan', 'South Sudan'),
        ('uk', 'UK'),
        ('usa', 'USA'),
        ('pakistan', 'Pakistan'),
        ('india', 'India'),
    ]
    
    # Personal Information from Onboarding
    middle_name = models.CharField(max_length=150, blank=True, null=True)
    gender = models.CharField(max_length=20, blank=True, null=True, help_text='Male, Female, Other')
    date_of_birth = models.DateField(blank=True, null=True)
    marital_status = models.CharField(max_length=50, blank=True, null=True, help_text='Single, Married, Divorced, Widowed')
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    profile_picture = models.ImageField(upload_to='profiles/', blank=True, null=True)
    
    # Church role and membership
    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default='member',
        help_text='User role in the church system'
    )
    
    church_position = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        help_text='Position in church'
    )
    
    membership_number = models.CharField(max_length=50, blank=True, null=True, help_text='Church membership number')
    
    # Location information
    country = models.CharField(max_length=100, blank=True, null=True)
    region = models.CharField(max_length=100, blank=True, null=True, help_text='Region/State')
    service_region = models.CharField(max_length=100, blank=True, null=True, help_text='Service region (Mikoa)')
    city = models.CharField(max_length=100, blank=True, null=True, help_text='District/City')
    residence = models.CharField(max_length=200, blank=True, null=True, help_text='Residence area')
    street = models.CharField(max_length=200, blank=True, null=True)
    house_number = models.CharField(max_length=50, blank=True, null=True)
    postal_address = models.CharField(max_length=200, blank=True, null=True)
    
    # Additional info
    bio = models.TextField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    
    # Preferences
    receive_notifications = models.BooleanField(default=True)
    preferred_language = models.CharField(
        max_length=10,
        choices=[('en', 'English'), ('sw', 'Swahili')],
        default='en'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return self.email or self.username
    
    def get_role_display_name(self):
        """Get human-readable role name"""
        return dict(self.ROLE_CHOICES).get(self.role, 'Member')
    
    def has_leadership_role(self):
        """Check if user has any leadership role"""
        leadership_roles = [
            'admin', 'chief_apostle', 'katibu_kiongozi',
            'apostle', 'senior_pastor', 'bishop'
        ]
        return self.role in leadership_roles
    
    def can_edit_content(self):
        """Check if user can edit content"""
        return self.role in ['admin', 'editor', 'data_entry'] or self.has_leadership_role()
    
    def can_approve_content(self):
        """Check if user can approve content (testimonies, prayers, etc.)"""
        return self.role in ['admin', 'bishop', 'senior_pastor', 'chief_apostle']
    
    def can_manage_users(self):
        """Check if user can manage other users"""
        return self.role in ['admin', 'chief_apostle', 'katibu_kiongozi']


class UserProfile(models.Model):
    """Extended user profile information"""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    
    # Spiritual information
    salvation_date = models.DateField(blank=True, null=True)
    baptism_date = models.DateField(blank=True, null=True)
    ministry = models.CharField(max_length=100, blank=True, null=True)
    
    # Emergency contact
    emergency_contact_name = models.CharField(max_length=100, blank=True, null=True)
    emergency_contact_phone = models.CharField(max_length=15, blank=True, null=True)
    
    # Family
    marital_status = models.CharField(
        max_length=20,
        choices=[
            ('single', 'Single'),
            ('married', 'Married'),
            ('divorced', 'Divorced'),
            ('widowed', 'Widowed'),
        ],
        blank=True,
        null=True
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.username}'s Profile"
