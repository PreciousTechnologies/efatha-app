# 🎵 SERMONS MANAGEMENT - DJANGO BACKEND IMPLEMENTATION

## Overview
Complete Django backend implementation for sermons management system with upload, edit, delete, filtering, and search capabilities.

---

## 📁 Project Structure

```
church_app/
├── models.py          # Sermon model
├── serializers.py     # Sermon serializer
├── views.py          # Sermon views
├── urls.py           # URL routing
└── permissions.py    # Custom permissions
```

---

## 🗄️ 1. DATABASE MODEL

### File: `church_app/models.py`

```python
from django.db import models
from django.contrib.auth import get_User_Model

User = get_User_Model()

class Sermon(models.Model):
    """
    Sermon model for storing church sermons with audio/video files
    """
    # Basic Information
    title = models.CharField(max_length=255)
    pastor = models.CharField(max_length=200)
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
        default='Sunday Service'
    )
    description = models.TextField()
    topics = models.CharField(max_length=500, help_text="Comma-separated topics")
    duration = models.CharField(max_length=10, help_text="Format: MM:SS")
    
    # Media Files
    audio_file = models.FileField(
        upload_to='sermons/audio/%Y/%m/',
        null=True,
        blank=True,
        help_text="Audio file (MP3, WAV, etc.)"
    )
    video_file = models.FileField(
        upload_to='sermons/video/%Y/%m/',
        null=True,
        blank=True,
        help_text="Video file (MP4, MOV, etc.)"
    )
    thumbnail = models.ImageField(
        upload_to='sermons/thumbnails/%Y/%m/',
        null=True,
        blank=True,
        help_text="Sermon thumbnail image"
    )
    
    # Metadata
    uploaded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='uploaded_sermons'
    )
    views = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Sermon'
        verbose_name_plural = 'Sermons'
    
    def __str__(self):
        return f"{self.title} - {self.pastor}"
    
    def increment_views(self):
        """Increment view count"""
        self.views += 1
        self.save(update_fields=['views'])
```

### Run Migrations:
```bash
python manage.py makemigrations
python manage.py migrate
```

---

## 🔐 2. PERMISSIONS

### File: `church_app/permissions.py`

```python
from rest_framework import permissions

class IsEditorOrReadOnly(permissions.BasePermission):
    """
    Custom permission:
    - Any authenticated user can read sermons
    - Only editors can create/update/delete sermons
    """
    
    def has_permission(self, request, view):
        # Read permissions for all authenticated users
        if request.method in permissions.SAFE_METHODS:
            return request.user and request.user.is_authenticated
        
        # Write permissions only for editors
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == 'editor'
        )
    
    def has_object_permission(self, request, view, obj):
        # Read permissions for all authenticated users
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write permissions only for editors
        return request.user.role == 'editor'
```

---

## 📦 3. SERIALIZER

### File: `church_app/serializers.py`

```python
from rest_framework import serializers
from .models import Sermon

class SermonSerializer(serializers.ModelSerializer):
    """
    Serializer for Sermon model with file upload handling
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
        if obj.uploaded_by:
            return f"{obj.uploaded_by.first_name} {obj.uploaded_by.last_name}".strip()
        return "Unknown"
    
    def get_audio_url(self, obj):
        if obj.audio_file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.audio_file.url)
        return None
    
    def get_video_url(self, obj):
        if obj.video_file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.video_file.url)
        return None
    
    def get_thumbnail_url(self, obj):
        if obj.thumbnail:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.thumbnail.url)
        return None
    
    def create(self, validated_data):
        # Set uploaded_by to current user
        validated_data['uploaded_by'] = self.context['request'].user
        return super().create(validated_data)
```

---

## 🎯 4. VIEWS

### File: `church_app/views.py`

