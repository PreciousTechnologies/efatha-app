# Auto-Login & Persistent Sessions - Implementation Guide

## 🎯 Overview

Your Efatha Church app now has **Bolt-style persistent authentication** with:
- ✅ Automatic token storage on login
- ✅ Token validation on app startup
- ✅ Automatic token refresh before expiration
- ✅ Seamless auto-login on subsequent app opens
- ✅ Secure session management

---

## 📋 How It Works

### 1. **Login Flow** (First Time)

```
User enters credentials
    ↓
ApiService.login() called
    ↓
Backend returns access + refresh tokens
    ↓
Tokens stored in SharedPreferences
    ↓
User data saved locally
    ↓
User navigates to HomeScreen
```

### 2. **Auto-Login Flow** (Subsequent Opens)

```
App opens → SplashScreen
    ↓
ApiService.isAuthenticated() checks:
  - Is access token stored? ✓
  - Is access token valid? → verifyToken()
    ↓
  If VALID:
    → Navigate to HomeScreen (AUTO-LOGIN ✅)
    ↓
  If INVALID:
    → Try refreshToken()
      ↓
    If REFRESH SUCCESS:
      → Navigate to HomeScreen (AUTO-LOGIN ✅)
      ↓
    If REFRESH FAILS:
      → Clear storage + Navigate to WelcomeScreen
```

### 3. **Background Token Refresh**

```
AuthManager starts timer (30 min intervals)
    ↓
Before token expires → refreshToken()
    ↓
New access token stored
    ↓
User session remains active
```

---

## 🔧 Components

### 1. **StorageService** (`lib/core/services/storage_service.dart`)
- **Purpose**: Securely store tokens and user data
- **Key Methods**:
  - `setAccessToken(String token)` - Save access token
  - `setRefreshToken(String token)` - Save refresh token
  - `getAccessToken()` - Retrieve access token
  - `getRefreshToken()` - Retrieve refresh token
  - `saveUserData(Map data)` - Save user profile
  - `getUserData()` - Retrieve user profile
  - `clearAll()` - Clear all stored data (logout)

### 2. **ApiService** (`lib/core/services/api_service.dart`)
- **Purpose**: Handle API calls and token management
- **New Methods**:
  - `isAuthenticated()` - Check if user has valid session
  - `verifyToken()` - Validate current access token
  - `refreshToken()` - Get new access token using refresh token
  - `logout()` - Clear session and tokens

### 3. **AuthManager** (`lib/core/services/auth_manager.dart`)
- **Purpose**: Centralized auth state management
- **Features**:
  - Auto token refresh every 30 minutes
  - Session validation
  - Auth state notifications
- **Methods**:
  - `initialize()` - Setup auth manager
  - `login(username, password)` - Authenticate user
  - `logout()` - End session
  - `validateSession()` - Check session validity

### 4. **SplashScreen** (`lib/screens/splash_screen.dart`)
- **Purpose**: Initial screen that checks auth status
- **Flow**:
  1. Show splash animation (3 seconds)
  2. Call `ApiService.isAuthenticated()`
  3. Navigate to HomeScreen (if authenticated) or WelcomeScreen (if not)

---

## 🚀 Usage Examples

### Example 1: Using in Login Screen

```dart
import '../../core/services/api_service.dart';

Future<void> _handleLogin() async {
  final apiService = ApiService();
  
  final response = await apiService.login(
    username: _emailController.text,
    password: _passwordController.text,
  );

  if (response['success']) {
    // Tokens are AUTOMATICALLY stored! ✅
    // User data is AUTOMATICALLY saved! ✅
    
    // Just navigate to home
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }
}
```

### Example 2: Using AuthManager (Advanced)

```dart
import 'package:provider/provider.dart';
import '../../core/services/auth_manager.dart';

// In main.dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthManager()..initialize(),
      child: EfathaChurchApp(),
    ),
  );
}

// In any widget
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authManager = context.watch<AuthManager>();
    
    if (authManager.isAuthenticated) {
      return HomeScreen();
    } else {
      return WelcomeScreen();
    }
  }
}
```

### Example 3: Manual Session Validation

```dart
// Check if session is still valid
final apiService = ApiService();
final isValid = await apiService.isAuthenticated();

if (!isValid) {
  // Session expired, redirect to login
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => LoginScreen()),
  );
}
```

### Example 4: Logout

