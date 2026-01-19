# 🚀 Efatha Church App - Setup & Running Guide

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software
1. **Flutter SDK** (version 3.8.1 or higher)
   - Download from: https://docs.flutter.dev/get-started/install
   - Verify: `flutter --version`

2. **Dart SDK** (comes with Flutter)
   - Verify: `dart --version`

3. **Android Studio** (for Android development)
   - Download from: https://developer.android.com/studio
   - Install Android SDK and command-line tools

4. **VS Code** or **Android Studio** with Flutter extensions
   - VS Code Flutter extension: https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter
   - VS Code Dart extension: https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code

5. **Git** (for version control)
   - Download from: https://git-scm.com/

### Optional (for other platforms)
- **Windows SDK** (for Windows desktop apps)
- **Chrome** (for web development)

## 🔧 Initial Setup

### 1. Clone the Repository
```bash
git clone https://github.com/MrINstructor333/ride1.git
cd efatha_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

This will download all required packages listed in `pubspec.yaml`.

### 3. Verify Flutter Setup
```bash
flutter doctor
```

This command checks your environment and displays a report. Fix any issues marked with [✗].

### 4. Check Connected Devices
```bash
flutter devices
```

This shows all available devices/emulators.

## 📱 Running the App

### Option 1: Using Command Line

#### Run on Android Emulator
```bash
# Start an Android emulator first, then:
flutter run
```

#### Run on Android Physical Device
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect device via USB
4. Run: `flutter run`

#### Run on Windows Desktop
```bash
flutter run -d windows
```

#### Run on Web (Chrome)
```bash
flutter run -d chrome
```

### Option 2: Using VS Code
1. Open the project folder in VS Code
2. Press `F5` or click "Run" → "Start Debugging"
3. Select your target device from the dropdown

### Option 3: Using Android Studio
1. Open the project in Android Studio
2. Select your target device from the device dropdown
3. Click the "Run" button (green play icon)

## 🔨 Building for Production

### Android APK (for testing)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Google Play)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Windows Desktop App
```bash
flutter build windows --release
```
Output: `build/windows/runner/Release/`

### Web Application
```bash
flutter build web --release
```
Output: `build/web/`

## 🐛 Troubleshooting

### Issue: "flutter: command not found"
**Solution**: Add Flutter to your PATH environment variable
```bash
# Windows PowerShell
$env:Path += ";C:\path\to\flutter\bin"

# Verify
flutter --version
```

### Issue: Android licenses not accepted
**Solution**: Run the following command:
```bash
flutter doctor --android-licenses
```
Accept all licenses by typing 'y'.

### Issue: Gradle build fails
**Solution**: 
1. Clear Gradle cache:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   ```
2. Try again:
   ```bash
   flutter run
   ```

### Issue: "Waiting for another flutter command to release the startup lock"
**Solution**: Delete the lock file:
```bash
# Windows
del %LOCALAPPDATA%\Pub\Cache\.flutter_tool_state.lock

# Or navigate to Flutter installation
cd C:\path\to\flutter\bin\cache
del lockfile
```

### Issue: Hot reload not working
**Solution**: 
1. Stop the app
2. Run: `flutter clean`
3. Run: `flutter pub get`
4. Restart the app

## 📊 Performance Tips

### Optimize Build Times
1. **Use flavors for debug builds**:
   ```bash
   flutter run --debug
   ```

2. **Enable multidex** (if app size is large):
   In `android/app/build.gradle`, add:
   ```gradle
   android {
       defaultConfig {
           multiDexEnabled true
       }
   }
   ```

### Speed Up Development
1. **Use hot reload**: Press `r` in terminal while app is running
2. **Use hot restart**: Press `R` in terminal
3. **Use emulator snapshots**: Save emulator state for faster startup

## 🧪 Testing

### Run All Tests
```bash
flutter test
```