```python
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from .models import Sermon
from .serializers import SermonSerializer
from .permissions import IsEditorOrReadOnly

class SermonViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing sermons
    
    Endpoints:
    - GET    /api/church/sermons/          List all sermons (with filters)
    - POST   /api/church/sermons/          Create new sermon (editors only)
    - GET    /api/church/sermons/{id}/     Retrieve sermon details
    - PATCH  /api/church/sermons/{id}/     Update sermon (editors only)
    - DELETE /api/church/sermons/{id}/     Delete sermon (editors only)
    """
    queryset = Sermon.objects.filter(is_active=True)
    serializer_class = SermonSerializer
    permission_classes = [IsAuthenticated, IsEditorOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'pastor', 'topics', 'description']
    ordering_fields = ['created_at', 'views', 'title']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """
        Filter sermons by:
        - category
        - pastor
        - topics
        - search (title, pastor, topics, description)
        """
        queryset = super().get_queryset()
        
        # Category filter
        category = self.request.query_params.get('category', None)
        if category and category != 'all':
            queryset = queryset.filter(category=category)
        
        # Pastor filter
        pastor = self.request.query_params.get('pastor', None)
        if pastor:
            queryset = queryset.filter(pastor__icontains=pastor)
        
        # Topics filter
        topics = self.request.query_params.get('topics', None)
        if topics:
            queryset = queryset.filter(topics__icontains=topics)
        
        # General search
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(pastor__icontains=search) |
                Q(topics__icontains=search) |
                Q(description__icontains=search)
            )
        
        return queryset
    
    def retrieve(self, request, *args, **kwargs):
        """Increment view count when sermon is retrieved"""
        instance = self.get_object()
        instance.increment_views()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    def perform_create(self, serializer):
        """Set uploaded_by to current user"""
        serializer.save(uploaded_by=self.request.user)
    
    @action(detail=True, methods=['post'])
    def increment_views(self, request, pk=None):
        """Manually increment views"""
        sermon = self.get_object()
        sermon.increment_views()
        return Response({'views': sermon.views})
```

---

## 🌐 5. URL ROUTING

### File: `church_app/urls.py`

```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SermonViewSet

router = DefaultRouter()
router.register(r'sermons', SermonViewSet, basename='sermon')

urlpatterns = [
    path('church/', include(router.urls)),
]
```

### Main URL Configuration: `your_project/urls.py`

```python
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # ... other patterns ...
    path('api/', include('church_app.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

---

## ⚙️ 6. SETTINGS CONFIGURATION

### File: `settings.py`

```python
# Media files configuration
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Maximum file upload size (100MB for videos)
DATA_UPLOAD_MAX_MEMORY_SIZE = 104857600  # 100MB
FILE_UPLOAD_MAX_MEMORY_SIZE = 104857600  # 100MB

# Allowed file extensions
ALLOWED_AUDIO_EXTENSIONS = ['.mp3', '.wav', '.m4a', '.ogg']
ALLOWED_VIDEO_EXTENSIONS = ['.mp4', '.mov', '.avi', '.mkv']
ALLOWED_IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp']

# CORS settings (if frontend is on different domain)
CORS_ALLOW_ALL_ORIGINS = True  # For development only
# CORS_ALLOWED_ORIGINS = ['http://localhost:3000']  # For production

# REST Framework settings
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
```

---

## 📋 7. API ENDPOINTS DOCUMENTATION

### **GET /api/church/sermons/** - List Sermons

**Query Parameters:**
- `category` (optional): Filter by category
- `pastor` (optional): Filter by pastor name
- `topics` (optional): Filter by topics
- `search` (optional): Search in title, pastor, topics, description
- `page` (optional): Page number for pagination
- `page_size` (optional): Items per page

**Example Requests:**
```bash
# Get all sermons
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8000/api/church/sermons/

# Filter by category
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8000/api/church/sermons/?category=Sunday%20Service"

# Search by pastor
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8000/api/church/sermons/?pastor=John%20Smith"

# Search by topics
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8000/api/church/sermons/?topics=Faith"

# General search
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8000/api/church/sermons/?search=prayer"

