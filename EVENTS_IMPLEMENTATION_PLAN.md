# 🎉 EVENTS MANAGEMENT SYSTEM - IMPLEMENTATION PLAN

## ✅ COMPLETED

### 1. Event Upload/Create Screen
**File:** `lib/screens/events/upload_event_screen.dart`

**Features Implemented:**
- ✅ Title field with validation
- ✅ Description textarea
- ✅ Location/Venue field
- ✅ Category dropdown (Worship, Conference, Seminar, Fellowship, Outreach, Youth, Other)
- ✅ Start Date & Time pickers
- ✅ End Date & Time pickers
- ✅ Cover Photo upload with preview
- ✅ RSVP toggle switch
- ✅ Max Attendees field (when RSVP enabled)
- ✅ Registration Deadline picker (when RSVP enabled)
- ✅ Create & Update functionality
- ✅ Image upload to backend
- ✅ Form validation
- ✅ Loading states
- ✅ Success/Error notifications

## 🚧 NEXT STEPS (In Order)

### Step 2: Add + Button to Events Screen (5 minutes)
**File to Modify:** `lib/screens/events/events_screen.dart`

**Changes Needed:**
1. Import UploadEventScreen
2. Add + FloatingActionButton (only show for admin/editor)
3. Navigate to UploadEventScreen on tap
4. Refresh events list after creation

**Code to Add:**
```dart
// In actions array of SliverAppBar:
if (userRole == 'admin' || userRole == 'editor')
  IconButton(
    icon: const Icon(Icons.add),
    onPressed: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UploadEventScreen(),
        ),
      );
      if (result == true) {
        _fetchEvents(); // Refresh list
      }
    },
  ),
```

### Step 3: Enhanced Event Cards with Cover Photos (15 minutes)
**File to Create:** Update `_EventCard` widget in `events_screen.dart`

**Features to Add:**
- Large cover photo at top (16:9 aspect ratio)
- Event title overlay on cover
- Date/time badge
- Location with icon
- Attendee count (X/Y registered)
- RSVP button
- Edit/Delete buttons (admin/editor only)
- Category tag
- Gradient overlay on cover for text readability

### Step 4: Event Detail Screen (20 minutes)
**File to Create:** `lib/screens/events/event_detail_screen.dart`

**Features:**
- Full-screen cover photo
- Event title, date, time
- Location with map icon
- Full description
- Category badge
- RSVP button (changes to "Registered" if user registered)
- Attendee count and list (admin only)
- Edit/Delete options (admin/editor only)
- Share event button

### Step 5: Connect to Backend API (10 minutes)
**File to Modify:** `events_screen.dart`

**API Calls:**
```dart
// Fetch events
GET ${ApiConfig.events}?filter=upcoming

// Create event
POST ${ApiConfig.events} (already in upload_event_screen.dart)

// Update event
PUT ${ApiConfig.events}{id}/ (already in upload_event_screen.dart)

// Delete event
DELETE ${ApiConfig.events}{id}/

// RSVP
POST ${ApiConfig.events}{id}/register/

// Un-RSVP
POST ${ApiConfig.events}{id}/unregister/

// Get attendees
GET ${ApiConfig.events}{id}/attendees/
```

### Step 6: RSVP Functionality (15 minutes)

**Backend Endpoints (Already Exist):**
- `POST /api/church/events/{id}/register/` - Register for event
- `DELETE /api/church/event-registrations/{id}/` - Unregister
- `GET /api/church/events/{id}/` - Get event with registration status

**Frontend Implementation:**
```dart
Future<void> _rsvpToEvent(int eventId) async {
  final url = Uri.parse('${ApiConfig.events}$eventId/register/');
  final response = await http.post(url);
  
  if (response.statusCode == 201) {
    setState(() {
      // Update UI to show "Registered"
    });
  }
}
```

## 📋 BACKEND STATUS