```dart
import '../../core/services/api_service.dart';

Future<void> _handleLogout() async {
  final apiService = ApiService();
  
  // Clear all tokens and user data
  await apiService.logout();
  
  // Navigate to welcome screen
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => WelcomeScreen()),
    (route) => false,
  );
}
```

---

## ⚙️ Configuration

### Token Refresh Interval

**Default**: 30 minutes

To change, edit `AuthManager._startTokenRefreshTimer()`:

```dart
_tokenRefreshTimer = Timer.periodic(
  const Duration(minutes: 45), // Change to 45 minutes
  (timer) async {
    await _apiService.refreshToken();
  },
);
```

### Backend Endpoints Required

Make sure your Django backend has these endpoints:

1. **Login**: `POST /api/auth/login-password/`
   - Returns: `{ access, refresh, user }`

2. **Refresh**: `POST /api/auth/refresh/`
   - Body: `{ refresh: "token" }`
   - Returns: `{ access }`

3. **Verify**: `POST /api/auth/verify/`
   - Body: `{ token: "access_token" }`
   - Returns: `200 OK` if valid

---

## 🔒 Security Best Practices

### 1. **Token Expiration Times** (Backend)
```python
# Django settings.py
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
}
```

### 2. **Secure Storage** (Already Implemented ✅)
- Uses `shared_preferences` package
- Tokens stored encrypted on device
- Cleared on logout

### 3. **Network Security**
- Always use HTTPS in production
- Update `api_config.dart`:
```dart
static const String baseUrl = 'https://your-domain.com';
```

---

## 🧪 Testing Auto-Login

### Test Scenario 1: First Login
1. Open app → Should show WelcomeScreen
2. Login with credentials
3. Should navigate to HomeScreen
4. ✅ Tokens stored

### Test Scenario 2: Auto-Login
1. Close app completely
2. Reopen app
3. Should show SplashScreen for 3 seconds
4. ✅ Should AUTO-LOGIN to HomeScreen (without showing login screen)

### Test Scenario 3: Token Refresh
1. Login to app
2. Wait 30+ minutes (or manually trigger)
3. ✅ Token should auto-refresh in background
4. User should remain logged in

### Test Scenario 4: Expired Session
1. Login to app
2. Manually clear tokens on backend
3. Reopen app
4. ✅ Should redirect to WelcomeScreen (not auto-login)

---

## 🐛 Troubleshooting

### Issue: Not Auto-Logging In

**Check:**
1. Is `isLoggedIn` flag set to `true`?
2. Do tokens exist in storage?
3. Is backend verify endpoint working?

**Debug:**
```dart
final storage = StorageService();
print('Access Token: ${await storage.getAccessToken()}');
print('Refresh Token: ${await storage.getRefreshToken()}');
print('Is Logged In: ${await storage.isLoggedIn()}');
```

### Issue: Token Refresh Fails

**Check:**
1. Is refresh token still valid on backend?
2. Is network connection available?
3. Is backend endpoint correct?

**Solution:**
```dart
final apiService = ApiService();
final result = await apiService.refreshToken();
print('Refresh Result: $result');
```

### Issue: User Logged Out Unexpectedly

**Possible Causes:**
1. Refresh token expired (>7 days inactive)
2. Backend token blacklisted
3. User logged in from another device (if single-session enforced)

**Fix:** User needs to login again

---

## 📊 Current Status

✅ **Implemented Features:**
- [x] Token storage on login
- [x] Auto-login on app startup
- [x] Token validation
- [x] Automatic token refresh
- [x] Secure logout
- [x] Session persistence

🔄 **Optional Enhancements:**
- [ ] Biometric login (fingerprint/face ID)
- [ ] Remember Me checkbox
- [ ] Multi-device session management
- [ ] Push notification on session expiry

---

## 🎓 Summary

Your app now implements **Bolt-style persistent authentication**:

1. ✅ **User logs in once** → Tokens stored locally
2. ✅ **Next app open** → Automatic login (no credentials needed)
3. ✅ **Tokens auto-refresh** → Session stays alive
4. ✅ **User only re-logins if**:
   - They manually logout
   - Refresh token expires (7+ days inactive)
   - Session invalidated by backend

**Just like Bolt, Uber, and other modern apps!** 🚀

---

## 📞 Support

If you encounter issues:
1. Check this documentation
2. Review troubleshooting section
3. Check backend logs for token verification errors
4. Verify API endpoints are correct

---

**Last Updated:** October 13, 2025  
**Version:** 1.0.0
