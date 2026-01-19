# Profile Edit Functionality - Backend Requirements

## 📋 Overview

The Profile Edit functionality allows users to update all their personal information from the Flutter app. Changes are saved to the Django database and immediately reflected in the app.

---

## 🔧 Backend Endpoint Required

### Update Profile Endpoint

**Endpoint:** `PATCH /api/auth/users/update_profile/`

**Authentication:** Required (Bearer Token)

**Request Body:**
```json
{
  "first_name": "John",
  "middle_name": "Smith",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "phone_number": "+1234567890",
  "date_of_birth": "1990-01-15",
  "gender": "Male",
  "marital_status": "Married",
  "country": "United States",
  "region": "California",
  "city": "Los Angeles",
  "residence": "Downtown",
  "street": "Main Street",
  "house_number": "123A",
  "postal_address": "P.O. Box 456",
  "church_position": "Deacon",
  "service_region": "Youth Ministry",
  "bio": "A dedicated member serving in the church..."
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "username": "johndoe",
  "email": "john.doe@example.com",
  "first_name": "John",
  "middle_name": "Smith",
  "last_name": "Doe",
  "phone_number": "+1234567890",
  "date_of_birth": "1990-01-15",
  "gender": "Male",
  "marital_status": "Married",
  "country": "United States",
  "region": "California",
  "city": "Los Angeles",
  "residence": "Downtown",
  "street": "Main Street",
  "house_number": "123A",
  "postal_address": "P.O. Box 456",
  "church_position": "Deacon",
  "service_region": "Youth Ministry",
  "membership_number": "MEM001",
  "role": "member",
  "role_display": "Member",
  "bio": "A dedicated member serving in the church...",
  "profile_picture": "http://example.com/media/profiles/john.jpg",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-10-13T12:00:00Z"
}
```

---

## Django Implementation

### Step 1: Update Views

**File:** `your_app/views.py`

```python
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .serializers import UserSerializer

@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    """
    Update user profile information
    """
    user = request.user
    
    # Get the fields that can be updated
    allowed_fields = [
        'first_name', 'middle_name', 'last_name', 'email',
        'phone_number', 'date_of_birth', 'gender', 'marital_status',
        'country', 'region', 'city', 'residence', 'street',
        'house_number', 'postal_address', 'church_position',
        'service_region', 'bio'
    ]
    
    # Update User model fields (first_name, last_name, email)
    user_fields = ['first_name', 'last_name', 'email']
    for field in user_fields:
        if field in request.data:
            setattr(user, field, request.data[field])
    
    try:
        user.save()
    except Exception as e:
        return Response(
            {'detail': f'Failed to update user: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Update UserProfile fields
    profile = user.profile  # Assuming OneToOne relationship
    profile_fields = [f for f in allowed_fields if f not in user_fields]
    
    for field in profile_fields:
        if field in request.data:
            setattr(profile, field, request.data[field])
    
    try:
        profile.save()
    except Exception as e:
        return Response(
            {'detail': f'Failed to update profile: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Return updated user data
    serializer = UserSerializer(user)
    return Response(serializer.data, status=status.HTTP_200_OK)
```

### Step 2: Update URL Routes

**File:** `your_app/urls.py`

```python
from django.urls import path
from .views import update_profile

urlpatterns = [
    # ... existing urls
    path('users/update_profile/', update_profile, name='update_profile'),
]
```

### Step 3: Ensure UserProfile Model Has Required Fields

**File:** `your_app/models.py`

```python
from django.db import models
from django.contrib.auth.models import User

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    
    # Personal Information
    middle_name = models.CharField(max_length=100, blank=True, null=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    date_of_birth = models.DateField(blank=True, null=True)
    gender = models.CharField(
        max_length=10,
        choices=[('Male', 'Male'), ('Female', 'Female'), ('Other', 'Other')],
        blank=True,
        null=True
    )
    marital_status = models.CharField(
        max_length=20,
        choices=[
            ('Single', 'Single'),
            ('Married', 'Married'),
            ('Divorced', 'Divorced'),
            ('Widowed', 'Widowed')
        ],
        blank=True,
        null=True
    )
    
    # Location Information
    country = models.CharField(max_length=100, blank=True, null=True)
    region = models.CharField(max_length=100, blank=True, null=True)
    city = models.CharField(max_length=100, blank=True, null=True)
    residence = models.CharField(max_length=200, blank=True, null=True)
    street = models.CharField(max_length=200, blank=True, null=True)
    house_number = models.CharField(max_length=50, blank=True, null=True)
    postal_address = models.CharField(max_length=200, blank=True, null=True)
    
    # Church Information
    church_position = models.CharField(max_length=100, blank=True, null=True)
    service_region = models.CharField(max_length=100, blank=True, null=True)
    membership_number = models.CharField(max_length=50, unique=True, blank=True, null=True)
    role = models.CharField(
        max_length=20,
        choices=[
            ('admin', 'Admin'),
            ('pastor', 'Pastor'),
            ('elder', 'Elder'),
            ('deacon', 'Deacon'),
            ('member', 'Member')
        ],
        default='member'
    )
    
    # Other
    bio = models.TextField(max_length=500, blank=True, null=True)
    profile_picture = models.ImageField(
        upload_to='profiles/',
        blank=True,
        null=True
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.username}'s Profile"
    
    @property
    def role_display(self):
        return dict(self._meta.get_field('role').choices).get(self.role, self.role)
```

### Step 4: Update Serializer

**File:** `your_app/serializers.py`

