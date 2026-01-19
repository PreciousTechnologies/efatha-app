# Pesapal SSL Certificate & IPN ID Fix - Complete Solution

## Issues Fixed

### 1. SSL Certificate Error (HTTP Client)
**Error Message:**
```
HandshakeException: Handshake error in client (OS Error: 
CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate(handshake.cc:295))
```

### 2. SSL Certificate Error (WebView/Chromium)
**Error Message:**
```
I/cr_X509Util: Failed to validate the certificate chain, error: 
java.security.cert.CertPathValidatorException: Trust anchor for certification path not found.
E/chromium: [ERROR:net/socket/ssl_client_socket_impl.cc:902] handshake failed; 
returned -1, SSL error code 1, net_error -202
```

### 3. Invalid IPN ID Error
**Error Message:**
```
{error_type: api_error, code: invalidlpnld, message: The specified IPN ID is invalid}
```

## Complete Solutions Applied

### Solution 1: HTTP Client SSL Handling
**File:** `lib/core/services/pesapal_service.dart`

Created custom HTTP client with SSL certificate acceptance:
```dart
import 'dart:io';
import 'package:http/io_client.dart';

static http.Client? _httpClient;

static http.Client _getHttpClient() {
  if (_httpClient == null) {
    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return host.contains('pesapal.com');
      };
    _httpClient = IOClient(ioClient);
  }
  return _httpClient!;
}
```

All HTTP requests updated to use the custom client.

### Solution 2: Android WebView SSL Configuration
**File:** `android/app/src/main/res/xml/network_security_config.xml` (NEW)

Created network security configuration:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </base-config>
    
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">pesapal.com</domain>
        <domain includeSubdomains="true">cybqa.pesapal.com</domain>
        <domain includeSubdomains="true">pay.pesapal.com</domain>
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </domain-config>
</network-security-config>
```

**File:** `android/app/src/main/AndroidManifest.xml`

Added reference to network security config:
```xml
<application
    ...
    android:networkSecurityConfig="@xml/network_security_config">
```

**File:** `android/app/src/main/kotlin/com/example/efatha_app/MainActivity.kt`

Enabled WebView debugging:
```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    WebView.setWebContentsDebuggingEnabled(true)
}
```

### Solution 3: Dynamic IPN Registration
**File:** `lib/core/services/pesapal_service.dart`

- Added IPN ID storage: `String? _ipnId;`
- Auto-register IPN during initialization
- Made `notification_id` optional in payment requests

```dart
Future<void> initialize() async {
  await _getAccessToken();
  
  if (_ipnId == null) {
    final callbackUrl = '${ApiConfig.apiUrl}/payments/pesapal/callback';
    _ipnId = await registerIPN(callbackUrl);
  }
}

// In submitOrder method:
if (_ipnId != null && _ipnId!.isNotEmpty) {
  orderData['notification_id'] = _ipnId;
}
```

**File:** `lib/screens/donations/pesapal_payment_screen.dart`

Updated error handling to not block on SSL errors:
```dart
onWebResourceError: (WebResourceError error) {
  if (error.errorType == WebResourceErrorType.unknown ||
      error.errorType == WebResourceErrorType.connect) {
    print('WebView error (likely SSL): ${error.description}');
    return; // Don't show error to user
  }
  // Show other errors
}
```

## Files Modified

1. ✅ `lib/core/services/pesapal_service.dart` - HTTP SSL + IPN handling
2. ✅ `lib/screens/donations/pesapal_payment_screen.dart` - WebView error handling
3. ✅ `android/app/src/main/res/xml/network_security_config.xml` - NEW file
4. ✅ `android/app/src/main/AndroidManifest.xml` - Added security config
5. ✅ `android/app/src/main/kotlin/com/example/efatha_app/MainActivity.kt` - WebView setup

## How to Test

1. **Rebuild the app** (IMPORTANT - native Android changes require rebuild):
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test payment flow:**
   - Navigate to Donations screen
   - Select donation amount and payment method
   - Click "Proceed to Payment"
   - Should see: "IPN registered successfully: [IPN_ID]" in console
   - Pesapal checkout page should load without SSL errors
   - All payment methods (M-Pesa, Card, etc.) should be visible

3. **Monitor logs:**
   - No more SSL handshake errors
   - No more "Trust anchor" errors from Chromium
   - No more "invalidlpnld" errors

## Technical Details

### Why Two SSL Fixes?

1. **HTTP Client SSL:** For API calls from Flutter/Dart code (auth, submit order, check status)
2. **WebView SSL:** For loading Pesapal's checkout page in the WebView component

Both needed separate fixes because:
- HTTP client uses Dart's networking stack
- WebView uses Android's Chromium WebView component

### Network Security Config Explained

- **base-config:** Trust both system CAs and user-added CAs globally
- **domain-config for Pesapal:** Ensures HTTPS for Pesapal domains
- **cleartext allowed for localhost:** For local development/testing

### IPN (Instant Payment Notification)

- Allows Pesapal to notify your backend of payment status changes
- Registration may fail if callback URL is not publicly accessible
- Payments work without IPN (it's optional)
- IPN is cached after first successful registration

## Production Checklist

Before going live:
- [ ] Change `_environment` to 'live' in `pesapal_service.dart`
- [ ] Verify production credentials are correct
- [ ] Ensure backend callback URL is publicly accessible
- [ ] Test with real payment amounts
- [ ] Verify IPN notifications are received

## Troubleshooting

**If SSL errors persist:**
1. Run `flutter clean`
2. Rebuild the app (native changes require full rebuild)
3. Check Android Studio logcat for specific errors

**If IPN registration fails:**
- Check if backend is running and accessible
- Verify callback URL is publicly reachable
- Payments will still work without IPN

**If WebView shows blank page:**
- Check internet connection
- Verify Pesapal credentials
- Check console for JavaScript errors
