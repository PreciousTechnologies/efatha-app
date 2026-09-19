import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';
import 'submit_prayer_screen.dart';
import 'prayer_detail_screen.dart';
import '../testimonies/submit_testimony_screen.dart';
import 'package:intl/intl.dart';

/// Prayers Screen - Prayer requests and testimonies
class PrayersScreen extends StatefulWidget {
  final bool showFAB;

  const PrayersScreen({super.key, this.showFAB = false});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  final StorageService _storage = StorageService();

  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Urgent',
    'High Priority',
    'My Prayers',
  ];

  List<Map<String, dynamic>> _prayers = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPrayers();
  }

  Future<void> _loadUserData() async {
    final userId = await _storage.getUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<void> _loadPrayers() async {
    setState(() => _isLoading = true);

    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        _showError('Please log in again');
        setState(() => _isLoading = false);
        return;
      }

      // Build query parameters based on filter
      String endpoint = ApiConfig.prayerRequests;
      if (_selectedFilter == 'My Prayers') {
        endpoint += '?my_prayers=true';
      } else if (_selectedFilter == 'Urgent') {
        endpoint += '?priority=URGENT';
      } else if (_selectedFilter == 'High Priority') {
        endpoint += '?priority=HIGH';
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> prayersList;

        if (data is List) {
          prayersList = data;
        } else if (data is Map && data.containsKey('results')) {
          prayersList = data['results'];
        } else {
          prayersList = [];
        }

        setState(() {
          _prayers = prayersList.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError('Failed to load prayers');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: ${e.toString()}');
    }
  }

  Future<void> _deletePrayer(int prayerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prayer Request?'),
        content: const Text(
          'This prayer request will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        _showError('Please log in again');
        return;
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.prayerRequests}$prayerId/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204) {
        _showSuccess('Prayer request deleted successfully');
        _loadPrayers(); // Reload list
      } else {
        _showError('Failed to delete prayer request');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }

  Future<void> _togglePray(int index) async {
    final prayer = _prayers[index];

    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        _showError('Please log in again');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.prayerRequests}${prayer['id']}/pray/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newIsPraying = data['is_praying'] ?? !prayer['is_praying'];

        setState(() {
          _prayers[index]['is_praying'] = newIsPraying;
          _prayers[index]['prayer_count'] =
              (_prayers[index]['prayer_count'] ?? 0) + (newIsPraying ? 1 : -1);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newIsPraying
                    ? "You're praying for this request"
                    : 'Prayer removed',
              ),
              duration: const Duration(seconds: 2),
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadPrayers,
        color: AppColors.primaryPurpleDeep,
        child: CustomScrollView(
          slivers: [
            // Modern Header
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
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
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurpleLight.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubmitPrayerScreen(),
                        ),
                      );
                      if (result is Map && result['addTestimony'] == true) {
                        // User wants to add testimony for the prayer they just submitted
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubmitTestimonyScreen(
                              prayerRequestId: result['prayerId'],
                              prayerRequestTitle: result['prayerTitle'],
                            ),
                          ),
                        );
                        _loadPrayers();
                      } else if (result == true) {
                        _loadPrayers();
                      }
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Prayer Wall',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_prayers.length} active prayer requests',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: Container(
                height: 60,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = filter == _selectedFilter;
                    return FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        _loadPrayers();
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.primaryPurpleLight.withValues(
                        alpha: 0.2,
                      ),
                      checkmarkColor: AppColors.primaryPurpleDeep,
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
                        width: isSelected ? 2 : 1,
                      ),
                      elevation: isSelected ? 2 : 0,
                      shadowColor: AppColors.primaryPurpleLight.withValues(
                        alpha: 0.3,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Prayer Cards
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_prayers.isEmpty)
              SliverFillRemaining(
                child: Center(
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
                        _selectedFilter == 'My Prayers'
                            ? 'No prayer requests yet'
                            : 'No prayers found',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFilter == 'My Prayers'
                            ? 'Tap + to submit your first prayer request'
                            : 'Try changing the filter',
                        style: AppTextStyles.bodyRegular.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final prayer = _prayers[index];
                    final isMyPrayer =
                        _currentUserId != null &&
                        prayer['user'] == _currentUserId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PrayerCard(
                        prayer: prayer,
                        isMyPrayer: isMyPrayer,
                        onPrayToggle: () => _togglePray(index),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PrayerDetailScreen(prayer: prayer),
                            ),
                          );
                          if (result == true) {
                            _loadPrayers();
                          }
                        },
                        onEdit: isMyPrayer
                            ? () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SubmitPrayerScreen(prayerData: prayer),
                                  ),
                                );
                                if (result == true) {
                                  _loadPrayers();
                                }
                              }
                            : null,
                        onDelete: isMyPrayer
                            ? () => _deletePrayer(prayer['id'])
                            : null,
                      ),
                    );
                  }, childCount: _prayers.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final Map<String, dynamic> prayer;
  final bool isMyPrayer;
  final VoidCallback onPrayToggle;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PrayerCard({
    required this.prayer,
    required this.isMyPrayer,
    required this.onPrayToggle,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color _getPriorityColor() {
    switch (prayer['priority']) {
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

      return DateFormat('MMM dd').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();
    final isPraying = prayer['is_praying'] ?? false;
    final prayerCount = prayer['prayer_count'] ?? 0;
    final commentCount = prayer['comment_count'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with profile picture or gradient
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: prayer['user_profile_picture'] == null
                        ? LinearGradient(
                            colors: [
                              AppColors.primaryPurpleDeep,
                              AppColors.primaryPurpleVibrant,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    image: prayer['user_profile_picture'] != null
                        ? DecorationImage(
                            image: NetworkImage(prayer['user_profile_picture']),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurpleLight.withValues(alpha: 0.3),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: prayer['user_profile_picture'] == null
                      ? Center(
                          child: Text(
                            (prayer['user_name'] ?? 'A')
                                .split(' ')
                                .take(2)
                                .map((n) => n[0])
                                .join()
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                        prayer['user_name'] ?? 'Anonymous',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(prayer['created_at']),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [priorityColor, priorityColor.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: priorityColor.withValues(alpha: 0.3),
                        spreadRadius: 0,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    prayer['priority'] ?? 'NORMAL',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Prayer Text
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayer['title'] ?? 'Prayer Request',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prayer['description'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action Section
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Praying Button
                Expanded(
                  child: InkWell(
                    onTap: onPrayToggle,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isPraying
                            ? LinearGradient(
                                colors: [
                                  AppColors.primaryPurpleDeep,
                                  AppColors.primaryPurpleVibrant,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isPraying ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPraying
                              ? Colors.transparent
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                        boxShadow: isPraying
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryPurpleLight
                                      .withValues(alpha: 0.3),
                                  spreadRadius: 0,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPraying ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isPraying ? Colors.white : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPraying ? "I'm Praying" : 'Pray',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isPraying ? Colors.white : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($prayerCount)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isPraying
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Comment Button
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$commentCount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Edit/Delete Buttons (only for user's own prayers)
                if (isMyPrayer) ...[
                  const SizedBox(width: 8),
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit,
                        color: AppColors.primaryPurpleDeep,
                        size: 20,
                      ),
                      tooltip: 'Edit',
                    ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'Delete',
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
