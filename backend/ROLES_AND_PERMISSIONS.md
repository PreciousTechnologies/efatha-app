# Efatha Church App - User Roles & Permissions

## User Roles

The Efatha Church App has 9 distinct user roles with different levels of access and permissions:

### 1. **Admin** 👑
- **Full system access**
- Can manage all users
- Can assign/change roles
- Can approve/reject all content
- Can edit all content
- Can access admin dashboard
- Can view all analytics and reports

**Capabilities:**
- ✅ Manage users
- ✅ Approve content (testimonies, prayers)
- ✅ Edit all content (sermons, events, announcements)
- ✅ Assign roles
- ✅ View financial reports
- ✅ Delete any content

---

### 2. **Chief Apostle** 🙏
- **Highest spiritual authority**
- Can manage users
- Can approve content
- Can edit content
- Leadership-level access

**Capabilities:**
- ✅ Manage users
- ✅ Approve content
- ✅ Edit sermons, events, announcements
- ✅ View member information
- ✅ Access leadership reports
- ❌ Cannot assign Admin role

---

### 3. **Katibu Kiongozi** (Lead Secretary) 📋
- **Administrative leadership**
- Can manage users
- Can edit content
- Can view reports

**Capabilities:**
- ✅ Manage users (except leadership roles)
- ✅ Edit content
- ✅ View member information
- ✅ Manage events and registrations
- ✅ View attendance reports
- ❌ Cannot approve testimonies/prayers

---

### 4. **Apostle** ⛪
- **Spiritual leadership**
- Can approve content
- Can edit content
- Leadership access

**Capabilities:**
- ✅ Approve content
- ✅ Edit sermons and announcements
- ✅ View prayer requests
- ✅ Create events
- ❌ Cannot manage users

---

### 5. **Senior Pastor** 🕊️
- **Senior ministry leadership**
- Can approve content
- Can edit content
- Leadership access

**Capabilities:**
- ✅ Approve testimonies and prayers
- ✅ Edit sermons and events
- ✅ Create announcements
- ✅ View member information
- ❌ Cannot manage user roles

---

### 6. **Bishop** ⛪
- **Ministry leadership**
- Can approve content
- Can edit content
- Leadership access

**Capabilities:**
- ✅ Approve testimonies
- ✅ Edit sermons
- ✅ Create events
- ✅ View prayer requests
- ❌ Cannot manage users

---

### 7. **Editor** ✏️
- **Content management**
- Can edit all content
- No user management

**Capabilities:**
- ✅ Edit sermons, events, announcements
- ✅ Upload media (audio, video, images)
- ✅ Manage Bible content
- ✅ Manage hymns
- ❌ Cannot approve content
- ❌ Cannot manage users

---

### 8. **Data Entry** 💾
- **Data input specialist**
- Can add/edit specific content
- Limited editing rights

**Capabilities:**
- ✅ Add sermons (pending approval)
- ✅ Add events
- ✅ Input member data
- ✅ Upload media
- ❌ Cannot delete content
- ❌ Cannot approve content

---

### 9. **Member** 👤
- **Standard church member**
- Can view content
- Can submit requests
- Limited access

**Capabilities:**
- ✅ View sermons, events, Bible
- ✅ Submit prayer requests
- ✅ Submit testimonies
- ✅ Register for events
- ✅ Record giving/donations
- ✅ Update own profile
- ❌ Cannot edit church content

---

## Permission Matrix

| Feature | Admin | Chief Apostle | Katibu Kiongozi | Apostle | Senior Pastor | Bishop | Editor | Data Entry | Member |
|---------|-------|---------------|-----------------|---------|---------------|--------|--------|------------|--------|
| **User Management** |
| View Users | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Edit Users | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Assign Roles | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Content Management** |
| Create Sermons | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Edit Sermons | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Delete Sermons | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Create Events | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Edit Events | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Create Announcements | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Approval Rights** |
| Approve Testimonies | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Approve Prayers | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Member Features** |
| Submit Prayer Request | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Submit Testimony | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Register for Events | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Record Giving | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Reports & Analytics** |
| Financial Reports | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Attendance Reports | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Member Analytics | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

