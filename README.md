# 🙏 Efatha Church App

A beautiful, spiritual Flutter application designed for the Efatha Church community to connect, worship, and grow together.

## ✨ Features

### 🏠 Home Dashboard
- **Welcome Hero Section**: Personalized greeting with upcoming service information
- **Community Highlights**: Quick stats showing members, active prayers, and upcoming events
- **Featured Content**: Dynamic banner highlighting current sermon series or special announcements
- **Quick Actions**: FAB menu for posting messages, announcements, prayer requests, testimonies, reports, and media uploads

### 🎙️ Sermons
- Browse and watch recorded sermons
- Grid/List view toggle
- Search functionality
- Video thumbnails with play controls
- Pastor information and sermon metadata
- View counts and duration

### 📅 Events
- Comprehensive event calendar
- Filter by date and category
- Event details with location and timing
- Status badges (Upcoming, Ongoing, Completed)
- Easy registration and RSVP

### 🙏 Prayer Requests
- Submit and view prayer requests
- Priority levels (Urgent, High, Normal)
- Community engagement (Pray button, Comments)
- User profiles and timestamps
- Filter by priority

### 💝 Donations & Giving
- Multiple donation categories:
  - **Upendo** (Love Offering) - Purple
  - **Injili** (Gospel) - Blue
  - **Mkuto** (General) - Red
- Total giving overview
- Donation history with receipts
- Secure giving interface

## 🎨 Design System

### Color Palette
The app follows a **purple-first spiritual aesthetic** with carefully chosen semantic colors:

- **Primary Purple**: `#6B46C1` (Deep), `#8B5CF6` (Light), `#7C3AED` (Vibrant)
- **Accent Blue**: `#2196F3` (Brand), `#4285F4` (Google), `#1877F2` (Facebook)
- **Success Green**: `#10B981` (Primary), `#059669` (Dark)
- **Warning Amber**: `#F59E0B`
- **Danger Red**: `#EF4444` (Primary), `#DC2626` (Dark)

### Typography
- **Headlines**: 24-32pt, Bold (Weight: 700)
- **Section Titles**: 16-18pt, Semi-bold (Weight: 600)
- **Body Copy**: 14-16pt, Regular (Weight: 400)
- **Metadata**: 12-14pt, Medium (Weight: 500)
- **Buttons**: 14-18pt, Semi-bold (Weight: 600)

### Spacing System
Consistent spacing throughout the app:
- XS: 6px, SM: 8px, MD: 12px, LG: 16px, XL: 20px
- Card radius: 12px
- Button radius: 8px
- Input radius: 12px
- Chip/Badge radius: 16-20px

## 🏗️ Architecture

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart       # Color palette
│   │   ├── app_text_styles.dart  # Typography
│   │   └── app_theme.dart        # Main theme config
│   └── constants/
│       └── app_spacing.dart      # Spacing system
├── widgets/
│   ├── app_button.dart           # Reusable button component
│   ├── app_card.dart             # Card component
│   ├── loading_spinner.dart      # Loading indicators
│   └── status_badge.dart         # Status/priority badges
├── screens/
│   ├── splash_screen.dart        # Animated splash screen
│   ├── auth/
│   │   └── login_screen.dart     # Authentication
│   ├── home/
│   │   └── home_screen.dart      # Main dashboard
│   ├── sermons/
│   │   └── sermons_screen.dart   # Sermons listing
│   ├── events/
│   │   └── events_screen.dart    # Events calendar
│   ├── prayers/
│   │   └── prayers_screen.dart   # Prayer requests
│   └── donations/
│       └── donations_screen.dart # Giving portal
└── main.dart                     # App entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.8.1)
- Dart SDK (^3.8.1)
- Android Studio / VS Code with Flutter extensions
- Android SDK (for Android development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/MrINstructor333/ride1.git
   cd efatha_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # Android
   flutter run

   # Windows
   flutter run -d windows

   # Web
   flutter run -d chrome
   ```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Windows
flutter build windows --release

# Web
flutter build web --release
```

## 📱 Supported Platforms

- ✅ **Android** (Primary target)
- ✅ **Windows**
- ✅ **Web**
- ✅ **Linux**
- ✅ **macOS**
- ❌ **iOS** (Not supported on Windows development environment)

## 🎯 Key Components

### AppButton
Versatile button component with multiple variants:
- **Primary**: Filled purple background
- **Secondary**: Filled blue background
- **Outline**: Bordered with transparent background
- **Text**: Text-only button
- **Sizes**: Small (32px), Medium (40px), Large (48px)
- **States**: Loading, Disabled, Full-width

### AppCard
Reusable card component with:
- White background
- 12px border radius
- Optional elevation/shadow
- Customizable padding/margin
- Tap handler support

### StatusBadge
Semantic status indicators:
- Success/Approved (Green)
- Warning/Pending (Amber)
- Danger/Failed (Red)
- Info (Blue)
- Auto-uppercase labels

## 🎨 Design Philosophy

The Efatha Church App embodies a **warm, pastoral tone** with:
- **Generous white space** for comfortable reading
- **Rounded corners** for approachable, friendly interface
- **Soft shadows** for subtle depth
- **Semantic colors** for instant visual communication
- **Consistent spacing rhythm** for visual harmony
- **High contrast** for accessibility

## 🔮 Creative Enhancements

Beyond the reference design, we've added:
- **Animated splash screen** with gradient background
- **Smooth page transitions** with fade effects
- **Quick action FAB** with modal bottom sheet
- **Interactive prayer cards** with engagement metrics
- **Gradient hero sections** for visual impact
- **Stat cards** with icon-driven data visualization
- **Pull-to-refresh** patterns (ready for implementation)
- **Empty states** with friendly messaging

## 🛠️ Development

### Code Style
- Follow Flutter's official style guide
- Use `const` constructors where possible
- Organize imports (Flutter, packages, relative)
- Maximum line length: 80 characters
- Use meaningful variable names

### State Management
Currently using built-in `setState` for simplicity. Consider these options for scaling:
- **Provider** for lightweight state management
- **Riverpod** for more complex state needs
- **Bloc** for enterprise-level architecture

## 📄 License

This project is private and intended for Efatha Church community use only.

## 👥 Contributors

- **Development**: MrINstructor333
- **Design Reference**: Efatha Church React Native App

## 🙌 Acknowledgments

Special thanks to the Efatha Church community for their vision and support in making this app a reality.

---

**Built with ❤️ and 🙏 for the Efatha Church Community**
# efatha-app
