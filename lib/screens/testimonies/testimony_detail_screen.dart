import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/image_viewer.dart';
import '../../widgets/testimony_video_player.dart';
import 'package:share_plus/share_plus.dart';

/// Testimony Detail Screen - Enhanced UI/UX for viewing full testimony with media
class TestimonyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> testimony;

  const TestimonyDetailScreen({super.key, required this.testimony});

  @override
  State<TestimonyDetailScreen> createState() => _TestimonyDetailScreenState();
}

class _TestimonyDetailScreenState extends State<TestimonyDetailScreen> {
  late Map<String, dynamic> testimony;

  @override
  void initState() {
    super.initState();
    testimony = Map<String, dynamic>.from(widget.testimony);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = testimony['photo_url'] != null;
    final hasVideo = testimony['video_url'] != null;
    final category = testimony['category'] ?? 'other';
    final prayerTitle = testimony['prayer_request_title'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Simple App Bar (no expanded header)
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            title: const Text(
              'Testimony',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share testimony',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share functionality coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Player First (YouTube-style - full width)
                if (hasVideo) ...[
                  Container(
                    width: double.infinity,
                    height: 240, // YouTube-like height
                    color: Colors.black,
                    child: TestimonyVideoPlayer(
                      videoUrl: testimony['video_url'],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Main Content Card
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Featured Row
                      Row(
                        children: [
                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getCategoryColors(category),
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: _getCategoryColors(
                                    category,
                                  )[0].withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(category),
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getCategoryLabel(category),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Featured Badge
                          if (testimony['is_featured'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFFD700,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Featured',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Title
                      Text(
                        testimony['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          letterSpacing: -0.5,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Author Info
                      Row(
                        children: [
                          // Profile Picture
                          testimony['user_profile_picture'] != null
                              ? Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundImage: NetworkImage(
                                      testimony['user_profile_picture'],
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue[400]!,
                                        Colors.blue[600]!,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  testimony['is_anonymous'] == true
                                      ? 'Anonymous'
                                      : testimony['user_name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 13,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(testimony['created_at']),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey[200]!,
                              Colors.grey[100]!,
                              Colors.grey[200]!,
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Content
                      Text(
                        testimony['content'] ?? '',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.grey[800],
                          height: 1.7,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Prayer Link (if linked)
                if (prayerTitle != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurpleLight.withValues(alpha: 0.1),
                          AppColors.primaryPurpleVibrant.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryPurpleLight.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurpleDeep,
                                AppColors.primaryPurpleVibrant,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPurpleDeep.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.link,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LINKED PRAYER REQUEST',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                prayerTitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.primaryPurpleDeep,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.primaryPurpleDeep,
                        ),
                      ],
                    ),
                  ),
                if (prayerTitle != null) const SizedBox(height: 16),

                // Photo Section (if available and no video)
                if (hasPhoto && !hasVideo)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageViewer(
                                imageUrls: [testimony['photo_url']],
                                initialIndex: 0,
                              ),
                            ),
                          );
                        },
                        child: Image.network(
                          testimony['photo_url'],
                          width: double.infinity,
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
                        ),
                      ),
                    ),
                  ),
                if (hasPhoto && !hasVideo) const SizedBox(height: 16),

                // Action Buttons
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: testimony['user_has_praised'] == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          label: testimony['user_has_praised'] == true
                              ? 'Praised'
                              : 'Praise God',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                          ),
                          onTap: _handlePraise,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.share,
                          label: 'Share',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                          ),
                          onTap: _handleShare,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: gradient.colors[0].withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(date);
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

  // Handle Praise action
  Future<void> _handlePraise() async {
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPraised ? 'Praise removed' : 'Praised! Glory to God! 🙏',
              ),
              duration: const Duration(seconds: 2),
            ),
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
  void _handleShare() {
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
}