### Event Model (Already Complete)
```python
class Event(models.Model):
    title = models.CharField(max_length=200)  ✅
    description = models.TextField()  ✅
    location = models.CharField(max_length=200)  ✅
    start_date = models.DateTimeField()  ✅
    end_date = models.DateTimeField()  ✅
    banner_image = models.ImageField(upload_to='events/')  ✅
    requires_registration = models.BooleanField(default=False)  ✅
    max_attendees = models.IntegerField(blank=True, null=True)  ✅
    registration_deadline = models.DateTimeField(blank=True, null=True)  ✅
    category = models.CharField(max_length=50)  ✅
    organizer = models.ForeignKey(User)  ✅
    is_published = models.BooleanField(default=True)  ✅
```

### EventRegistration Model (Already Complete)
```python
class EventRegistration(models.Model):
    event = models.ForeignKey(Event)  ✅
    user = models.ForeignKey(User)  ✅
    registered_at = models.DateTimeField(auto_now_add=True)  ✅
    attended = models.BooleanField(default=False)  ✅
```

### API Endpoints (Already Exist)
```python
# From church/views.py
class EventViewSet(viewsets.ModelViewSet):
    - GET /api/church/events/  ✅
    - POST /api/church/events/  ✅
    - GET /api/church/events/{id}/  ✅
    - PUT /api/church/events/{id}/  ✅
    - DELETE /api/church/events/{id}/  ✅

class EventRegistrationViewSet(viewsets.ModelViewSet):
    - GET /api/church/event-registrations/  ✅
    - POST /api/church/event-registrations/  ✅
    - DELETE /api/church/event-registrations/{id}/  ✅
```

## 🎨 UI/UX ENHANCEMENTS

### Event Card Design
```
┌─────────────────────────────┐
│                             │
│    [Cover Photo 16:9]       │
│    with gradient overlay    │
│                             │
│  📅 Mar 15, 2024  2:00 PM   │  ← Date badge
│  Event Title Here           │  ← Title overlay
│                             │
├─────────────────────────────┤
│ 📍 Main Church Hall         │  ← Location
│ 👥 25/50 Registered         │  ← Attendee count
│                             │
│ ┌─────┐ ┌─────┐            │
│ │RSVP │ │Edit │ │Delete│   │  ← Action buttons
│ └─────┘ └─────┘            │
└─────────────────────────────┘
```

### Detail Screen Design
```
┌─────────────────────────────┐
│                             │
│    [Full Cover Photo]       │
│    with back button         │
│                             │
├─────────────────────────────┤
│  Event Title                │
│  ⭐ Conference               │  ← Category tag
│                             │
│  📅 March 15, 2024          │
│  🕐 2:00 PM - 5:00 PM       │
│  📍 Main Church Hall        │
│  👥 25/50 Registered        │
│                             │
│  Description:               │
│  Lorem ipsum dolor sit...   │
│                             │
│  ┌───────────────────┐      │
│  │   RSVP NOW        │      │  ← RSVP button
│  └───────────────────┘      │
│                             │
│  Attendees (Admin Only):    │
│  • John Doe                 │
│  • Jane Smith               │
│  • ...                      │
└─────────────────────────────┘
```

## 🔐 ROLE-BASED ACCESS CONTROL

### Permissions by Role:

**Regular User:**
- ✅ View all published events
- ✅ RSVP to events
- ✅ Un-RSVP from events
- ✅ View own registrations
- ❌ Create events
- ❌ Edit events
- ❌ Delete events
- ❌ View attendee list

**Editor:**
- ✅ All regular user permissions
- ✅ Create new events
- ✅ Edit own events
- ✅ Delete own events
- ✅ View attendee list for own events
- ❌ Edit others' events
- ❌ Delete others' events

**Admin:**
- ✅ All editor permissions
- ✅ Edit ANY event
- ✅ Delete ANY event
- ✅ View ALL attendee lists
- ✅ Mark attendance
- ✅ Export attendee data

## 📱 IMPLEMENTATION CODE SNIPPETS

