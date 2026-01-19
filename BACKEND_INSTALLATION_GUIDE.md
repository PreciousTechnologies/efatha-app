# 🚀 COMPLETE BACKEND INSTALLATION GUIDE - STEP BY STEP

## 📋 Prerequisites
- Django project already running
- User model with 'role' field exists
- JWT authentication configured

---

## 🔧 STEP 1: Copy Backend Files

### 1.1 Locate Your Django Project
Your Django project structure should look like:
```
your_django_project/
├── manage.py
├── your_project/
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
└── church_app/          ← Your church app
    ├── models.py
    ├── views.py
    ├── serializers.py
    ├── urls.py
    ├── admin.py
    └── permissions.py
```

### 1.2 Copy Files from BACKEND_IMPLEMENTATION Folder

Copy the content of these files to your Django `church_app/`:

**File 1: models.py**
```bash
# Copy content from: BACKEND_IMPLEMENTATION/models.py
# To: church_app/models.py
```
Add the `Sermon` model to your existing `church_app/models.py`

**File 2: serializers.py**
```bash
# Copy content from: BACKEND_IMPLEMENTATION/serializers.py
# To: church_app/serializers.py
```
Add the `SermonSerializer` class

**File 3: permissions.py**
```bash
# Copy content from: BACKEND_IMPLEMENTATION/permissions.py
# To: church_app/permissions.py (create if doesn't exist)
```

**File 4: views.py**
```bash
# Copy content from: BACKEND_IMPLEMENTATION/views.py
# To: church_app/views.py
```
Add the `SermonViewSet` class

**File 5: urls.py**
```bash
# Copy content from: BACKEND_IMPLEMENTATION/urls.py
# To: church_app/urls.py
```
Update your existing URLs

**File 6: admin.py**
```bash
# Copy content from: BACKEND_IMPLEMENTATION/admin.py
# To: church_app/admin.py
```
Add the `SermonAdmin` class

---

## ⚙️ STEP 2: Update Django Settings

### 2.1 Edit `your_project/settings.py`

Add these configurations:

```python
# ============================================
# MEDIA FILES CONFIGURATION
# ============================================

import os

# Media files (uploads)
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Maximum file upload size (100MB for videos)
DATA_UPLOAD_MAX_MEMORY_SIZE = 104857600  # 100MB
FILE_UPLOAD_MAX_MEMORY_SIZE = 104857600  # 100MB

# ============================================
# REST FRAMEWORK CONFIGURATION
# ============================================

REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# ============================================
# CORS CONFIGURATION (if needed)
# ============================================

# For development (allow all origins)
CORS_ALLOW_ALL_ORIGINS = True

# For production (specify allowed origins)
# CORS_ALLOWED_ORIGINS = [
#     'http://localhost:3000',
#     'http://10.107.200.233:8000',
# ]
```

### 2.2 Ensure Pillow is Installed

```bash
pip install Pillow
```

This is required for ImageField (thumbnail).

---

## 🌐 STEP 3: Update Main URLs

### 3.1 Edit `your_project/urls.py`

```python
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('church_app.urls')),  # Add this line
    # ... other paths ...
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

---

## 💾 STEP 4: Create Database Tables

### 4.1 Create Migrations

```bash
python manage.py makemigrations church_app
```

Expected output:
```
Migrations for 'church_app':
  church_app/migrations/0XXX_sermon.py
    - Create model Sermon
```

### 4.2 Run Migrations

```bash
python manage.py migrate
```

Expected output:
```
Running migrations:
  Applying church_app.0XXX_sermon... OK
```

### 4.3 Verify Tables Created

```bash
python manage.py dbshell
```

Then run:
```sql
.tables  -- (SQLite)
-- or
SHOW TABLES;  -- (MySQL/PostgreSQL)
```

You should see `church_app_sermon` table.

---

## 📁 STEP 5: Create Media Directories

### 5.1 Create Folders

```bash
# In your Django project root
mkdir -p media/sermons/audio
mkdir -p media/sermons/video
mkdir -p media/sermons/thumbnails
```

### 5.2 Set Permissions (Linux/Mac)

```bash
chmod -R 755 media/
```

### 5.3 Verify Structure

```
your_django_project/
├── media/
│   └── sermons/
│       ├── audio/
│       ├── video/
│       └── thumbnails/
```

---

## 👤 STEP 6: Create Editor User

### 6.1 Open Django Shell

```bash
python manage.py shell
```

### 6.2 Create Editor User

```python
from django.contrib.auth import get_user_model

User = get_user_model()

# Create editor user
editor = User.objects.create_user(
    username='editor1',
    email='editor@efatha.com',
    password='editor123',  # Change this to a secure password
    first_name='John',
    last_name='Editor',
    role='editor'  # IMPORTANT: Set role to 'editor'
)

print(f"✅ Created editor user: {editor.username}")
print(f"   Role: {editor.role}")
print(f"   ID: {editor.id}")
```

### 6.3 Verify Editor Created

```python
# Check editor exists
editor = User.objects.get(username='editor1')
print(f"Username: {editor.username}")
print(f"Role: {editor.role}")
print(f"Is Active: {editor.is_active}")
```

---

## 🧪 STEP 7: Test Backend with cURL

### 7.1 Get Authentication Token

```bash
curl -X POST http://10.107.200.233:8000/api/auth/login-password/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "editor1",
    "password": "editor123"
  }'
```

Expected response:
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "username": "editor1",
    "role": "editor"
  }
}
```

Copy the `access` token.

### 7.2 Test GET Sermons (Empty List)

```bash
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  http://10.107.200.233:8000/api/church/sermons/
```