### Run Specific Test
```bash
flutter test test/widget_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

## 📦 Project Structure Quick Reference

```
efatha_app/
├── android/          # Android-specific files
├── assets/           # Images, fonts, etc.
│   ├── images/
│   └── icons/
├── lib/              # Main application code
│   ├── core/         # Core functionality
│   │   ├── theme/    # App theming
│   │   └── constants/
│   ├── widgets/      # Reusable widgets
│   └── screens/      # App screens
├── test/             # Test files
├── web/              # Web-specific files
├── windows/          # Windows-specific files
├── pubspec.yaml      # Dependencies
└── README.md         # Documentation
```

## 🎨 Development Workflow

### Recommended Workflow
1. **Start with design**: Plan your screen layout
2. **Build UI first**: Create the visual components
3. **Add functionality**: Implement business logic
4. **Test thoroughly**: Test on multiple devices
5. **Optimize**: Profile and improve performance

### Hot Reload vs Hot Restart
- **Hot Reload** (`r`): Updates UI changes instantly (preserves state)
- **Hot Restart** (`R`): Restarts app (resets state)
- **Full Restart**: Use when changing dependencies or native code

## 🔐 Environment Configuration

### Debug Mode (Development)
```bash
flutter run --debug
```
Features:
- Assertions enabled
- Service extensions enabled
- Compilation optimized for fast development

### Profile Mode (Performance Testing)
```bash
flutter run --profile
```
Features:
- Some optimizations enabled
- Service extensions enabled
- Performance overlay available

### Release Mode (Production)
```bash
flutter run --release
```
Features:
- Full optimizations
- No debugging information
- Smallest app size

## 📱 Device-Specific Notes

### Android
- Minimum SDK: 21 (Android 5.0 Lollipop)
- Target SDK: Latest stable
- Supports: ARM, ARM64, x86, x86_64

### Windows
- Minimum: Windows 10 (64-bit)
- Desktop app with native performance

### Web
- Modern browsers (Chrome, Firefox, Safari, Edge)
- Progressive Web App (PWA) ready

## 🆘 Getting Help

### Official Resources
- Flutter Docs: https://docs.flutter.dev/
- Flutter Community: https://flutter.dev/community
- Stack Overflow: https://stackoverflow.com/questions/tagged/flutter

### Project-Specific
- Check `PROJECT_DOCS.md` for architecture details
- Check `README.md` for feature documentation
- Review code comments for implementation details

## ✅ Pre-Launch Checklist

Before deploying:
- [ ] All tests pass: `flutter test`
- [ ] No errors: `flutter analyze`
- [ ] Tested on multiple devices
- [ ] App icons configured
- [ ] Splash screen configured
- [ ] App name and description updated
- [ ] Version number updated
- [ ] Privacy policy added
- [ ] Terms of service added
- [ ] Analytics configured
- [ ] Crash reporting enabled

## 🎯 Quick Start Commands

```bash
# Setup
flutter pub get

# Development
flutter run                    # Run on connected device
flutter run -d chrome          # Run on web
flutter run -d windows         # Run on Windows

# Testing
flutter test                   # Run all tests
flutter analyze                # Check for issues

# Building
flutter build apk              # Android APK
flutter build appbundle        # Android App Bundle
flutter build windows          # Windows executable
flutter build web              # Web application

# Maintenance
flutter clean                  # Clean build cache
flutter pub upgrade            # Upgrade dependencies
flutter doctor                 # Check environment
```

## 🌟 Tips for Best Results

1. **Keep Flutter Updated**: Run `flutter upgrade` regularly
2. **Use Version Control**: Commit often with clear messages
3. **Write Tests**: Ensure code quality and prevent regressions
4. **Profile Performance**: Use DevTools for optimization
5. **Follow Style Guide**: Use `flutter format` for consistent code style
6. **Document Changes**: Update README and docs with new features

---

**Happy Coding! 🚀**

For questions or issues, check the troubleshooting section or reach out to the development team.
