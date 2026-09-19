import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';
import '../testimonies/submit_testimony_screen.dart';
import '../testimonies/testimony_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Testimony Screen - Share and view testimonies
class TestimonyScreen extends StatefulWidget {
  const TestimonyScreen({super.key});

  @override
  State<TestimonyScreen> createState() => _TestimonyScreenState();
}

class _TestimonyScreenState extends State<TestimonyScreen> {
  String _selectedFilter = 'Sunday Service';
  final List<String> _filters = [
    'Sunday Service',
    'Featured',
    'My Testimonies',
  ];

  List<Map<String, dynamic>> _testimonies = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final storageService = StorageService();
    final userId = await storageService.getUserId();
    setState(() => _currentUserId = userId);
    _loadTestimonies();
  }

  Future<void> _loadTestimonies() async {
    setState(() => _isLoading = true);

    try {
      final storageService = StorageService();
      final token = await storageService.getAccessToken();
      final response = await http.get(
        Uri.parse(ApiConfig.testimonies),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> data;

        // Handle both array response and paginated response
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded.containsKey('results')) {
          // Paginated response
          data = decoded['results'] as List;
        } else {
          // Unknown format, try to get any list
          data = [];
        }

        setState(() {
          _testimonies = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error loading testimonies: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading testimonies: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTestimonies {
    if (_selectedFilter == 'Sunday Service') {
      return _testimonies
          .where((t) => t['testimony_type'] == 'sunday_service')
          .toList();
    }
    if (_selectedFilter == 'Featured') {
      // Show all testimonies from other people (excluding current user's testimonies)
      return _testimonies.where((t) => t['user'] != _currentUserId).toList();
    }
    if (_selectedFilter == 'My Testimonies') {
      return _testimonies.where((t) => t['user'] == _currentUserId).toList();
    }
    // Default - show all
    return _testimonies;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Testimonies',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubmitTestimonyScreen(),
                ),
              );
              if (result == true) {
                _loadTestimonies();
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurpleDeep,
                    AppColors.primaryPurpleVibrant,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 60,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: AppColors.primaryPurpleLight.withValues(
                      alpha: 0.3,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primaryPurpleDeep
                          : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryPurpleDeep
                          : Colors.grey[300]!,
                    ),
                  ),
                );
              },
            ),
          ),

          // Testimonies List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTestimonies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No testimonies yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share your testimony!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTestimonies,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTestimonies.length,
                      itemBuilder: (context, index) {
                        return _buildTestimonyCard(_filteredTestimonies[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonyCard(Map<String, dynamic> testimony) {
    final testimonyType = testimony['testimony_type'] ?? 'regular';

    // Sunday Service Testimony Card (like Sermon Card)
    if (testimonyType == 'sunday_service') {
      return _buildSundayServiceCard(testimony);
    }

    // Regular Testimony Card
    final hasPhoto = testimony['photo_url'] != null;
    final hasVideo = testimony['video_url'] != null;
    final category = testimony['category'] ?? 'other';
    final prayerTitle = testimony['prayer_request_title'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestimonyDetailScreen(testimony: testimony),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Profile Picture
                  testimony['user_profile_picture'] != null
                      ? CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(
                            testimony['user_profile_picture'],
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.pink[400]!, Colors.pink[600]!],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              testimony['user_name']
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testimony['is_anonymous'] == true
                              ? 'Anonymous'
                              : testimony['user_name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDate(testimony['created_at']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getCategoryColors(category),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getCategoryLabel(category),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Prayer Link Banner (if linked to prayer)
            if (prayerTitle != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurpleLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryPurpleLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 16,
                      color: AppColors.primaryPurpleDeep,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Testimony for: $prayerTitle',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryPurpleDeep,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (prayerTitle != null) const SizedBox(height: 12),

            // Photo (if available)
            if (hasPhoto)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    testimony['photo_url'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 50),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (hasPhoto) const SizedBox(height: 12),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testimony['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    testimony['content'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Media Indicators
            if (hasVideo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        color: Colors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Video attached',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (hasVideo) const SizedBox(height: 12),

            // Featured Badge
            if (testimony['is_featured'] == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (testimony['is_featured'] == true) const SizedBox(height: 12),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _handlePraise(testimony),
                    child: Row(
                      children: [
                        Icon(
                          testimony['user_has_praised'] == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: testimony['user_has_praised'] == true
                              ? Colors.red
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          testimony['praise_count'] != null &&
                                  testimony['praise_count'] > 0
                              ? 'Praise (${testimony['praise_count']})'
                              : 'Praise',
                          style: TextStyle(
                            color: testimony['user_has_praised'] == true
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _handleShare(testimony),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.share_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Share',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sunday Service Testimony Card - Similar to Sermon Card
  Widget _buildSundayServiceCard(Map<String, dynamic> testimony) {
    final thumbnailUrl = testimony['thumbnail_url'];
    final hasVideo = testimony['video_url'] != null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestimonyDetailScreen(testimony: testimony),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with Play Button Overlay
            Stack(
              children: [
                // Thumbnail Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: thumbnailUrl != null
                      ? Image.network(
                          thumbnailUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 50),
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryPurpleDeep,
                                AppColors.primaryPurpleVibrant,
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.church,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),

                // Sunday Service Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
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
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.church, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Sunday Service',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Play Button Overlay (if has video)
                if (hasVideo)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: AppColors.primaryPurpleDeep,
                          size: 45,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    testimony['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // User and Date
                  Row(
                    children: [
                      // Profile Picture
                      testimony['user_profile_picture'] != null
                          ? CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage(
                                testimony['user_profile_picture'],
                              ),
                            )
                          : Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.pink[400]!,
                                    Colors.pink[600]!,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  testimony['user_name']
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              testimony['is_anonymous'] == true
                                  ? 'Anonymous'
                                  : testimony['user_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDate(testimony['created_at']),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _getCategoryColors(
                              testimony['category'] ?? 'other',
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getCategoryLabel(testimony['category'] ?? 'other'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle Praise action
  Future<void> _handlePraise(Map<String, dynamic> testimony) async {
    try {
      final storageService = StorageService();
      final token = await storageService.getAccessToken();

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to praise testimonies'),
            ),
          );
        }
        return;
      }

      final testimonyId = testimony['id'];
      final isPraised = testimony['user_has_praised'] == true;

      // Optimistically update UI
      setState(() {
        testimony['user_has_praised'] = !isPraised;
        testimony['praise_count'] =
            (testimony['praise_count'] ?? 0) + (isPraised ? -1 : 1);
      });

      final response = await http.post(
        Uri.parse('${ApiConfig.testimonies}$testimonyId/praise/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        // Revert on failure
        if (mounted) {
          setState(() {
            testimony['user_has_praised'] = isPraised;
            testimony['praise_count'] =
                (testimony['praise_count'] ?? 0) + (isPraised ? 1 : -1);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update praise')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  // Handle Share action
  void _handleShare(Map<String, dynamic> testimony) {
    final title = testimony['title'] ?? 'Testimony';
    final content = testimony['content'] ?? '';
    final userName = testimony['is_anonymous'] == true
        ? 'Anonymous'
        : (testimony['user_name'] ?? 'A member');

    final shareText =
        '''
📖 Testimony: $title

By: $userName

$content

Shared from Efatha Church App
''';

    Share.share(shareText, subject: 'Testimony: $title');
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'healing':
        return Icons.healing;
      case 'financial':
        return Icons.attach_money;
      case 'family':
        return Icons.family_restroom;
      case 'salvation':
        return Icons.church;
      case 'deliverance':
        return Icons.shield;
      case 'career':
        return Icons.work;
      case 'answered_prayer':
        return Icons.check_circle;
      default:
        return Icons.favorite;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'healing':
        return 'Healing';
      case 'financial':
        return 'Financial';
      case 'family':
        return 'Family';
      case 'salvation':
        return 'Salvation';
      case 'deliverance':
        return 'Deliverance';
      case 'career':
        return 'Career';
      case 'answered_prayer':
        return 'Answered Prayer';
      default:
        return 'Testimony';
    }
  }

  List<Color> _getCategoryColors(String category) {
    switch (category) {
      case 'healing':
        return [const Color(0xFF4CAF50), const Color(0xFF45a049)];
      case 'financial':
        return [const Color(0xFF2196F3), const Color(0xFF1976D2)];
      case 'family':
        return [const Color(0xFFE91E63), const Color(0xFFC2185B)];
      case 'salvation':
        return [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)];
      case 'deliverance':
        return [const Color(0xFFFF9800), const Color(0xFFF57C00)];
      case 'career':
        return [const Color(0xFF607D8B), const Color(0xFF455A64)];
      case 'answered_prayer':
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      default:
        return [Colors.pink[400]!, Colors.pink[600]!];
    }
  }
}