---

## Role Assignment

### Who Can Assign Roles?

1. **Admin** - Can assign ANY role
2. **Chief Apostle** - Can assign all roles except Admin
3. **Katibu Kiongozi** - Can assign roles: Bishop, Editor, Data Entry, Member

### Default Role
- New users are assigned **Member** role by default
- Role can be upgraded by authorized users through admin panel or API

---

## API Permissions

### Public Endpoints (No authentication required)
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - Login
- `GET /api/church/sermons/` - View sermons
- `GET /api/church/events/` - View events
- `GET /api/church/announcements/` - View announcements

### Authenticated Endpoints (Login required)
- `GET /api/auth/users/me/` - Get own profile
- `PUT /api/auth/users/update_profile/` - Update own profile
- `POST /api/church/prayer-requests/` - Submit prayer request
- `POST /api/church/testimonies/` - Submit testimony
- `POST /api/church/event-registrations/` - Register for event

### Leadership Endpoints (Leadership roles only)
- `GET /api/auth/users/` - List all users
- `GET /api/church/giving/` - View giving records
- `POST /api/church/sermons/` - Create sermon
- `PATCH /api/church/testimonies/{id}/approve/` - Approve testimony

### Admin Endpoints (Admin only)
- `POST /api/auth/users/assign_role/` - Assign user role
- `DELETE /api/church/sermons/{id}/` - Delete sermon
- `GET /api/reports/analytics/` - View analytics

---

## Implementation in Flutter

### Checking User Role
```dart
// Store user role after login
SharedPreferences prefs = await SharedPreferences.getInstance();
String userRole = prefs.getString('user_role') ?? 'member';

// Check permissions
bool isLeadership = [
  'admin', 'chief_apostle', 'katibu_kiongozi',
  'apostle', 'senior_pastor', 'bishop'
].contains(userRole);

bool canEditContent = [
  'admin', 'editor', 'data_entry', 'chief_apostle',
  'katibu_kiongozi', 'apostle', 'senior_pastor', 'bishop'
].contains(userRole);

bool canApprove = [
  'admin', 'chief_apostle', 'apostle', 'senior_pastor', 'bishop'
].contains(userRole);
```

### Conditional UI Based on Role
```dart
// Show admin panel only to leadership
if (isLeadership) {
  return AdminDashboard();
}

// Show edit button only to editors
if (canEditContent) {
  return IconButton(
    icon: Icon(Icons.edit),
    onPressed: () => editSermon(),
  );
}

// Show approve button only to approvers
if (canApprove) {
  return ElevatedButton(
    onPressed: () => approveTestimony(),
    child: Text('Approve'),
  );
}
```

---

## Role Hierarchy

```
Level 1: Admin (Supreme Access)
    ↓
Level 2: Chief Apostle (Spiritual Authority + User Management)
    ↓
Level 3: Katibu Kiongozi (Administrative Authority)
    ↓
Level 4: Apostle, Senior Pastor (Spiritual Leadership)
    ↓
Level 5: Bishop (Ministry Leadership)
    ↓
Level 6: Editor (Content Management)
    ↓
Level 7: Data Entry (Data Input)
    ↓
Level 8: Member (Standard Access)
```

---

## Security Best Practices

1. **Never store role assignments on client-side only** - Always verify with backend
2. **Use JWT tokens** with role embedded in payload
3. **Validate permissions on EVERY API call** - Don't trust frontend checks alone
4. **Audit trail** - Log all role changes and critical actions
5. **Regular review** - Periodically review user roles and permissions

---

## Database Schema Addition

```python
# User model includes:
role = models.CharField(
    max_length=20,
    choices=ROLE_CHOICES,
    default='member'
)
```

---

**Version:** 1.0  
**Last Updated:** October 11, 2025  
**App:** Efatha Church Mobile Application
