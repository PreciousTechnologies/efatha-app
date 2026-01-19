# 🚀 Efatha App - Startup Scripts

## Overview

Three powerful batch scripts to automate IP detection and app startup:

1. **`update_ip.bat`** - Simple IP updater
2. **`update_ip_advanced.bat`** - Advanced IP updater with multiple network support
3. **`start_efatha.bat`** - ONE-CLICK complete app startup ⭐ RECOMMENDED

---

## 📋 Script Details

### 1. `update_ip.bat` - Simple IP Updater

**What it does:**
- Detects your current IP address
- Updates `lib/core/config/api_config.dart` automatically
- Creates backup of configuration
- Optionally starts Django server

**Usage:**
```bash
update_ip.bat
```

**Features:**
- ✅ Automatic IP detection
- ✅ Auto-backup configuration
- ✅ One-click server start
- ✅ Simple and fast

---

### 2. `update_ip_advanced.bat` - Advanced IP Updater

**What it does:**
- Detects ALL network interfaces
- Shows all available IP addresses
- Lets you choose which IP to use
- Updates configuration
- Creates timestamped backups

**Usage:**
```bash
update_ip_advanced.bat
```

**When to use:**
- Multiple network adapters (WiFi + Ethernet)
- VPN connections
- Virtual machines
- Need to select specific IP

**Features:**
- ✅ Multiple IP detection
- ✅ Manual IP selection
- ✅ Timestamped backups
- ✅ Configuration verification

---

### 3. `start_efatha.bat` - ONE-CLICK STARTUP ⭐

**What it does:**
- Detects IP automatically
- Updates Flutter configuration
- Checks Django backend
- Checks port availability
- Provides startup options menu

**Usage:**
```bash
start_efatha.bat
```

**Startup Options:**
1. **Start Django Server Only** - Backend only
2. **Start Django + Flutter** - Full app in separate windows
3. **Show Server URLs** - Display all URLs and exit
4. **Exit**

**Features:**
- ✅ Complete automation
- ✅ Port conflict detection
- ✅ Multiple startup modes
- ✅ Beautiful ASCII logo
- ✅ Interactive menu
- ✅ Error handling

---

## 🎯 Quick Start Guide

### First Time Setup:

1. **Navigate to project folder:**
   ```bash
   cd C:\Users\MAXFYNN\Desktop\efatha_app
   ```

2. **Run the ONE-CLICK starter:**
   ```bash
   start_efatha.bat
   ```

3. **Select option 2** (Start Django + Flutter)

4. **Done!** 🎉

---

## 📖 Detailed Usage

### Scenario 1: Your IP Changed

**Problem:** Your IP changed from `10.146.127.233` to `192.168.1.100`

**Solution:**
```bash
# Option A: Quick update
update_ip.bat

# Option B: Choose from multiple IPs
update_ip_advanced.bat

# Option C: Update and start everything
start_efatha.bat
```

### Scenario 2: Start Development Session

**Just run:**
```bash
start_efatha.bat
```

Select option:
- **[1]** Backend only - Testing APIs
- **[2]** Full stack - Complete development
- **[3]** Check URLs - Reference only

### Scenario 3: Multiple Network Adapters

**If you have:**
- WiFi: 192.168.1.100
- Ethernet: 10.0.0.50
- VPN: 172.16.0.10

**Use:**
```bash
update_ip_advanced.bat
```

The script will show:
```
[1] 192.168.1.100
[2] 10.0.0.50
[3] 172.16.0.10

Select IP address number (1-3):
```

Choose the one you want!

---

## 🔧 What Gets Updated

### Configuration File:
**Location:** `lib/core/config/api_config.dart`

**Before:**
```dart
static const String baseUrl = 'http://10.146.127.233:8000';
```

**After:**
```dart
static const String baseUrl = 'http://YOUR_NEW_IP:8000';
```

### Backup Files Created:

**Simple backup:**
```
lib/core/config/api_config.dart.backup
```

**Timestamped backup:**
```
lib/core/config/api_config.dart.backup.20251012_143022
```

---

## 📡 Server URLs (After Update)

After running any script with IP `192.168.1.100`, you can access:

| Service | URL |
|---------|-----|
| **Backend API** | http://192.168.1.100:8000 |
| **Admin Panel** | http://192.168.1.100:8000/admin |
| **API Docs (Swagger)** | http://192.168.1.100:8000/swagger |
| **Register** | http://192.168.1.100:8000/api/auth/register/ |
| **Login** | http://192.168.1.100:8000/api/auth/login-password/ |
| **Profile** | http://192.168.1.100:8000/api/auth/users/me/ |