```python
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile

class UserSerializer(serializers.ModelSerializer):
    # Include profile fields
    middle_name = serializers.CharField(source='profile.middle_name', read_only=False, required=False, allow_blank=True)
    phone_number = serializers.CharField(source='profile.phone_number', read_only=False, required=False, allow_blank=True)
    date_of_birth = serializers.DateField(source='profile.date_of_birth', read_only=False, required=False, allow_null=True)
    gender = serializers.CharField(source='profile.gender', read_only=False, required=False, allow_blank=True)
    marital_status = serializers.CharField(source='profile.marital_status', read_only=False, required=False, allow_blank=True)
    country = serializers.CharField(source='profile.country', read_only=False, required=False, allow_blank=True)
    region = serializers.CharField(source='profile.region', read_only=False, required=False, allow_blank=True)
    city = serializers.CharField(source='profile.city', read_only=False, required=False, allow_blank=True)
    residence = serializers.CharField(source='profile.residence', read_only=False, required=False, allow_blank=True)
    street = serializers.CharField(source='profile.street', read_only=False, required=False, allow_blank=True)
    house_number = serializers.CharField(source='profile.house_number', read_only=False, required=False, allow_blank=True)
    postal_address = serializers.CharField(source='profile.postal_address', read_only=False, required=False, allow_blank=True)
    church_position = serializers.CharField(source='profile.church_position', read_only=False, required=False, allow_blank=True)
    service_region = serializers.CharField(source='profile.service_region', read_only=False, required=False, allow_blank=True)
    membership_number = serializers.CharField(source='profile.membership_number', read_only=True)
    role = serializers.CharField(source='profile.role', read_only=True)
    role_display = serializers.CharField(source='profile.role_display', read_only=True)
    bio = serializers.CharField(source='profile.bio', read_only=False, required=False, allow_blank=True)
    profile_picture = serializers.ImageField(source='profile.profile_picture', read_only=True)
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'middle_name', 'phone_number', 'date_of_birth', 'gender',
            'marital_status', 'country', 'region', 'city', 'residence',
            'street', 'house_number', 'postal_address', 'church_position',
            'service_region', 'membership_number', 'role', 'role_display',
            'bio', 'profile_picture'
        ]
        read_only_fields = ['id', 'username', 'membership_number', 'role', 'role_display']
```

---

## Testing the Endpoint

### Using cURL

```bash
curl -X PATCH http://10.103.160.233:8000/api/auth/users/update_profile/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone_number": "+1234567890",
    "city": "Los Angeles",
    "bio": "Updated bio text"
  }'
```

### Using Python Requests

```python
import requests

url = "http://10.103.160.233:8000/api/auth/users/update_profile/"
headers = {
    "Authorization": "Bearer YOUR_ACCESS_TOKEN",
    "Content-Type": "application/json"
}
data = {
    "first_name": "John",
    "last_name": "Doe",
    "city": "Los Angeles",
    "bio": "Updated bio"
}

response = requests.patch(url, json=data, headers=headers)
print(response.json())
```

---

## Frontend Usage

The Edit Profile screen is now integrated into your app:

1. **Navigate to Profile**: More → Profile tab
2. **Tap Edit Button**: Top right corner (pencil icon)
3. **Edit Information**: All fields are editable
4. **Save Changes**: Tap "Save" button
5. **Changes Synced**: Data is saved to database and updated locally

### Features Implemented:

✅ **Full Edit Functionality** - All user fields can be edited
✅ **Form Validation** - Required fields validated before save
✅ **Date Picker** - For date of birth selection
✅ **Dropdown Menus** - For gender and marital status
✅ **Auto-Save to Database** - Changes saved via API
✅ **Local Storage Update** - User data updated in SharedPreferences
✅ **Success Feedback** - Visual confirmation when saved
✅ **Bio Repositioned** - Moved to last position after Contact Information
✅ **Edit Button in AppBar** - Easy access to edit mode

---

## Field Ordering in Profile Screen

**New Order:**
1. Personal Information
2. Church Information
3. Location Information
4. Contact Information
5. **Bio** (moved to last position) ✅

---

## Security Considerations

### 1. **Authentication Required**
- User must be logged in (Bearer token)
- Can only edit own profile

### 2. **Field Protection**
- `username` - Read-only (cannot be changed)
- `membership_number` - Read-only (admin only)
- `role` - Read-only (admin only)

### 3. **Input Validation**
- Email format validation
- Phone number format validation
- Date validation (not future dates)
- Text length limits (bio: 500 chars)

### 4. **Permissions**
```python
permission_classes = [IsAuthenticated]
```

---

## Migration Required

If adding new fields, run migrations:

```bash
python manage.py makemigrations
python manage.py migrate
```

---

## Testing Checklist

- [ ] Backend endpoint exists (`/api/auth/users/update_profile/`)
- [ ] User can edit first name, middle name, last name
- [ ] User can edit contact information (email, phone, postal address)
- [ ] User can edit location information (country, region, city, etc.)
- [ ] User can edit church information (position, service region)
- [ ] User can edit bio (moved to last position)
- [ ] Date picker works for date of birth
- [ ] Gender dropdown works
- [ ] Marital status dropdown works
- [ ] Form validation works (required fields)
- [ ] Save button updates database
- [ ] Profile screen refreshes after save
- [ ] Success message appears
- [ ] Data persists after app restart
- [ ] Bio appears in last position after Contact Information

---

## Troubleshooting

### Issue: "Failed to update profile"

**Check:**
1. Backend endpoint exists
2. User is authenticated
3. Field names match backend model
4. No validation errors

### Issue: "Bio not in last position"

**Solution:** Already fixed! Bio card is now positioned after Contact Information.

### Issue: "Changes not saving"

**Check:**
1. Network connection
2. Access token valid
3. Backend endpoint returns 200
4. Check console for errors

---

**Status:** ✅ READY TO USE  
**Last Updated:** October 13, 2025  
**Features:** Full profile editing + Bio repositioned to last
