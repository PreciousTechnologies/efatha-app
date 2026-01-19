import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import 'upload_sermon_screen.dart';
import 'sermon_detail_screen.dart';

/// Sermons Screen - Displays church sermons and messages
/// Following design reference: 28pt title, view toggle, filters, pull-to-refresh
class SermonsScreen extends StatefulWidget {
  const SermonsScreen({super.key});

  @override
  State<SermonsScreen> createState() => _SermonsScreenState();
}

enum ViewMode { list, grid }

enum SortOption { newest, oldest, popular, title }

class _SermonsScreenState extends State<SermonsScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  ViewMode _viewMode = ViewMode.list;
  String _selectedCategory = 'all';
  String? _selectedPastor;
  String? _selectedTopic;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = true;
  bool _isEditor = false;
  List<Map<String, dynamic>> _sermons = [];
  Set<String> _availablePastors = {};
  Set<String> _availableTopics = {};

  final List<String> _categories = [
    'all',
    'Sunday Service',
    'Midweek Service',
    'Youth Service',
    'Special Event',
    'Conference',
    'Revival',
    'Worship Night',
    'Bible Study',
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadSermons();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final role = await _storage.getUserRole();
    setState(() {
      _isEditor = role?.toLowerCase() == 'editor';
    });
    print('👤 User role: $role, isEditor: $_isEditor');
  }

  Future<void> _loadSermons() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getSermons(
        category: _selectedCategory != 'all' ? _selectedCategory : null,
        pastor: _selectedPastor,
        topics: _selectedTopic,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          _sermons = List<Map<String, dynamic>>.from(data['results'] ?? []);

          // Extract unique pastors and topics for filters
          _availablePastors.clear();
          _availableTopics.clear();

          for (var sermon in _sermons) {
            if (sermon['pastor'] != null) {
              _availablePastors.add(sermon['pastor'].toString());
            }
            if (sermon['topics'] != null) {
              final topics = sermon['topics'].toString().split(',');
              _availableTopics.addAll(topics.map((t) => t.trim()));
            }
          }
        });
        print('✅ Loaded ${_sermons.length} sermons');
      } else {
        print('❌ Failed to load sermons: ${response['message']}');
        // Show error but don't crash - keep empty list
      }
    } catch (e) {
      print('❌ Exception loading sermons: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    // Cancel previous debounce timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Start new debounce timer
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadSermons();
    });
  }

  Future<void> _handleRefresh() async {
    await _loadSermons();
  }

  Future<void> _deleteSermon(int sermonId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sermon?'),
        content: const Text(
          'This sermon will be permanently deleted. This action cannot be undone.',
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

    // Show loading
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            const Text('Deleting sermon...'),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      final response = await _apiService.deleteSermon(sermonId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Sermon deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadSermons(); // Reload the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${response['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _navigateToUpload({Map<String, dynamic>? sermonData}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadSermonScreen(sermonData: sermonData),
      ),
    );

    if (result == true) {
      _loadSermons(); // Reload sermons after upload/edit
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBackgroundSoft,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primaryPurpleDeep,
        child: CustomScrollView(
          slivers: [
            // Custom App Bar Header
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sermons',
                                style: AppTextStyles.headlineLarge.copyWith(
                                  color: AppColors.neutralTextPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_sermons.length} inspiring messages',
                                style: AppTextStyles.bodyRegular.copyWith(
                                  color: AppColors.neutralTextMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            // Editor Upload Button
                            if (_isEditor) ...[
                              Container(
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
                                      color: AppColors.primaryPurpleVibrant
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _navigateToUpload(),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      child: Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            _buildViewToggle(),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Filters Section
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.neutralBackgroundLightest,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildFilterChips(),
                  ],
                ),
              ),
            ),

            // Sermon List/Grid
            if (_isLoading)
              const SliverFillRemaining(child: Center(child: _LoadingState()))
            else if (_sermons.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note_outlined,
                        size: 64,
                        color: AppColors.neutralTextMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No sermons found',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.neutralTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: AppTextStyles.bodyRegular.copyWith(
                          color: AppColors.neutralTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _viewMode == ViewMode.list
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _SermonCard(
                          sermonData: _sermons[index],
                          isGridView: false,
                          isEditor: _isEditor,
                          onEdit: () =>
                              _navigateToUpload(sermonData: _sermons[index]),
                          onDelete: () => _deleteSermon(_sermons[index]['id']),
                        ),
                        childCount: _sermons.length,
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio:
                                  0.70, // Fixed overflow - adjusted from 0.75
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _SermonCard(
                            sermonData: _sermons[index],
                            isGridView: true,
                            isEditor: _isEditor,
                            onEdit: () =>
                                _navigateToUpload(sermonData: _sermons[index]),
                            onDelete: () =>
                                _deleteSermon(_sermons[index]['id']),
                          ),
                          childCount: _sermons.length,
                        ),
                      ),
                    ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.neutralBackgroundSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleButton(
            icon: Icons.view_list_rounded,
            isSelected: _viewMode == ViewMode.list,
            onTap: () => setState(() => _viewMode = ViewMode.list),
          ),
          _ViewToggleButton(
            icon: Icons.grid_view_rounded,
            isSelected: _viewMode == ViewMode.grid,
            onTap: () => setState(() => _viewMode = ViewMode.grid),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurpleVibrant.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search sermons, topics, pastors...',
          hintStyle: AppTextStyles.bodyRegular.copyWith(
            color: AppColors.neutralTextPlaceholder,
            fontSize: 14,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.primaryPurpleDeep,
              size: 24,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.neutralTextMuted,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Filter
        Row(
          children: [
            Icon(
              Icons.category_outlined,
              size: 16,
              color: AppColors.neutralTextMuted,
            ),
            const SizedBox(width: 6),
            Text(
              'Category',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.neutralTextMuted,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return _FilterChip(
                label: category == 'all' ? 'ALL' : category.toUpperCase(),
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedCategory = category);
                  _loadSermons();
                },
              );
            },
          ),
        ),

        // Pastor Filter (if available)
        if (_availablePastors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.neutralTextMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Pastor',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.neutralTextMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              if (_selectedPastor != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedPastor = null);
                    _loadSermons();
                  },
                  child: Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: AppColors.primaryPurpleDeep,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _availablePastors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final pastor = _availablePastors.elementAt(index);
                final isSelected = _selectedPastor == pastor;
                return _FilterChip(
                  label: pastor.toUpperCase(),
                  isSelected: isSelected,
                  onTap: () {
                    setState(
                      () => _selectedPastor = isSelected ? null : pastor,
                    );
                    _loadSermons();
                  },
                );
              },
            ),
          ),
        ],

        // Topics Filter (if available)
        if (_availableTopics.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.label_outline,
                size: 16,
                color: AppColors.neutralTextMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Topics',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.neutralTextMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              if (_selectedTopic != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedTopic = null);
                    _loadSermons();
                  },
                  child: Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: AppColors.primaryPurpleDeep,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _availableTopics.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final topic = _availableTopics.elementAt(index);
                final isSelected = _selectedTopic == topic;
                return _FilterChip(
                  label: topic.toUpperCase(),
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedTopic = isSelected ? null : topic);
                    _loadSermons();
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SermonCard extends StatelessWidget {
  final Map<String, dynamic> sermonData;
  final bool isGridView;
  final bool isEditor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SermonCard({
    required this.sermonData,
    this.isGridView = false,
    this.isEditor = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return _buildGridCard(context);
    }
    return _buildListCard(context);
  }

  Widget _buildListCard(BuildContext context) {
    final title = sermonData['title'] ?? 'Untitled Sermon';
    final pastor = sermonData['pastor'] ?? 'Unknown Pastor';
    final category = sermonData['category'] ?? 'SERMON';
    final duration = sermonData['duration'] ?? '00:00';
    final views = sermonData['views'] ?? 0;
    final createdAt = sermonData['created_at'] ?? '';
    final thumbnailUrl = sermonData['thumbnail_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurpleVibrant.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SermonDetailScreen(sermon: sermonData),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Thumbnail with gradient overlay
              Stack(
                children: [
                  // Thumbnail image or gradient fallback
                  thumbnailUrl != null
                      ? Image.network(
                          thumbnailUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackThumbnail();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildFallbackThumbnail();
                          },
                        )
                      : _buildFallbackThumbnail(),
                  // Gradient overlay for better readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Play button with better design
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 40,
                          color: AppColors.primaryPurpleDeep,
                        ),
                      ),
                    ),
                  ),
                  // Duration badge with better design
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            duration,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurpleVibrant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Edit and Delete buttons for editors
                  if (isEditor && (onEdit != null || onDelete != null))
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button
                          if (onEdit != null)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onEdit,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                    color: AppColors.primaryPurpleDeep,
                                  ),
                                ),
                              ),
                            ),
                          if (onEdit != null && onDelete != null)
                            const SizedBox(width: 8),
                          // Delete button
                          if (onDelete != null)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onDelete,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.delete_rounded,
                                    size: 18,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),

              // Content section with better spacing
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with better typography
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutralTextPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Pastor info with avatar
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurpleVibrant,
                                AppColors.primaryPurpleDeep,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              pastor.split(' ').map((n) => n[0]).take(2).join(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pastor,
                                style: AppTextStyles.bodyMediumWeight.copyWith(
                                  fontSize: 14,
                                  color: AppColors.neutralTextPrimary,
                                ),
                              ),
                              Text(
                                createdAt.isNotEmpty
                                    ? _formatDate(createdAt)
                                    : 'Recent',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.neutralTextMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Stats row with better icons
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutralBackgroundSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.primaryPurpleDeep,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$views views',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutralTextPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurpleVibrant.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.download_rounded,
                              size: 18,
                              color: AppColors.primaryPurpleDeep,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurpleVibrant.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.share_rounded,
                              size: 18,
                              color: AppColors.primaryPurpleDeep,
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
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';

      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildGridCard(BuildContext context) {
    final title = sermonData['title'] ?? 'Untitled Sermon';
    final pastor = sermonData['pastor'] ?? 'Unknown Pastor';
    final duration = sermonData['duration'] ?? '00:00';
    final views = sermonData['views'] ?? 0;
    final thumbnailUrl = sermonData['thumbnail_url'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurpleVibrant.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SermonDetailScreen(sermon: sermonData),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced thumbnail
              Stack(
                children: [
                  // Thumbnail image or gradient fallback
                  thumbnailUrl != null
                      ? Image.network(
                          thumbnailUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 130,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryPurpleDeep,
                                    AppColors.primaryPurpleVibrant,
                                    AppColors.primaryPurpleLight,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.music_note,
                                  size: 36,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 130,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryPurpleDeep,
                                AppColors.primaryPurpleVibrant,
                                AppColors.primaryPurpleLight,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.music_note,
                              size: 36,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 28,
                          color: AppColors.primaryPurpleDeep,
                        ),
                      ),
                    ),
                  ),
                  // Duration badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        duration,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  // Edit and Delete buttons for editors
                  if (isEditor && (onEdit != null || onDelete != null))
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button
                          if (onEdit != null)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onEdit,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: AppColors.primaryPurpleDeep,
                                  ),
                                ),
                              ),
                            ),
                          if (onEdit != null && onDelete != null)
                            const SizedBox(width: 4),
                          // Delete button
                          if (onDelete != null)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onDelete,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.delete_rounded,
                                    size: 14,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(10), // Reduced from 12
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: AppTextStyles.bodyMediumWeight.copyWith(
                        fontSize: 13, // Reduced from 14
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutralTextPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // Reduced from 6
                    // Pastor name
                    Text(
                      pastor,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10, // Reduced from 11
                        color: AppColors.neutralTextMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6), // Reduced from 8
                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 13, // Reduced from 14
                          color: AppColors.primaryPurpleDeep,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          views > 999
                              ? '${(views / 1000).toStringAsFixed(1)}k'
                              : '$views',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10, // Reduced from 11
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutralTextPrimary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.download_rounded,
                          size: 14, // Reduced from 16
                          color: AppColors.primaryPurpleDeep,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fallback thumbnail widget
  Widget _buildFallbackThumbnail() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurpleDeep,
            AppColors.primaryPurpleVibrant,
            AppColors.primaryPurpleLight,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 48,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurpleVibrant.withValues(
                      alpha: 0.15,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 22,
          color: isSelected
              ? AppColors.primaryPurpleDeep
              : AppColors.neutralTextMuted,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primaryPurpleDeep,
                    AppColors.primaryPurpleVibrant,
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.neutralBackgroundMuted,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurpleVibrant.withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyRegular.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.neutralTextMuted,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.music_note, size: 48, color: AppColors.primaryPurpleDeep),
        const SizedBox(height: 16),
        Text(
          'Loading Sermons',
          style: AppTextStyles.titleMedium.copyWith(
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while we fetch the latest messages',
          style: AppTextStyles.bodyRegular.copyWith(
            color: AppColors.neutralTextMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
