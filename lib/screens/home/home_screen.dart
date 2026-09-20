import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../core/config/api_config.dart';
import '../sermons/sermons_screen.dart';
import '../events/events_screen.dart';
import '../prayers/prayers_screen.dart';
import '../donations/donations_screen.dart';
import '../more/more_screen.dart';
import '../welcome/welcome_screen.dart';

/// Main Home Screen with bottom navigation
/// Hub for all church activities and features
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    SermonsScreen(),
    EventsScreen(),
    PrayersScreen(),
    DonationsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.neutralTextMuted.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.neutralBackgroundLightest,
        selectedItemColor: AppColors.primaryPurpleDeep,
        unselectedItemColor: AppColors.neutralTextMuted,
        selectedLabelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.caption,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            activeIcon: Icon(Icons.play_circle),
            label: 'Sermons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Prayers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism_outlined),
            activeIcon: Icon(Icons.volunteer_activism),
            label: 'Give',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            activeIcon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
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
      // Supabase-first (Django fallback while migrating).
      if (SupabaseConfig.isConfigured) {
        try {
          final profile = await SupabaseAuthService().getCurrentProfile();
          if (profile != null && mounted) {
            setState(() {
              _userData = profile;
              _isLoadingUser = false;
            });
            return;
          }
        } catch (_) {
          // Fall through to Django.
        }
      }

      // Try to get user data from storage first
      final storedData = await _storageService.getUserData();

      if (storedData.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userData = storedData;
            _isLoadingUser = false;
          });
        }
      }

      // Also fetch fresh data from API
      final response = await _apiService.getCurrentUser();
      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _userData = response['data'];
            _isLoadingUser = false;
          });
        }
        // Update stored data
        await _storageService.saveUserData(response['data']);
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
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

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppColors.dangerRedPrimary),
            const SizedBox(width: 12),
            const Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRedPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (SupabaseConfig.isConfigured) {
        try {
          await SupabaseAuthService().signOut();
        } catch (_) {}
      }
      await _apiService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      image: _getProfilePictureUrl() != null
                          ? DecorationImage(
                              image: NetworkImage(_getProfilePictureUrl()!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.white,
                    ),
                    child: _getProfilePictureUrl() == null
                        ? Center(
                            child: Text(
                              _getInitials(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryPurpleDeep,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFullName(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getRoleDisplay(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            _buildMenuItem(
              icon: Icons.person_outline,
              iconColor: AppColors.primaryPurpleDeep,
              title: 'Profile',
              subtitle: 'View and edit your profile',
              onTap: () {
                Navigator.pop(context);
                // Navigate to More screen then switch to Profile tab
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MoreScreen()),
                );
              },
            ),

            _buildMenuItem(
              icon: Icons.help_outline,
              iconColor: AppColors.accentTeal,
              title: 'Help & Support',
              subtitle: 'Get help or contact support',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Help & Support - Coming Soon!'),
                    backgroundColor: AppColors.accentTeal,
                  ),
                );
              },
            ),

            _buildMenuItem(
              icon: Icons.logout,
              iconColor: AppColors.dangerRedPrimary,
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              onTap: () {
                Navigator.pop(context);
                _handleSignOut();
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBackgroundSoft,
      body: CustomScrollView(
        slivers: [
          // Enhanced White App Bar
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Row: Profile + Notification (Left) | Membership Number (Right)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left: Profile + Notification
                            Row(
                              children: [
                                // Profile Picture
                                GestureDetector(
                                  onTap: _showProfileMenu,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primaryPurpleDeep,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryPurpleDeep
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      image: _getProfilePictureUrl() != null
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                _getProfilePictureUrl()!,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      gradient: _getProfilePictureUrl() == null
                                          ? LinearGradient(
                                              colors: [
                                                AppColors.primaryPurpleDeep,
                                                AppColors.primaryPurpleVibrant,
                                              ],
                                            )
                                          : null,
                                    ),
                                    child: _getProfilePictureUrl() == null
                                        ? Center(
                                            child: _isLoadingUser
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : Text(
                                                    _getInitials(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Notification Bell
                                Stack(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPurpleDeep
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.notifications_outlined,
                                        color: AppColors.primaryPurpleDeep,
                                        size: 24,
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.dangerRedPrimary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Right: Membership Number Badge
                            if (!_isLoadingUser &&
                                _userData['membership_number'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryPurpleDeep,
                                      AppColors.primaryPurpleVibrant,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPurpleDeep
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.badge_outlined,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '#${_userData['membership_number']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Bottom Row: Logo + Church Name
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryPurpleDeep
                                        .withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/efathalogo.jpeg',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Efatha Church',
                                    style: TextStyle(
                                      color: AppColors.primaryPurpleDeep,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26,
                                      letterSpacing: -0.5,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _isLoadingUser
                                              ? 'Welcome back! 🙏'
                                              : 'Welcome back ${_getFullName()}! 🙏',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured Live Service Banner
                  _EnhancedFeaturedBanner(),

                  const SizedBox(height: 28),

                  // Quick Stats
                  Row(
                    children: [
                      Icon(
                        Icons.auto_graph_rounded,
                        size: 20,
                        color: AppColors.primaryPurpleDeep,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Community Highlights',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _EnhancedQuickStatsGrid(),

                  const SizedBox(height: 28),

                  // Quick Actions
                  Row(
                    children: [
                      Icon(
                        Icons.apps_rounded,
                        size: 20,
                        color: AppColors.primaryPurpleDeep,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Actions',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _QuickActionsGrid(),

                  const SizedBox(height: 28),

                  // Upcoming Events
                  Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 20,
                        color: AppColors.primaryPurpleDeep,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Upcoming Events',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: AppColors.primaryPurpleDeep,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _EnhancedUpcomingEventsList(),

                  const SizedBox(height: 28),

                  // Recent Prayers
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 20,
                        color: AppColors.primaryPurpleDeep,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Prayer Requests',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: AppColors.primaryPurpleDeep,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _EnhancedRecentPrayersList(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedFeaturedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurpleDeep,
            AppColors.primaryPurpleVibrant,
            AppColors.accentBlueBrand,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurpleDeep.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -20,
            child: Icon(
              Icons.play_circle_outline,
              size: 120,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.circle, color: Colors.white, size: 7),
                      SizedBox(width: 5),
                      Text(
                        'LIVE NOW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sunday Service',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Join us for worship and praise',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text(
                        'Watch Live',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryPurpleDeep,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Schedule',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedQuickStatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EnhancedStatCard(
            icon: Icons.people_rounded,
            count: '1,234',
            label: 'Members',
            gradient: [Colors.blue[400]!, Colors.blue[600]!],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _EnhancedStatCard(
            icon: Icons.favorite_rounded,
            count: '89',
            label: 'Prayers',
            gradient: [Colors.pink[400]!, Colors.pink[600]!],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _EnhancedStatCard(
            icon: Icons.event_rounded,
            count: '12',
            label: 'Events',
            gradient: [Colors.purple[400]!, Colors.purple[600]!],
          ),
        ),
      ],
    );
  }
}

class _EnhancedStatCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final List<Color> gradient;

  const _EnhancedStatCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'icon': Icons.play_circle_outline,
        'label': 'Sermons',
        'color': Colors.purple,
      },
      {
        'icon': Icons.volunteer_activism,
        'label': 'Give',
        'color': Colors.green,
      },
      {'icon': Icons.menu_book, 'label': 'Bible', 'color': Colors.orange},
      {'icon': Icons.groups, 'label': 'Connect', 'color': Colors.blue},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  action['label'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EnhancedUpcomingEventsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final events = [
      {
        'title': 'Youth Fellowship',
        'date': 'Saturday, 3:00 PM',
        'color': Colors.orange,
        'icon': Icons.groups,
      },
      {
        'title': 'Bible Study',
        'date': 'Wednesday, 6:00 PM',
        'color': Colors.green,
        'icon': Icons.menu_book,
      },
    ];

    return Column(
      children: events.map((event) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (event['color'] as Color).withValues(alpha: 0.7),
                      event['color'] as Color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  event['icon'] as IconData,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'] as String,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event['date'] as String,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurpleDeep.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.primaryPurpleDeep,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EnhancedRecentPrayersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prayers = [
      {
        'name': 'Sarah Johnson',
        'time': '2 hours ago',
        'priority': 'HIGH',
        'priorityColor': Colors.red,
        'text':
            'Please pray for my family during this challenging time. We need strength and guidance...',
        'praying': 24,
      },
      {
        'name': 'Michael Brown',
        'time': '5 hours ago',
        'priority': 'MEDIUM',
        'priorityColor': Colors.orange,
        'text': 'Requesting prayers for healing and recovery from surgery...',
        'praying': 18,
      },
    ];

    return Column(
      children: prayers.map((prayer) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurpleDeep,
                          AppColors.primaryPurpleVibrant,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer['name'] as String,
                          style: AppTextStyles.bodyMediumWeight.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          prayer['time'] as String,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: (prayer['priorityColor'] as Color).withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: prayer['priorityColor'] as Color,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      prayer['priority'] as String,
                      style: TextStyle(
                        color: prayer['priorityColor'] as Color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                prayer['text'] as String,
                style: AppTextStyles.bodyRegular.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 16,
                    color: AppColors.primaryPurpleDeep,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${prayer['praying']} people praying',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryPurpleDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      backgroundColor: AppColors.primaryPurpleDeep.withValues(
                        alpha: 0.1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Pray',
                      style: TextStyle(
                        color: AppColors.primaryPurpleDeep,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
