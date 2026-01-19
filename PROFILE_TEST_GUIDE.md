# 🎉 Profile Screen - Quick Test Guide

## Test the New Profile Screen

### Prerequisites:
1. ✅ Backend running: `python manage.py runserver 0.0.0.0:8000`
2. ✅ User registered in database (testuser@test.com)
3. ✅ Flutter app connected to backend (IP: 10.146.127.233)

### Test Steps:

#### 1. **Start the App**
```bash
flutter run
```

#### 2. **Navigate to Profile**
- Tap on "More" tab (bottom navigation)
- Profile section should load automatically

#### 3. **Verify Data Display**
You should see:
- ✅ **Profile Circle**: Initials "TU" (or your user's initials)
- ✅ **Name**: Test User (or your registered name)
- ✅ **Email**: testuser@test.com
- ✅ **Church Position Badge**: "Muumini"
- ✅ **Personal Info Card**: First name, last name, email, phone
- ✅ **Church Info Card**: Position, service region, registration number
- ✅ **Location Card**: Country (Tanzania), Region (Dar es Salaam), City (Kinondoni)

#### 4. **Test Refresh**
- **Pull down** on the profile screen
- Data should refresh from database
- Loading indicator appears briefly

#### 5. **Test Refresh Button**
- Tap the **refresh icon** in app bar (top right)
- Profile data reloads from API

#### 6. **Test Offline Mode**
- Stop Django backend server
- Pull to refresh on profile
- Should show: "Using cached data: Connection error..."
- Data still displays (from local cache)

#### 7. **Verify in Database**
```bash
cd backend
python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); user = User.objects.get(email='testuser@test.com'); print(f'✅ Database User: {user.first_name} {user.last_name}'); print(f'Email: {user.email}'); print(f'Position: {user.church_position}')"
```

Expected output:
```
✅ Database User: Test User
Email: testuser@test.com
Position: Muumini
```

### Expected Results:

#### Success Indicators:
- ✅ Profile loads within 1-2 seconds
- ✅ All database fields display correctly
- ✅ Initials match user's name
- ✅ Church position shows as badge
- ✅ All cards populated with real data
- ✅ No "-" dashes for fields with data
- ✅ Pull-to-refresh works smoothly

#### If You See:
- **"Loading..."** - Normal, wait 1-2 seconds
- **"-"** in fields - That data is not in database (null/empty)
- **"Connection error"** - Backend not running or wrong IP
- **Cached data message** - API failed, showing offline data

### Troubleshooting:

#### Problem: "Connection error"
**Solution**:
1. Check backend is running: `python manage.py runserver 0.0.0.0:8000`
2. Verify IP in `lib/core/config/api_config.dart` is correct
3. Ensure device/emulator on same network

#### Problem: All fields show "-"
**Solution**:
1. User not logged in properly
2. Check tokens saved: 
```dart
final token = await StorageService().getAccessToken();
print('Token: $token');
```
3. Re-register or login

#### Problem: Shows old cached data
**Solution**:
1. Pull to refresh
2. Tap refresh button
3. Restart app
4. Clear app data and re-login

### Test with Different User:

1. **Register new user** through onboarding
2. **Complete all fields** during registration
3. **Navigate to Profile** after registration
4. **Verify all data** appears correctly

### Screenshots Checklist:

When testing, verify these visual elements:
- [ ] Purple gradient profile circle with white initials
- [ ] Full name below circle
- [ ] Email in gray text
- [ ] Church position badge (purple gradient)
- [ ] 4+ colored section cards (purple, blue, green, orange)
- [ ] Each card has gradient header with icon
- [ ] Data displayed in label-value format
- [ ] Smooth scrolling
- [ ] Pull-to-refresh animation

## Success!

If all tests pass:
- ✅ Profile screen connected to database
- ✅ Real user data displaying
- ✅ Refresh functionality working
- ✅ Offline mode working
- ✅ UI looking professional

**Your profile screen is now production-ready!** 🚀