### 1. Check User Role
```dart
// Get from SharedPreferences or user session
Future<String> getUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_role') ?? 'user';
}
```

### 2. Fetch Events with Filters
```dart
Future<List<Map<String, dynamic>>> fetchEvents(String filter) async {
  String endpoint = ApiConfig.events;
  
  if (filter == 'upcoming') {
    endpoint += '?start_date__gte=${DateTime.now().toIso8601String()}';
  } else if (filter == 'this_week') {
    final weekEnd = DateTime.now().add(Duration(days: 7));
    endpoint += '?start_date__lte=${weekEnd.toIso8601String()}';
  }
  
  final response = await http.get(Uri.parse(endpoint));
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }
  
  return [];
}
```

### 3. Delete Event
```dart
Future<void> deleteEvent(int eventId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Event?'),
      content: Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    final url = Uri.parse('${ApiConfig.events}$eventId/');
    final response = await http.delete(url);
    
    if (response.statusCode == 204) {
      _fetchEvents(); // Refresh list
      _showSuccess('Event deleted successfully');
    }
  }
}
```

### 4. RSVP Button Widget
```dart
Widget _buildRsvpButton(Map<String, dynamic> event) {
  final isRegistered = event['is_registered'] ?? false;
  final isFull = event['is_full'] ?? false;
  
  if (isFull && !isRegistered) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('Event Full', style: TextStyle(color: Colors.white)),
    );
  }
  
  return ElevatedButton(
    onPressed: () => isRegistered ? _unregister(event['id']) : _rsvp(event['id']),
    style: ElevatedButton.styleFrom(
      backgroundColor: isRegistered ? Colors.green : AppColors.primaryPurpleDeep,
    ),
    child: Text(isRegistered ? 'Registered ✓' : 'RSVP Now'),
  );
}
```

## 🧪 TESTING CHECKLIST

### Event Creation
- [ ] Create event with all fields
- [ ] Upload cover photo
- [ ] Enable RSVP with max attendees
- [ ] Set registration deadline
- [ ] Verify data saved to database
- [ ] Verify cover photo uploaded to server

### Event Display
- [ ] Events show in list with cover photos
- [ ] Filters work (all, upcoming, this week, this month)
- [ ] Event cards show correct info
- [ ] Tap event opens detail screen

### RSVP Functionality
- [ ] User can RSVP to event
- [ ] RSVP button changes to "Registered"
- [ ] User can un-RSVP
- [ ] Attendee count updates
- [ ] Can't RSVP if event full
- [ ] Can't RSVP after deadline

### CRUD Operations
- [ ] Admin can edit any event
- [ ] Admin can delete any event
- [ ] Editor can edit own events
- [ ] Editor can delete own events
- [ ] Regular user cannot edit/delete
- [ ] + button only shows for admin/editor

### Data Persistence
- [ ] All data saves to database
- [ ] Cover photos persist
- [ ] RSVP status persists
- [ ] Attendee list persists
- [ ] Event updates reflect immediately

## 📦 FILES TO CREATE/MODIFY

### New Files:
1. ✅ `lib/screens/events/upload_event_screen.dart` - CREATED
2. ⏳ `lib/screens/events/event_detail_screen.dart` - TO CREATE
3. ⏳ `lib/widgets/event_card.dart` - OPTIONAL (can stay in events_screen.dart)

### Files to Modify:
1. ⏳ `lib/screens/events/events_screen.dart` - Add + button, connect to API
2. ⏳ `backend/church/views.py` - May need custom actions for RSVP
3. ⏳ `backend/church/serializers.py` - Add is_registered, is_full fields

## ⏭️ NEXT IMMEDIATE STEPS

1. **Now**: Add + button to events_screen.dart
2. **Next**: Create enhanced event cards with cover photos
3. **Then**: Create event_detail_screen.dart
4. **Then**: Connect to backend API
5. **Finally**: Test everything

Would you like me to continue with the implementation? Just say "continue" and I'll implement steps 2-6!
