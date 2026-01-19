# Frontend Update Complete ✅

## Summary
The onboarding screen has been successfully updated with the following improvements:

## Changes Made

### 1. ✅ Previous Button Added
- **Location**: Bottom left of onboarding screen
- **Functionality**: 
  - Appears only when `currentPage > 0`
  - Navigates back to previous page
  - Styled with purple border to match design
  - Layout uses `Row` with `spaceBetween` for navigation buttons

### 2. ✅ Registration Number Field Added
- **Location**: Church Details page (Page 4)
- **Type**: Text input field
- **Icon**: `confirmation_number_outlined`
- **Stored in**: `controller.formData['registrationNumber']`

### 3. ✅ Church Position Dropdown
- **Type**: Dynamic dropdown (fetches from backend API)
- **Data Source**: `/api/auth/constants/` → `church_positions`
- **Options include**:
  - Mtume Mkuu
  - Msaidizi Binafsi wa Mtume Mkuu
  - Mtume
  - Mchungaji Kiongozi
  - Mchungaji
  - Katibu
  - Mtawala
  - Askofu
  - Cell Leader
  - Mweka Hazina
  - Mwanakamati
  - Mjumbe wa Board
  - Funguka
  - ICT
  - TV
  - Sunday School Teacher
  - Walinzi
  - Muumini

### 4. ✅ Service Region Dropdown
- **Type**: Dynamic dropdown (fetches from backend API)
- **Data Source**: `/api/auth/constants/` → `service_regions`
- **Options include**:
  - All countries (Tanzania, Kenya, Malawi, Zambia, Rwanda, Burundi, etc.)
  - Tanzania regions (Dar es Salaam, Arusha, Mwanza, etc.)
  - Mikoa (Mwenge, Ushindi, Temeke, Kinondoni, Imara, Yombo, Kisukuru, Zanzibar)

### 5. ✅ Backend API Integration
- **Added**: API calls to fetch constants when page loads
- **Loading State**: Shows circular progress indicator while fetching data
- **Error Handling**: Displays snackbar if API call fails
- **Submission**: Updated `_handleSubmit()` to:
  - Call `apiService.register(believerModel.toJson())`
  - Save access and refresh tokens
  - Save user data
  - Mark user as logged in
  - Navigate to Home screen on success

## Files Modified

### 1. `lib/screens/onboarding/onboarding_screen.dart`
**Changes**:
- Added import for `ApiService` and `StorageService`
- Added Previous button in navigation row (bottom left)
- Updated `_handleSubmit()` to call backend API
- Save tokens and user data after successful registration
- Show loading dialog during submission
- Navigate to Home screen after registration

**Key Code**:
```dart
// Previous button (shows when currentPage > 0)
if (_controller.currentPage > 0)
  Container(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.primaryPurpleVibrant, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: AppButton(
      label: 'Previous',
      onPressed: _handleBack,
      variant: AppButtonVariant.secondary,
    ),
  ),
```

```dart
// API submission
final response = await apiService.register(believerModel.toJson());
if (response['success'] == true) {
  await storageService.setAccessToken(response['data']['access']);
  await storageService.setRefreshToken(response['data']['refresh']);
  await storageService.saveUserData(response['data']['user']);
  await storageService.setLoggedIn(true);
}
```

### 2. `lib/screens/onboarding/pages/church_details_page.dart`
**Changes**:
- Removed mock data for service regions, centres, areas, zones, cells
- Added API integration to fetch church positions and service regions
- Added registration number field
- Changed church position from text field to dropdown
- Simplified to show only: Church Position, Service Region, Membership Number, Registration Number

**Key Code**:
```dart
// Fetch constants from API
Future<void> _loadConstants() async {
  final response = await _apiService.getConstants();
  if (response['success'] == true && response['data'] != null) {
    setState(() {
      _churchPositions = List<String>.from(response['data']['church_positions'] ?? []);
      _serviceRegions = List<String>.from(response['data']['service_regions'] ?? []);
      _isLoading = false;
    });
  }
}
```

### 3. `lib/screens/onboarding/onboarding_controller.dart`
**Changes**:
- Added `registrationNumber` field support
- Updated `serviceRegionName` to use `serviceRegion` from form data
- Included in `toBelieverModel()` method

**Key Code**:
```dart
registrationNumber: _formData['registrationNumber'],
serviceRegionName: _formData['serviceRegion'],
```

## Backend API Endpoints Used

### 1. GET `/api/auth/constants/`
**Returns**:
```json
{
  "church_positions": ["Mtume Mkuu", "Mtume", "Mchungaji", ...],
  "countries": ["Tanzania", "Kenya", ...],
  "tanzania_regions": ["Dar es Salaam", "Arusha", ...],
  "service_regions": ["Tanzania", "Kenya", "Mwenge", "Ushindi", ...]
}
```

