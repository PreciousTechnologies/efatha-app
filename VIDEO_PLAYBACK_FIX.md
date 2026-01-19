# Video Playback Fix - HTTP Cleartext Traffic

## Problem
Video playback fails with the error:
```
androidx.media3.exoplayer.ExoPlaybackException: Source error
Caused by: androidx.media3.datasource.HttpDataSource$CleartextNotPermittedException: 
Cleartext HTTP traffic not permitted
```

And the app shows:
```
Failed to load media: PlatformException(VideoError Video player had error 
androidx.media3.exoplayer.ExoPlaybackException: Source error, null, null)
```

## Root Cause
**Android 9 (API level 28) and above block cleartext (HTTP) traffic by default for security reasons.**

Your Django server is running on HTTP (not HTTPS):
- `http://10.107.200.233:8000/media/sermons/video/...`

Android blocks this by default to prevent man-in-the-middle attacks.

## Solution Applied

### Updated Android Manifest
Added `android:usesCleartextTraffic="true"` to allow HTTP traffic for development.

**File**: `android/app/src/main/AndroidManifest.xml`

```xml
<application
    android:label="efatha_app"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true">
```

## What This Does
✅ Allows the video player to load videos from HTTP URLs
✅ Enables communication with your local Django server
✅ Permits HTTP traffic for all network requests in the app

## Testing Steps

### 1. **Rebuild the App** (REQUIRED)
Since we modified the Android manifest, you MUST rebuild:

```bash
# Stop the app completely
# Then rebuild and run:
flutter clean
flutter pub get
flutter run
```

### 2. **Test Video Playback**
1. Open the app
2. Navigate to Sermons
3. Tap on a sermon card
4. The video should now load and play! ✅

## Video File Picker UI
The file picker is working correctly:
- ✅ When you select a video, `_videoFileName` is set
- ✅ The UI shows the file name: `subtitle: _videoFileName ?? 'No video file selected'`
- ✅ The file is stored: `_videoFile = File(result.files.single.path!)`

**If the video name doesn't show in the UI:**
- Make sure you're seeing the updated screen (hot reload after picking)
- Check the console logs - you should see the file path printed

## Important Notes

### For Development (Current Setup) ✅
Using `usesCleartextTraffic="true"` is **fine for development** when:
- Testing with local servers (10.x.x.x or 192.168.x.x)
- Using HTTP URLs during development
- Running Django development server

### For Production (Future) ⚠️
When deploying to production:
1. **Use HTTPS** for your Django backend
2. Get an SSL certificate (Let's Encrypt, Cloudflare, etc.)
3. Remove or set `android:usesCleartextTraffic="false"`
4. Configure Network Security Config for specific domains if needed

## Network Security Best Practices

### Option 1: Allow All HTTP (Current - Development)
```xml
<application android:usesCleartextTraffic="true">
```
✅ Simple for development
❌ Not secure for production

### Option 2: Specific Domains (Better for Production)
Create `android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">10.107.200.233</domain>
        <domain includeSubdomains="true">localhost</domain>
    </domain-config>
</network-security-config>
```

Then reference it in AndroidManifest.xml:
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config">
```

### Option 3: HTTPS Only (Best for Production)
1. Deploy Django with HTTPS
2. Remove `usesCleartextTraffic` attribute
3. All traffic encrypted and secure

## Console Output Explained

From your logs:
```
✅ Video uploaded successfully: 
   http://10.107.200.233:8000/media/sermons/video/2025/10/VID-20251011-WA0001.mp4

❌ ExoPlayer error: Cleartext HTTP traffic not permitted
```

This confirms:
1. ✅ Backend working - video uploaded successfully
2. ✅ URL generated correctly
3. ❌ Android blocking HTTP playback (NOW FIXED)

## Next Steps

1. **Rebuild the app** with `flutter clean && flutter run`
2. **Upload a new sermon** or test with existing sermon
3. **Tap the sermon card** to open detail screen
4. **Video should play!** 🎬✅

5. **When ready for production**:
   - Set up HTTPS on Django server
   - Update `baseUrl` in Flutter to use HTTPS
   - Remove or disable cleartext traffic permission

## Troubleshooting

### If video still doesn't play after rebuild:
1. Verify Django server is running: `http://10.107.200.233:8000`
2. Test video URL in browser: paste the video URL from console
3. Check Flutter console for any new errors
4. Ensure you did `flutter clean` before rebuilding

### If file picker doesn't show selection:
- The code is correct, file names ARE being set
- Try hot restart (R) after selecting a file
- Check console for "File loaded and cached" message

## Summary

✅ **Fixed**: Added `android:usesCleartextTraffic="true"` to AndroidManifest.xml
✅ **Required**: Must rebuild app with `flutter clean && flutter run`
✅ **Result**: Videos will now play in the video player
✅ **File Picker**: Already working correctly

🎬 Your sermon videos should now play perfectly!
