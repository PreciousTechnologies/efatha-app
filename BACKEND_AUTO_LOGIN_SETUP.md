# Backend Requirements for Auto-Login

## Django REST API Endpoints Needed

### 1. Login Endpoint ✅ (Already Implemented)

**Endpoint:** `POST /api/auth/login-password/`

**Request:**
```json
{
  "username": "john_doe",
  "password": "SecurePass123"
}
```

**Response (200 OK):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "member",
    "church_position": "Deacon",
    "membership_number": "MEM001"
  }
}
```

---

### 2. Refresh Token Endpoint ✅ (Already Implemented)

**Endpoint:** `POST /api/auth/refresh/`

**Request:**
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Response (200 OK):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Error Response (401 Unauthorized):**
```json
{
  "detail": "Token is invalid or expired",
  "code": "token_not_valid"
}
```

---

### 3. Verify Token Endpoint ⚠️ (NEEDS TO BE ADDED)

**Endpoint:** `POST /api/auth/verify/`

**Request:**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Response (200 OK):**
```json
{
  "valid": true
}
```

**Error Response (401 Unauthorized):**
```json
{
  "detail": "Token is invalid or expired",
  "code": "token_not_valid"
}
```

---

## Django Implementation

### Step 1: Install Django REST Framework SimpleJWT

If not already installed:

```bash
pip install djangorestframework-simplejwt
```

### Step 2: Configure Settings

**File:** `settings.py`

```python
from datetime import timedelta

INSTALLED_APPS = [
    # ...
    'rest_framework',
    'rest_framework_simplejwt',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,

    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'VERIFYING_KEY': None,
    'AUDIENCE': None,
    'ISSUER': None,

    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',

    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
    'TOKEN_TYPE_CLAIM': 'token_type',

    'JTI_CLAIM': 'jti',
}
```

### Step 3: Add URL Routes

**File:** `urls.py`

```python
from django.urls import path
from rest_framework_simplejwt.views import (
    TokenRefreshView,
    TokenVerifyView,
)
from .views import CustomLoginView

urlpatterns = [
    # Login endpoint (custom view with user data)
    path('auth/login-password/', CustomLoginView.as_view(), name='login'),
    
    # Token refresh endpoint
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Token verify endpoint ⚠️ ADD THIS
    path('auth/verify/', TokenVerifyView.as_view(), name='token_verify'),
]
```

### Step 4: Create Custom Login View

**File:** `views.py`

```python
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .serializers import UserSerializer