# Combine filters
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8000/api/church/sermons/?category=Sunday%20Service&pastor=John&search=faith"
```

**Response:**
```json
{
  "count": 45,
  "next": "http://localhost:8000/api/church/sermons/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "title": "The Power of Faith",
      "pastor": "Pastor John Smith",
      "category": "Sunday Service",
      "description": "A powerful message about faith...",
      "topics": "Faith, Prayer, Healing",
      "duration": "45:30",
      "audio_url": "http://localhost:8000/media/sermons/audio/2025/10/sermon1.mp3",
      "video_url": "http://localhost:8000/media/sermons/video/2025/10/sermon1.mp4",
      "thumbnail_url": "http://localhost:8000/media/sermons/thumbnails/2025/10/thumb1.jpg",
      "uploaded_by": 5,
      "uploaded_by_name": "Editor Name",
      "views": 1234,
      "created_at": "2025-10-15T10:30:00Z",
      "updated_at": "2025-10-15T10:30:00Z",
      "is_active": true
    }
  ]
}
```

---

### **POST /api/church/sermons/** - Upload Sermon (Editors Only)

**Content-Type:** `multipart/form-data`

**Fields:**
- `title` (required): Sermon title
- `pastor` (required): Pastor name
- `category` (required): Category
- `description` (required): Description
- `topics` (required): Comma-separated topics
- `duration` (required): Duration (MM:SS format)
- `audio_file` (optional): Audio file
- `video_file` (optional): Video file
- `thumbnail` (optional): Thumbnail image

**Example Request:**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "title=The Power of Faith" \
  -F "pastor=Pastor John Smith" \
  -F "category=Sunday Service" \
  -F "description=A powerful message about faith and prayer" \
  -F "topics=Faith, Prayer, Healing" \
  -F "duration=45:30" \
  -F "audio_file=@/path/to/audio.mp3" \
  -F "video_file=@/path/to/video.mp4" \
  -F "thumbnail=@/path/to/thumbnail.jpg" \
  http://localhost:8000/api/church/sermons/
```

**Response:** (Status 201 Created)
```json
{
  "id": 1,
  "title": "The Power of Faith",
  "pastor": "Pastor John Smith",
  "category": "Sunday Service",
  "description": "A powerful message about faith and prayer",
  "topics": "Faith, Prayer, Healing",
  "duration": "45:30",
  "audio_url": "http://localhost:8000/media/sermons/audio/2025/10/audio.mp3",
  "video_url": "http://localhost:8000/media/sermons/video/2025/10/video.mp4",
  "thumbnail_url": "http://localhost:8000/media/sermons/thumbnails/2025/10/thumbnail.jpg",
  "uploaded_by": 5,
  "uploaded_by_name": "Editor Name",
  "views": 0,
  "created_at": "2025-10-19T12:00:00Z",
  "updated_at": "2025-10-19T12:00:00Z",
  "is_active": true
}
```

---

### **PATCH /api/church/sermons/{id}/** - Update Sermon (Editors Only)

**Content-Type:** `multipart/form-data`

**Example Request:**
```bash
curl -X PATCH \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "title=Updated Title" \
  -F "description=Updated description" \
  -F "topics=Faith, Hope, Love" \
  http://localhost:8000/api/church/sermons/1/
```

**Response:** (Status 200 OK)
```json
{
  "id": 1,
  "title": "Updated Title",
  "pastor": "Pastor John Smith",
  "category": "Sunday Service",
  "description": "Updated description",
  "topics": "Faith, Hope, Love",
  "duration": "45:30",
  "audio_url": "http://localhost:8000/media/sermons/audio/2025/10/audio.mp3",
  "video_url": "http://localhost:8000/media/sermons/video/2025/10/video.mp4",
  "thumbnail_url": "http://localhost:8000/media/sermons/thumbnails/2025/10/thumbnail.jpg",
  "uploaded_by": 5,
  "uploaded_by_name": "Editor Name",
  "views": 1234,
  "created_at": "2025-10-19T12:00:00Z",
  "updated_at": "2025-10-19T13:30:00Z",
  "is_active": true
}
```

