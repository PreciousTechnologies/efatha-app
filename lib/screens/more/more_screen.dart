import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/config/api_config.dart';
import '../welcome/welcome_screen.dart';
import 'profile_section.dart';
import 'testimony_screen.dart';
import 'live_screen.dart';
import 'media_library_screen.dart';
import 'user_management_screen.dart';
import 'reports_screen.dart';
import 'enhanced_bible_screen.dart';
import 'tenzi_screen.dart';

/// More Screen - Additional features with drawer navigation
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic> _userData = {};
  bool _isLoadingUser = true;
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Try to get user data from storage first
      final storedData = await _storageService.getUserData();

      if (storedData.isNotEmpty) {
        setState(() {
          _userData = storedData;
          _isLoadingUser = false;
        });
      }

      // Also fetch fresh data from API
      final response = await _apiService.getCurrentUser();
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _userData = response['data'];
          _isLoadingUser = false;
        });
        // Update stored data
        await _storageService.saveUserData(response['data']);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  String _getInitials() {
    final firstName = _userData['first_name']?.toString() ?? '';
    final lastName = _userData['last_name']?.toString() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      final email = _userData['email']?.toString() ?? '';
      return email.isNotEmpty ? email[0].toUpperCase() : 'U';
    }

    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
  }

  String _getFullName() {
    final firstName = _userData['first_name']?.toString() ?? '';
    final lastName = _userData['last_name']?.toString() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      return _userData['username']?.toString() ?? 'User';
    }

    return '$firstName $lastName'.trim();
  }

  String? _getProfilePictureUrl() {
    final profilePicture = _userData['profile_picture'];
    if (profilePicture == null) return null;

    final url = profilePicture.toString();
    // If it's already a full URL, return as-is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Otherwise, prepend the base URL from ApiConfig
    return '${ApiConfig.baseUrl}$url';
  }

  String _getRoleDisplay() {
    return _userData['role_display']?.toString() ??
        _userData['role']?.toString() ??
        'Member';
  }

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Profile',
      'icon': Icons.person_outline,
      'gradient': [Color(0xFF6B4CE6), Color(0xFF9B7FED)],
    },
    {
      'title': 'Testimony',
      'icon': Icons.favorite_outline,
      'gradient': [Color(0xFFE91E63), Color(0xFFFF4081)],
    },
    {
      'title': 'Live',
      'icon': Icons.video_camera_front_outlined,
      'gradient': [Color(0xFFFF5722), Color(0xFFFF7043)],
      'badge': 'LIVE',
    },
    {
      'title': 'Bible',
      'icon': Icons.menu_book_outlined,
      'gradient': [Color(0xFF795548), Color(0xFF8D6E63)],
    },
    {
      'title': 'Tenzi za Rohoni',
      'icon': Icons.music_note_rounded,
      'gradient': [Color(0xFF6B4CE6), Color(0xFF9B7FED)],
    },
    {
      'title': 'Media Library',
      'icon': Icons.library_music_outlined,
      'gradient': [Color(0xFF4CAF50), Color(0xFF66BB6A)],
    },
    {
      'title': 'User Management',
      'icon': Icons.people_outline,
      'gradient': [Color(0xFF2196F3), Color(0xFF42A5F5)],
      'isAdmin': true,
    },
    {
      'title': 'Reports',
      'icon': Icons.assessment_outlined,
      'gradient': [Color(0xFF9C27B0), Color(0xFFBA68C8)],
      'isAdmin': true,
    },
  ];

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const ProfileSection();
      case 1:
        return const TestimonyScreen();
      case 2:
        return const LiveScreen();
      case 3:
        return const EnhancedBibleScreen();
      case 4:
        return const TenziScreen();
      case 5:
        return const MediaLibraryScreen();
      case 6:
        return const UserManagementScreen();
      case 7:
        return const ReportsScreen();
      default:
        return const ProfileSection();
    }
  }

  // Show full-screen profile picture viewer (WhatsApp style)
  void _showFullScreenImage() {
    final imageUrl = _getProfilePictureUrl();
    if (imageUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _getFullName(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primaryPurpleDeep,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getScreenTitle() => _menuItems[_selectedIndex]['title'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurpleDeep,
                    AppColors.primaryPurpleVibrant,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu, color: Colors.white, size: 20),
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          _getScreenTitle(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: _getSelectedScreen(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurpleDeep,
                    AppColors.primaryPurpleVibrant,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _getProfilePictureUrl() != null
                        ? _showFullScreenImage
                        : null,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: _getProfilePictureUrl() != null
                            ? DecorationImage(
                                image: NetworkImage(_getProfilePictureUrl()!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _getProfilePictureUrl() == null
                          ? Center(
                              child: _isLoadingUser
                                  ? const SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryPurpleDeep,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _getInitials(),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryPurpleDeep,
                                      ),
                                    ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isLoadingUser ? 'Loading...' : _getFullName(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoadingUser ? '' : _getRoleDisplay(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _menuItems.length,
                itemBuilder: (ctx, i) => _buildMenuItem(ctx, i),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext ctx, int i) {
    final item = _menuItems[i];
    final isSelected = _selectedIndex == i;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = i);
          Navigator.pop(ctx);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primaryPurpleDeep.withOpacity(0.1),
                      AppColors.primaryPurpleLight.withOpacity(0.1),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: AppColors.primaryPurpleDeep.withOpacity(0.3),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: item['gradient'])
                      : null,
                  color: isSelected ? null : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item['icon'],
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['title'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primaryPurpleDeep
                        : Colors.grey[700],
                  ),
                ),
              ),
              if (item['isAdmin'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              if (item['badge'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red, Colors.red[700]!],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item['badge'],
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(c);

              // Show loading indicator
              showDialog(
                context: ctx,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final apiService = ApiService();
                final storageService = StorageService();

                // Call logout API
                await apiService.logout();

                // Clear local storage
                await storageService.clearAll();

                if (!mounted) return;

                // Close loading dialog
                Navigator.pop(ctx);

                // Navigate to welcome screen and remove all previous routes
                Navigator.of(ctx).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );

                // Show success message
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                // Close loading dialog
                Navigator.pop(ctx);

                // Show error message
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Logout failed: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
