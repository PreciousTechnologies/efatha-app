import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';
import '../../widgets/image_viewer.dart';
import 'package:intl/intl.dart';

/// Prayer Detail Screen - Shows full prayer details with images, comments, and pray button
class PrayerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> prayer;

  const PrayerDetailScreen({super.key, required this.prayer});

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  final _commentController = TextEditingController();
  final StorageService _storage = StorageService();

  bool _isPraying = false;
  bool _isSubmittingComment = false;
  late Map<String, dynamic> _prayerData;
  List<dynamic> _comments = [];

  @override
  void initState() {
    super.initState();
    _prayerData = Map.from(widget.prayer);
    _isPraying = _prayerData['is_praying'] ?? false;
    _loadUserData();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    await _storage.getUserId();
  }

  Future<void> _loadComments() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/church/prayer-comments/?prayer_request=${_prayerData['id']}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _comments = data is List ? data : (data['results'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
    }
  }

  Future<void> _togglePray() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        _showError('Please log in again');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.prayerRequests}${_prayerData['id']}/pray/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newIsPraying = data['is_praying'] ?? !_isPraying;

        setState(() {
          _isPraying = newIsPraying;
          _prayerData['prayer_count'] =
              (_prayerData['prayer_count'] ?? 0) + (newIsPraying ? 1 : -1);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newIsPraying
                    ? "You're praying for this request"
                    : 'Prayer removed',
              ),
              backgroundColor: newIsPraying
                  ? AppColors.primaryPurpleDeep
                  : Colors.grey[700],
            ),
          );
        }
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        _showError('Please log in again');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/church/prayer-comments/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'prayer_request': _prayerData['id'],
          'content': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _commentController.clear();
        await _loadComments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError('Failed to add comment');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() => _isSubmittingComment = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Color _getPriorityColor() {
    switch (_prayerData['priority']) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Recently';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return '${diff.inMinutes} minutes ago';
        }
        return '${diff.inHours} hours ago';
      }
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';

      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();
    final images = _prayerData['images'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Prayer Request',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _prayerData['user_profile_picture'] == null
                              ? LinearGradient(
                                  colors: [
                                    AppColors.primaryPurpleDeep,
                                    AppColors.primaryPurpleVibrant,
                                  ],
                                )
                              : null,
                          image: _prayerData['user_profile_picture'] != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    _prayerData['user_profile_picture'],
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _prayerData['user_profile_picture'] == null
                            ? Center(
                                child: Text(
                                  (_prayerData['user_name'] ?? 'A')
                                      .split(' ')
                                      .take(2)
                                      .map((n) => n[0])
                                      .join()
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
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
                              _prayerData['user_name'] ?? 'Anonymous',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(_prayerData['created_at']),
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              priorityColor,
                              priorityColor.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _prayerData['priority'] ?? 'NORMAL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    _prayerData['title'] ?? 'Prayer Request',
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 12),

                  // Category
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (_prayerData['category'] ?? 'other')
                            .toString()
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _prayerData['description'] ?? '',
                style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
              ),
            ),

            // Images Section
            if (images.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Images', style: AppTextStyles.titleMedium),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final image = images[index];
                    return GestureDetector(
                      onTap: () {
                        // Open full-screen image viewer
                        final imageUrls = images
                            .map((img) => img['image_url'] as String? ?? '')
                            .where((url) => url.isNotEmpty)
                            .toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewer(
                              imageUrls: imageUrls,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            image['image_url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Prayer Stats
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.favorite,
                    label: 'Praying',
                    count: _prayerData['prayer_count'] ?? 0,
                    color: Colors.red,
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _StatItem(
                    icon: Icons.comment,
                    label: 'Comments',
                    count: _comments.length,
                    color: AppColors.primaryPurpleDeep,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pray Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: _togglePray,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPraying
                      ? AppColors.primaryPurpleDeep
                      : Colors.white,
                  foregroundColor: _isPraying ? Colors.white : Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _isPraying
                          ? Colors.transparent
                          : Colors.grey[300]!,
                    ),
                  ),
                  elevation: _isPraying ? 4 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isPraying ? Icons.favorite : Icons.favorite_border,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isPraying ? "I'm Praying" : 'Pray for This Request',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Comments Section
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Text(
                      'Comments (${_comments.length})',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),

                  // Comment Input
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isSubmittingComment
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                onPressed: _submitComment,
                                icon: Icon(
                                  Icons.send,
                                  color: AppColors.primaryPurpleDeep,
                                ),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Comments List
                  _comments.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No comments yet',
                                  style: AppTextStyles.bodyRegular.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Be the first to comment',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return _CommentCard(comment: comment);
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  final Map<String, dynamic> comment;

  const _CommentCard({required this.comment});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Just now';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return DateFormat('MMM dd').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: comment['user_profile_picture'] == null
                      ? LinearGradient(
                          colors: [
                            AppColors.primaryPurpleDeep,
                            AppColors.primaryPurpleVibrant,
                          ],
                        )
                      : null,
                  image: comment['user_profile_picture'] != null
                      ? DecorationImage(
                          image: NetworkImage(comment['user_profile_picture']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: comment['user_profile_picture'] == null
                    ? Center(
                        child: Text(
                          comment['user_initials'] ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['user_name'] ?? 'User',
                      style: AppTextStyles.bodyMediumWeight.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatDate(comment['created_at']),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment['content'] ?? '',
            style: AppTextStyles.bodyRegular.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