---

### **DELETE /api/church/sermons/{id}/** - Delete Sermon (Editors Only)

**Example Request:**
```bash
curl -X DELETE \
  -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8000/api/church/sermons/1/
```

**Response:** (Status 204 No Content)

---

## 🧪 8. TESTING

### Create Test Editor User
```python
# In Django shell: python manage.py shell
from django.contrib.auth import get_user_model
User = get_user_model()

editor = User.objects.create_user(
    username='editor1',
    email='editor@church.com',
    password='testpass123',
    role='editor',
    first_name='John',
    last_name='Editor'
)
print(f"Created editor: {editor.username}")
```

### Test Upload
```bash
# 1. Login to get token
curl -X POST http://localhost:8000/api/auth/login-password/ \
  -H "Content-Type: application/json" \
  -d '{"username": "editor1", "password": "testpass123"}'

# 2. Upload sermon with token
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "title=Test Sermon" \
  -F "pastor=Pastor Test" \
  -F "category=Sunday Service" \
  -F "description=Test description" \
  -F "topics=Test, Faith" \
  -F "duration=30:00" \
  -F "audio_file=@test_audio.mp3" \
  http://localhost:8000/api/church/sermons/
```

---

## ✅ 9. DEPLOYMENT CHECKLIST

- [ ] Run migrations: `python manage.py makemigrations && python manage.py migrate`
- [ ] Create media directories: `mkdir -p media/sermons/{audio,video,thumbnails}`
- [ ] Set proper file permissions for media folder
- [ ] Configure MEDIA_ROOT and MEDIA_URL in settings
- [ ] Set up file upload size limits
- [ ] Create editor user accounts
- [ ] Test file uploads
- [ ] Test filtering and search
- [ ] Configure CORS for frontend
- [ ] Set up file storage (AWS S3 for production)
- [ ] Add file validation (size, type)
- [ ] Test permissions (editors vs regular users)

---

## 🔒 10. SECURITY NOTES

1. **File Validation:** Add validators for file types and sizes
2. **Storage:** Use AWS S3 or similar for production
3. **Permissions:** Only editors can upload/edit/delete
4. **Authentication:** JWT tokens required for all operations
5. **Rate Limiting:** Add rate limiting for uploads
6. **File Scanning:** Consider adding virus scanning for uploaded files

---

## 📊 11. ADMIN PANEL

### File: `church_app/admin.py`

```python
from django.contrib import admin
from .models import Sermon

@admin.register(Sermon)
class SermonAdmin(admin.ModelAdmin):
    list_display = ['title', 'pastor', 'category', 'views', 'created_at', 'is_active']
    list_filter = ['category', 'is_active', 'created_at']
    search_fields = ['title', 'pastor', 'topics', 'description']
    readonly_fields = ['views', 'created_at', 'updated_at']
    fieldsets = (
        ('Basic Information', {
            'fields': ('title', 'pastor', 'category', 'description', 'topics', 'duration')
        }),
        ('Media Files', {
            'fields': ('audio_file', 'video_file', 'thumbnail')
        }),
        ('Metadata', {
            'fields': ('uploaded_by', 'views', 'is_active', 'created_at', 'updated_at')
        }),
    )
```

---

## 🎉 IMPLEMENTATION COMPLETE!

Your sermons management system is now ready with:
✅ Full CRUD operations
✅ File upload support (audio, video, thumbnail)
✅ Advanced filtering (category, pastor, topics)
✅ Full-text search
✅ Editor-only permissions
✅ View tracking
✅ Pagination support
✅ Admin panel integration

**Next Steps:**
1. Deploy the backend
2. Test all endpoints
3. Connect Flutter app
4. Upload test sermons
5. Test editor permissions