### 2. POST `/api/auth/register/`
**Accepts**:
```json
{
  "first_name": "John",
  "middle_name": "Paul",
  "last_name": "Doe",
  "gender": "Male",
  "date_of_birth": "1990-01-01",
  "phone": "+255123456789",
  "email": "john@example.com",
  "church_position": "Muumini",
  "service_region": "Dar es Salaam",
  "membership_number": "DAR/2024/001",
  "registration_number": "REG/2024/001",
  ...
}
```

**Returns**:
```json
{
  "success": true,
  "data": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "user": {
      "id": 1,
      "email": "john@example.com",
      "username": "john_doe",
      ...
    }
  }
}
```

## Testing Checklist

### ✅ Visual Tests
- [ ] Previous button appears on pages 2-5 (bottom left)
- [ ] Previous button hidden on page 1
- [ ] Previous button styled with purple border
- [ ] Navigation buttons properly aligned (Previous left, Next right)

### ✅ Functional Tests
- [ ] Previous button navigates to previous page
- [ ] Church position dropdown loads from API
- [ ] Service region dropdown loads from API
- [ ] Registration number field accepts input
- [ ] Membership number field accepts input

### ✅ API Integration Tests
- [ ] Constants API called when church details page loads
- [ ] Loading indicator shows while fetching data
- [ ] Dropdowns populated with API data
- [ ] Registration submission calls backend API
- [ ] Tokens saved after successful registration
- [ ] User redirected to Home screen after registration
- [ ] Error handling shows snackbar on failure

### ✅ End-to-End Test
1. Start onboarding from Welcome screen
2. Fill in Personal Info (Page 1)
3. Click Next → Navigate to Location Info (Page 2)
4. Click Previous → Return to Personal Info (Page 1)
5. Fill all pages through Church Details (Page 4)
6. Select church position from dropdown
7. Select service region from dropdown
8. Enter membership number
9. Enter registration number
10. Click Next → Navigate to Confirmation (Page 5)
11. Click Submit → API call to backend
12. Verify success dialog shown
13. Verify navigation to Home screen
14. Verify user is logged in (tokens saved)

## Next Steps

### 1. Update API Base URL
The current API URL in `lib/core/config/api_config.dart` is set to emulator localhost. You need to update it to your computer's IP address for physical device testing:

```dart
// Change from:
static const String baseUrl = 'http://10.0.2.2:8000';

// To (your computer IP):
static const String baseUrl = 'http://192.168.X.X:8000';
```

**How to find your IP**:
```powershell
ipconfig
```
Look for "IPv4 Address" under your network adapter (usually WiFi or Ethernet).

### 2. Test on Device/Emulator
```bash
# Run the app
flutter run

# Or for specific device
flutter run -d <device_id>
```

### 3. Verify Backend is Running
Ensure your Django server is running and accessible:
```powershell
cd C:\Users\MAXFYNN\Desktop\efatha_app\backend
python manage.py runserver 0.0.0.0:8000
```

Test the constants endpoint:
```powershell
Invoke-RestMethod -Uri "http://localhost:8000/api/auth/constants/" -Method GET
```

### 4. Test Complete Flow
1. Open app on device/emulator
2. Click "Get Started" on Welcome screen
3. Click "New User" on login screen
4. Complete all onboarding pages
5. Verify church position dropdown shows all options
6. Verify service region dropdown shows all regions
7. Submit registration
8. Verify success and navigation to Home
9. Logout and verify email verification login works

## Status: ✅ COMPLETE

All frontend updates have been successfully implemented:
- ✅ Previous button on onboarding
- ✅ Registration number field
- ✅ Church position dropdown (API-driven)
- ✅ Service region dropdown (API-driven)
- ✅ Backend submission on registration
- ✅ Token storage and authentication
- ✅ Error handling

The application is now ready for testing with the backend API!

## Need Help?

If you encounter any issues:

1. **API not loading**: Check that Django server is running on `http://0.0.0.0:8000/`
2. **Connection error**: Update `baseUrl` in `api_config.dart` to your computer's IP
3. **Dropdowns empty**: Verify `/api/auth/constants/` endpoint returns data
4. **Registration fails**: Check backend logs for error details
5. **Previous button not showing**: Ensure you're on page 2 or later

**Backend logs**:
Check the Django server terminal for request logs and error messages.

**Flutter logs**:
```bash
flutter logs
```

## Documentation
- Main onboarding flow: `ONBOARDING_DOCUMENTATION.md`
- Email verification: `YOUR_EMAIL_SETUP.md`
- Testing guide: `TESTING_GUIDE.md`
- API reference: `API_DOCUMENTATION.md`