class CustomLoginView(APIView):
    """
    Custom login view that returns JWT tokens + user data
    """
    permission_classes = []  # Allow any user to login
    
    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        
        if not username or not password:
            return Response(
                {'detail': 'Username and password are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Authenticate user
        user = authenticate(username=username, password=password)
        
        if user is None:
            return Response(
                {'detail': 'Invalid credentials'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        if not user.is_active:
            return Response(
                {'detail': 'User account is disabled'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Generate tokens
        refresh = RefreshToken.for_user(user)
        
        # Serialize user data
        user_data = UserSerializer(user).data
        
        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': user_data
        }, status=status.HTTP_200_OK)
```

### Step 5: Create User Serializer

**File:** `serializers.py`

```python
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile  # Your custom profile model

class UserSerializer(serializers.ModelSerializer):
    # Include profile fields
    role = serializers.CharField(source='profile.role', read_only=True)
    church_position = serializers.CharField(source='profile.church_position', read_only=True)
    membership_number = serializers.CharField(source='profile.membership_number', read_only=True)
    phone_number = serializers.CharField(source='profile.phone_number', read_only=True)
    
    class Meta:
        model = User
        fields = [
            'id',
            'username',
            'email',
            'first_name',
            'last_name',
            'role',
            'church_position',
            'membership_number',
            'phone_number'
        ]
```

---

## Testing the Endpoints

### 1. Test Login

```bash
curl -X POST http://10.103.160.233:8000/api/auth/login-password/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "password": "SecurePass123"
  }'
```

**Expected Response:**
```json
{
  "access": "eyJ0eXAiOiJKV1Qi...",
  "refresh": "eyJ0eXAiOiJKV1Qi...",
  "user": { ... }
}
```

### 2. Test Token Verification

```bash
curl -X POST http://10.103.160.233:8000/api/auth/verify/ \
  -H "Content-Type: application/json" \
  -d '{
    "token": "YOUR_ACCESS_TOKEN_HERE"
  }'
```

**Expected Response (Valid Token):**
```json
{}
```
HTTP Status: `200 OK`

**Expected Response (Invalid Token):**
```json
{
  "detail": "Token is invalid or expired",
  "code": "token_not_valid"
}
```
HTTP Status: `401 Unauthorized`

### 3. Test Token Refresh

```bash
curl -X POST http://10.103.160.233:8000/api/auth/refresh/ \
  -H "Content-Type: application/json" \
  -d '{
    "refresh": "YOUR_REFRESH_TOKEN_HERE"
  }'
```

**Expected Response:**
```json
{
  "access": "NEW_ACCESS_TOKEN_HERE"
}
```

---

## Security Checklist

### ✅ Token Configuration
- [ ] Access token lifetime: 1 hour
- [ ] Refresh token lifetime: 7 days
- [ ] HTTPS enabled in production
- [ ] SECRET_KEY is secure and not in version control

### ✅ CORS Configuration
**File:** `settings.py`

```python
INSTALLED_APPS = [
    'corsheaders',
    # ...
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    # ...
]

# For development
CORS_ALLOW_ALL_ORIGINS = True

# For production (replace with your actual domain)
CORS_ALLOWED_ORIGINS = [
    "https://your-domain.com",
]
```

### ✅ Rate Limiting (Recommended)

Install:
```bash
pip install django-ratelimit
```

**File:** `views.py`

```python
from django_ratelimit.decorators import ratelimit
from django.utils.decorators import method_decorator

@method_decorator(ratelimit(key='ip', rate='5/m', method='POST'), name='dispatch')
class CustomLoginView(APIView):
    # ... your login logic
```

This limits login attempts to 5 per minute per IP address.

---

## Troubleshooting

### Issue: "Token is invalid or expired"

**Causes:**
1. Token actually expired (access token > 1 hour old)
2. Token signature doesn't match (SECRET_KEY changed)
3. Token format is incorrect

**Solution:**
- Check token expiration time in Django settings
- Ensure SECRET_KEY hasn't changed
- Use refresh token to get new access token

### Issue: "No refresh token available"

**Cause:** Refresh token not stored or cleared

**Solution:**
- Check if login response includes `refresh` field
- Verify StorageService.setRefreshToken() is called
- Check SharedPreferences for stored token

### Issue: CORS errors in browser/app

**Cause:** Backend not configured for cross-origin requests

**Solution:**
- Install `django-cors-headers`
- Add to INSTALLED_APPS and MIDDLEWARE
- Configure CORS_ALLOWED_ORIGINS

---

## Production Deployment Checklist

- [ ] Change DEBUG = False
- [ ] Use HTTPS (not HTTP)
- [ ] Set secure SECRET_KEY
- [ ] Configure ALLOWED_HOSTS
- [ ] Enable CORS properly
- [ ] Set up rate limiting
- [ ] Enable token blacklisting
- [ ] Configure proper token lifetimes
- [ ] Set up logging for failed auth attempts
- [ ] Enable database backups
- [ ] Use environment variables for secrets

---

## Token Blacklisting (Optional but Recommended)

### Install Blacklist App

```python
INSTALLED_APPS = [
    # ...
    'rest_framework_simplejwt.token_blacklist',
]
```

### Run Migrations

```bash
python manage.py migrate
```

### Update Settings

```python
SIMPLE_JWT = {
    # ... other settings
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
}
```

### Add Logout View

```python
from rest_framework_simplejwt.tokens import RefreshToken

class LogoutView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            token = RefreshToken(refresh_token)
            token.blacklist()
            
            return Response({'detail': 'Logout successful'}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)
```

---

**Last Updated:** October 13, 2025  
**Django Version:** 5.2.6  
**SimpleJWT Version:** Latest