---

## 🛠️ Troubleshooting

### Issue: "Port 8000 already in use"

**Solution 1:** Use `start_efatha.bat` - it detects and offers to kill the process

**Solution 2:** Manual kill:
```bash
netstat -ano | findstr :8000
taskkill /PID <PID_NUMBER> /F
```

### Issue: "Config file not found"

**Check:** Make sure you're running the script from the project root:
```bash
C:\Users\MAXFYNN\Desktop\efatha_app
```

### Issue: "No IP addresses found"

**Check:**
1. Network connection active?
2. Run `ipconfig` manually to verify
3. Disable VPN if causing issues

### Issue: "Django not found"

**Check:**
```bash
cd backend
dir manage.py
```

If missing, check project structure.

---

## ⚙️ Advanced Configuration

### Customize Port

If you want to use a different port (e.g., 3000):

1. Edit the script, find:
   ```batch
   http://%IP%:8000
   ```

2. Change to:
   ```batch
   http://%IP%:3000
   ```

3. Start server with:
   ```bash
   python manage.py runserver 0.0.0.0:3000
   ```

### Skip IP Detection

To manually set IP in script:

1. Edit script
2. Find: `for /f "tokens=2 delims=:" %%a in ...`
3. Replace with: `set IP=192.168.1.100`

---

## 📝 Script Comparison

| Feature | update_ip.bat | update_ip_advanced.bat | start_efatha.bat |
|---------|---------------|------------------------|------------------|
| Auto IP detect | ✅ | ✅ | ✅ |
| Multiple IPs | ❌ | ✅ | ❌ |
| Config backup | ✅ | ✅ (timestamped) | ✅ |
| Start Django | Optional | Optional | ✅ Interactive |
| Start Flutter | ❌ | ❌ | ✅ Optional |
| Port check | ❌ | ❌ | ✅ |
| Menu interface | ❌ | ❌ | ✅ |
| ASCII art | ❌ | ❌ | ✅ |

---

## 🎨 Color Coding

Scripts use colors for better visibility:
- 🟢 **Green** - Success messages
- 🔵 **Blue** - Information
- 🟡 **Yellow** - Warnings
- 🔴 **Red** - Errors

---

## 🔄 Workflow Integration

### Daily Development Workflow:

```bash
# Morning: Start development session
start_efatha.bat
[Select option 2]

# Afternoon: IP changed, restart
start_efatha.bat
[Automatically detects new IP]
[Select option 2]

# Evening: Check server URLs
start_efatha.bat
[Select option 3]
```

### Quick Backend-Only Development:

```bash
update_ip.bat
[Y] Start server
```

### Testing on Multiple Devices:

```bash
update_ip_advanced.bat
[Select WiFi IP for mobile testing]
```

---

## 📚 Additional Resources

### Manual Commands (if scripts fail):

**Detect IP:**
```bash
ipconfig | findstr IPv4
```

**Update config manually:**
```bash
# Open: lib/core/config/api_config.dart
# Change: baseUrl = 'http://YOUR_IP:8000'
```

**Start Django:**
```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

**Start Flutter:**
```bash
flutter run
```

---

## 💡 Tips & Tricks

1. **Create desktop shortcut** to `start_efatha.bat` for instant access
2. **Run as administrator** if port kill doesn't work
3. **Check firewall** if mobile device can't connect
4. **Use WiFi IP** for testing on mobile devices
5. **Backup configs** before major changes

---

## 🎯 Recommended Usage

**For most users:**
```bash
start_efatha.bat → Option 2
```

**For backend testing:**
```bash
start_efatha.bat → Option 1
```

**For quick IP check:**
```bash
start_efatha.bat → Option 3
```

---

## 📞 Support

If scripts don't work:
1. Check you're in project root
2. Verify Python and Flutter installed
3. Check network connection
4. Run `ipconfig` to verify IP
5. Check file permissions

---

## 🎉 Success Indicators

After running script successfully:

✅ **See:** "Configuration updated: http://YOUR_IP:8000"
✅ **See:** "Starting development server at http://0.0.0.0:8000/"
✅ **See:** Flutter app running on device/emulator
✅ **Test:** Open http://YOUR_IP:8000/admin in browser

---

**Made with ❤️ for Efatha Church App**