Expected response:
```json
{
  "count": 0,
  "results": []
}
```

### 7.3 Test POST Create Sermon

```bash
curl -X POST http://10.107.200.233:8000/api/church/sermons/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "title=Test Sermon" \
  -F "pastor=Pastor John" \
  -F "category=Sunday Service" \
  -F "description=This is a test sermon" \
  -F "topics=Faith, Prayer, Hope" \
  -F "duration=30:00" \
  -F "audio_file=@/path/to/test.mp3"
```

Expected response (Status 201):
```json
{
  "id": 1,
  "title": "Test Sermon",
  "pastor": "Pastor John",
  "category": "Sunday Service",
  "description": "This is a test sermon",
  "topics": "Faith, Prayer, Hope",
  "duration": "30:00",
  "audio_url": "http://10.107.200.233:8000/media/sermons/audio/2025/10/test.mp3",
  "video_url": null,
  "thumbnail_url": null,
  "uploaded_by": 1,
  "uploaded_by_name": "John Editor",
  "views": 0,
  "created_at": "2025-10-19T...",
  "updated_at": "2025-10-19T...",
  "is_active": true
}
```

---

## ▶️ STEP 8: Start Django Server

### 8.1 Run Server

```bash
python manage.py runserver 0.0.0.0:8000
```

### 8.2 Verify Server Running

Open browser and go to:
```
http://10.107.200.233:8000/admin/
```

Login with superuser credentials.

### 8.3 Check Sermon in Admin

Go to:
```
http://10.107.200.233:8000/admin/church_app/sermon/
```

You should see your test sermon.

---

## 📱 STEP 9: Test Flutter App

### 9.1 Update API Config (if needed)

File: `lib/core/config/api_config.dart`

```dart
static const String baseUrl = 'http://10.107.200.233:8000';
```

### 9.2 Login as Editor in App

1. Open Flutter app
2. Login with:
   - Username: `editor1`
   - Password: `editor123`

### 9.3 Test Upload

1. Go to Sermons tab
2. Tap the **+** button (top-right)
3. Fill form:
   - Title: "My First Sermon"
   - Pastor: "Pastor John Smith"
   - Category: "Sunday Service"
   - Topics: "Faith, Prayer"
   - Duration: "45:30"
   - Description: "A powerful message..."
4. Select audio file
5. Select thumbnail (optional)
6. Tap **UPLOAD SERMON**
7. Wait for success message

### 9.4 Verify Sermon Appears

1. Go back to sermons list
2. Sermon should appear immediately
3. Check Django admin to verify it's in database

---

## ✅ STEP 10: Verification Checklist

Check all these:

- [ ] Django migrations created and applied
- [ ] Media folders created
- [ ] Editor user created with role='editor'
- [ ] Can login as editor via API
- [ ] Can GET sermons list (returns empty or populated list)
- [ ] Can POST new sermon via cURL (returns 201)
- [ ] Sermon appears in Django admin
- [ ] Media files are saved in media/ folder
- [ ] Django server running on 0.0.0.0:8000
- [ ] Flutter app shows + button for editor
- [ ] Can upload sermon via Flutter app
- [ ] Sermon appears in Flutter app list
- [ ] Filters work in Flutter app
- [ ] Search works in Flutter app
- [ ] Can edit sermon via Flutter app

---

## 🐛 Troubleshooting

### Issue 1: "Cannot find module 'Sermon'"
**Solution:** Make sure you copied `models.py` correctly and ran `makemigrations`.

### Issue 2: "Permission denied" when uploading
**Solution:** Check media folder permissions:
```bash
chmod -R 755 media/
```

### Issue 3: "Editor can't upload"
**Solution:** Verify user role is exactly 'editor' (lowercase):
```python
user = User.objects.get(username='editor1')
print(user.role)  # Should print: 'editor'
```

### Issue 4: "File not found" errors
**Solution:** Check MEDIA_ROOT and MEDIA_URL in settings.py:
```python
print(settings.MEDIA_ROOT)
print(settings.MEDIA_URL)
```

### Issue 5: Sermon not appearing in app
**Solution:** 
1. Check Django console for errors
2. Check Flutter console for API errors
3. Verify sermon is in database:
```python
from church_app.models import Sermon
Sermon.objects.all()
```

---

## 📊 STEP 11: Monitor Logs

### Django Console
Watch for these logs when uploading:
```
📤 Received create request from user: editor1
📤 Request data: {...}
📤 Files: {'audio_file': <UploadedFile...>}
✅ Sermon created successfully: 1
```

### Flutter Console
Watch for these logs:
```
📤 Uploading sermon...
📥 Upload response status: 201
📥 Upload response body: {...}
✅ Loaded 1 sermons
```

---

## 🎉 SUCCESS!

If all steps completed successfully:

✅ **Backend is ready** - Sermons are saved to database
✅ **Media files work** - Audio, video, thumbnails stored
✅ **Permissions work** - Only editors can upload
✅ **Flutter app works** - Uploads and displays sermons
✅ **Filters work** - Category, pastor, topics filters functional
✅ **Search works** - Full-text search operational

---

## 📞 Next Steps

1. **Test with real files:**
   - Upload actual sermon audio files
   - Upload sermon videos
   - Add sermon thumbnails

2. **Create more editors:**
   - Create additional editor accounts
   - Test permissions

3. **Monitor usage:**
   - Check view counts
   - Monitor database growth
   - Check media folder size

4. **Production deployment:**
   - Set up AWS S3 for media files
   - Configure CORS properly
   - Use HTTPS
   - Set DEBUG=False

---

**Status:** Ready to deploy and use! 🚀
