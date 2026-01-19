# Flutter Integration with Django Backend

## 1. Add Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
```

Run:
```powershell
flutter pub get
```

## 2. Backend Configuration

Update your backend URL in `lib/core/config/api_config.dart`:
```dart
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.100:8000';  // Your computer's local IP
  static const String apiUrl = '$baseUrl/api';
}
```

## 3. Test Backend Connection

1. Find your computer's local IP:
```powershell
ipconfig
# Look for IPv4 Address under your network adapter
```

2. Update Django ALLOWED_HOSTS in `backend/.env`:
```
ALLOWED_HOSTS=localhost,127.0.0.1,192.168.1.100
```

3. Restart Django server:
```powershell
python manage.py runserver 0.0.0.0:8000
```

4. Test from Flutter device/emulator:
```
http://YOUR_IP:8000/api/auth/constants/
```

## 4. Authentication Flow

### Register User
```dart
final response = await apiService.register({
  'username': 'testuser',
  'email': 'test@example.com',
  'password': 'password123',
  'password_confirm': 'password123',
  'first_name': 'Test',
  'last_name': 'User',
  'phone_number': '+255712345678',
  'church_position': 'muumini',
  'country': 'tanzania',
  'region': 'Dar es Salaam',
  'service_region': 'Kinondoni',
});
```

### Login
```dart
final response = await apiService.login(
  username: 'testuser',
  password: 'password123',
);

// Save tokens
await storage.setAccessToken(response['access']);
await storage.setRefreshToken(response['refresh']);
await storage.setUserId(response['user']['id']);
await storage.setUserRole(response['user']['role']);
```

### Get Current User
```dart
final user = await apiService.getCurrentUser();
print(user['first_name']);
print(user['role']);
print(user['church_position']);
```

## 5. Using API Services

See created files:
- `lib/core/services/api_service.dart` - Main API class
- `lib/core/services/auth_service.dart` - Authentication
- `lib/core/services/storage_service.dart` - Secure storage
- `lib/core/config/api_config.dart` - Configuration

## 6. Onboarding Integration

The onboarding screen now:
1. Fetches constants from backend (countries, regions, positions)
2. Validates church position selection
3. Includes registration number field
4. Has "Previous" button on bottom left
5. Submits data to backend on completion

## 7. Testing

1. Start backend: `python manage.py runserver 0.0.0.0:8000`
2. Run Flutter app: `flutter run`
3. Complete onboarding
4. Check Django admin to see new user

## Troubleshooting

### Connection Refused
- Ensure backend is running on 0.0.0.0:8000
- Check firewall allows port 8000
- Verify IP address is correct
- Test with browser first: http://YOUR_IP:8000/swagger/

### CORS Error
- Backend CORS is already configured
- Check CORS_ALLOWED_ORIGINS in backend/.env

### Authentication Error
- Ensure tokens are being saved
- Check token expiry (60 min default)
- Use refresh token to get new access token
