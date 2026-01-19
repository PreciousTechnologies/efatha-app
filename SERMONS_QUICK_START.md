# 🎵 SERMONS MANAGEMENT - QUICK START GUIDE

## 📱 For App Users

### Viewing Sermons:
1. Open app → Tap "Sermons" tab
2. Browse sermons in **List** or **Grid** view
3. Use filters to find specific sermons
4. Search by typing keywords
5. Tap sermon to play/watch

### Filtering Sermons:
- **Category:** Sunday Service, Youth, Midweek, etc.
- **Pastor:** Filter by specific pastor
- **Topics:** Filter by topics (Faith, Prayer, etc.)
- **Clear Filter:** Tap X icon to remove filter

### Searching:
- Type in search bar
- Search works for:
  - Sermon titles
  - Pastor names
  - Topics
  - Descriptions
- Results appear automatically after 500ms

---

## 👨‍💼 For Editors

### Uploading a Sermon:

1. **Open Upload Screen:**
   - Tap the **+** button (top-right corner)

2. **Add Thumbnail:**
   - Tap the thumbnail area
   - Select image from gallery
   - Preview shows immediately

3. **Fill Basic Information:**
   - **Title:** "The Power of Faith"
   - **Pastor:** "Pastor John Smith"
   - **Category:** Select from dropdown
   - **Topics:** "Faith, Prayer, Healing" (comma-separated)
   - **Duration:** "45:30" (MM:SS format)
   - **Description:** Brief sermon description

4. **Upload Media Files:**
   - **Audio File:** Tap to select MP3/WAV file
   - **Video File:** (Optional) Tap to select MP4/MOV file

5. **Submit:**
   - Tap **UPLOAD SERMON** button
   - Wait for success message
   - Sermon appears in list automatically

### Editing a Sermon:

1. **Open Edit Screen:**
   - Tap **edit icon** (✏️) on sermon card

2. **Make Changes:**
   - Update any field
   - Change files if needed
   - Modify description

3. **Save Changes:**
   - Tap **SAVE CHANGES** button
   - Wait for success message
   - Changes appear immediately

---

## 🔧 For Developers

### Setting Up Backend:

```bash
# 1. Create Django model
# See DJANGO_SERMONS_BACKEND.md

# 2. Run migrations
python manage.py makemigrations
python manage.py migrate

# 3. Create editor user
python manage.py shell
>>> from django.contrib.auth import get_user_model
>>> User = get_user_model()
>>> editor = User.objects.create_user(
...     username='editor1',
...     email='editor@church.com',
...     password='testpass123',
...     role='editor',
...     first_name='John',
...     last_name='Editor'
... )

# 4. Test upload
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "title=Test Sermon" \
  -F "pastor=Pastor Test" \
  -F "category=Sunday Service" \
  -F "description=Test description" \
  -F "topics=Test, Faith" \
  -F "duration=30:00" \
  -F "audio_file=@test.mp3" \
  http://localhost:8000/api/church/sermons/
```

### Testing Endpoints:

```bash
# List all sermons
GET /api/church/sermons/

# Filter by category
GET /api/church/sermons/?category=Sunday%20Service

# Filter by pastor
GET /api/church/sermons/?pastor=John

# Search
GET /api/church/sermons/?search=faith

# Combine filters
GET /api/church/sermons/?category=Sunday%20Service&pastor=John&search=faith

# Get specific sermon
GET /api/church/sermons/{id}/

# Update sermon (editors only)
PATCH /api/church/sermons/{id}/

# Delete sermon (editors only)
DELETE /api/church/sermons/{id}/
```

### Flutter Code Structure:

```
lib/
├── screens/
│   └── sermons/
│       ├── sermons_screen.dart          # Main screen
│       └── upload_sermon_screen.dart    # Upload/Edit form
├── core/
│   └── services/
│       └── api_service.dart             # API methods
```

### Key Components:

**Sermons Screen:**
- User role check: `_checkUserRole()`
- Load sermons: `_loadSermons()`
- Search debouncing: `_onSearchChanged()`
- Navigation: `_navigateToUpload()`

**Upload Screen:**
- File pickers: `_pickAudioFile()`, `_pickVideoFile()`, `_pickThumbnail()`
- Form validation: `_formKey.currentState!.validate()`
- Submit: `_submitForm()`

**API Methods:**
- `getSermons()` - with filters
- `uploadSermon()` - multipart upload
- `updateSermon()` - multipart update
- `deleteSermon()` - delete

---

## 🐛 Troubleshooting

### Upload Button Not Showing:
- **Check:** User role is 'editor'
- **Fix:** Verify `getUserRole()` returns 'editor'

### Edit Button Not Showing:
- **Check:** User is logged in as editor
- **Fix:** Ensure `_isEditor` is true

### Files Not Uploading:
- **Check:** File size limits
- **Check:** File format support
- **Fix:** Increase `DATA_UPLOAD_MAX_MEMORY_SIZE` in Django

### Search Not Working:
- **Check:** Backend search implementation
- **Check:** API endpoint returns filtered results
- **Fix:** Verify Django filter logic

### Filters Not Working:
- **Check:** Query parameters sent to API
- **Check:** Backend filtering implementation
- **Fix:** Verify `get_queryset()` in Django

### Grid View Overflow:
- **Status:** ✅ Fixed
- **Solution:** Reduced childAspectRatio to 0.70

---

## 📋 Checklist Before Testing

### Backend:
- [ ] Django model created
- [ ] Migrations run
- [ ] Media folder created
- [ ] Permissions configured
- [ ] Editor user created
- [ ] Endpoints tested with curl
- [ ] Server running

### Frontend:
- [ ] Dependencies installed (`flutter pub get`)
- [ ] App compiled successfully
- [ ] Editor user credentials available
- [ ] Server IP configured in `api_config.dart`
- [ ] Device/emulator connected

### Testing:
- [ ] Login as editor works
- [ ] Upload button appears
- [ ] Upload form opens
- [ ] Files can be selected
- [ ] Upload succeeds
- [ ] Sermon appears in list
- [ ] Filters work
- [ ] Search works
- [ ] Edit button appears
- [ ] Edit form works
- [ ] Changes save correctly

---

## 🎯 Common Tasks

### Add New Category:
1. Update `_categories` list in `upload_sermon_screen.dart`
2. Update category choices in Django model
3. Run migrations
4. Update `_categories` list in `sermons_screen.dart`

### Change File Size Limits:
1. Update `DATA_UPLOAD_MAX_MEMORY_SIZE` in `settings.py`
2. Update web server config (nginx, apache)
3. Restart server

### Add New Filter:
1. Add filter UI in `sermons_screen.dart`
2. Add query param in `getSermons()` method
3. Add filter logic in Django `get_queryset()`

### Change Upload Permissions:
1. Modify `IsEditorOrReadOnly` permission class
2. Update role check in Flutter screens

---

## 📞 Support

**Documentation:**
- Full implementation: `SERMONS_IMPLEMENTATION_SUMMARY.md`
- Django backend: `DJANGO_SERMONS_BACKEND.md`

**Files Modified:**
- `lib/screens/sermons/sermons_screen.dart`
- `lib/screens/sermons/upload_sermon_screen.dart`
- `lib/core/services/api_service.dart`
- `pubspec.yaml`

**Status:** ✅ All features implemented and ready for testing!
