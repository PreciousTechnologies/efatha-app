import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Tenzi za Rohoni - Swahili Hymnal Screen
class TenziScreen extends StatefulWidget {
  const TenziScreen({super.key});

  @override
  State<TenziScreen> createState() => _TenziScreenState();
}

class _TenziScreenState extends State<TenziScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allHymns = [];
  List<Map<String, dynamic>> _filteredHymns = [];
  Set<int> _favorites = {};
  List<int> _recentHymns = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Praise & Worship',
    'Prayer',
    'Thanksgiving',
    'Salvation',
    'Holy Spirit',
    'Faith',
    'Love',
    'Christmas',
    'Easter',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _loadFavorites();
      await _loadRecent();
      await _loadHymns();
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHymns() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/tenzi.json');
      final data = json.decode(jsonString);

      if (mounted) {
        setState(() {
          _allHymns = List<Map<String, dynamic>>.from(data['hymns']);
          _filteredHymns = _allHymns;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading hymns: $e');
      // Use sample data for demonstration
      if (mounted) {
        _loadSampleHymns();
      }
    }
  }

  void _loadSampleHymns() {
    if (mounted) {
      setState(() {
        _allHymns = [
          {
            'number': 1,
            'title': 'Mungu ni Mwema',
            'category': 'Praise & Worship',
            'firstLine': 'Mungu ni mwema, ni mwema kweli...',
          },
          {
            'number': 2,
            'title': 'Yesu Nakupenda',
            'category': 'Love',
            'firstLine': 'Yesu nakupenda, wewe ni rafiki yangu...',
          },
          // Add more sample hymns
        ];
        _filteredHymns = _allHymns;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favs = prefs.getStringList('favorite_hymns') ?? [];
      if (mounted) {
        setState(() {
          _favorites = favs
              .map((e) => int.tryParse(e) ?? 0)
              .where((e) => e > 0)
              .toSet();
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'favorite_hymns',
        _favorites.map((e) => e.toString()).toList(),
      );
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  Future<void> _loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = prefs.getStringList('recent_hymns') ?? [];
      if (mounted) {
        setState(() {
          _recentHymns = recent
              .map((e) => int.tryParse(e) ?? 0)
              .where((e) => e > 0)
              .toList();
        });
      }
    } catch (e) {
      print('Error loading recent: $e');
    }
  }

  Future<void> _saveRecent(int hymnNumber) async {
    try {
      _recentHymns.remove(hymnNumber);
      _recentHymns.insert(0, hymnNumber);
      if (_recentHymns.length > 20) {
        _recentHymns = _recentHymns.sublist(0, 20);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'recent_hymns',
        _recentHymns.map((e) => e.toString()).toList(),
      );
    } catch (e) {
      print('Error saving recent: $e');
    }
  }

  void _toggleFavorite(int hymnNumber) {
    if (mounted) {
      setState(() {
        if (_favorites.contains(hymnNumber)) {
          _favorites.remove(hymnNumber);
        } else {
          _favorites.add(hymnNumber);
        }
      });
      _saveFavorites();
    }
  }

  void _searchHymns(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredHymns = _allHymns;
        } else {
          _filteredHymns = _allHymns.where((hymn) {
            final number = hymn['number'].toString();
            final title = hymn['title'].toString().toLowerCase();
            final firstLine = hymn['firstLine']?.toString().toLowerCase() ?? '';
            final searchLower = query.toLowerCase();

            return number.contains(query) ||
                title.contains(searchLower) ||
                firstLine.contains(searchLower);
          }).toList();
        }
      });
    }
  }

  void _filterByCategory(String category) {
    if (mounted) {
      setState(() {
        _selectedCategory = category;
        if (category == 'All') {
          _filteredHymns = _allHymns;
        } else {
          _filteredHymns = _allHymns
              .where((hymn) => hymn['category'] == category)
              .toList();
        }
      });
    }
  }

  void _openHymn(Map<String, dynamic> hymn) {
    final hymnNumber = hymn['number'] as int;
    _saveRecent(hymnNumber);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HymnDetailScreen(
          hymn: hymn,
          isFavorite: _favorites.contains(hymnNumber),
          onToggleFavorite: () => _toggleFavorite(hymnNumber),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tenzi za Rohoni'),
        backgroundColor: AppColors.primaryPurpleDeep,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              // Show info
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPurpleDeep,
              ),
            )
          : Column(
              children: [
                _buildSearchBar(),
                _buildCategoryChips(),
                _buildTabBar(),
                Expanded(child: _buildTabContent()),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchHymns,
        decoration: InputDecoration(
          hintText: 'Search by number, title, or lyrics...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primaryPurpleDeep,
            size: 24,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _searchHymns('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () => _filterByCategory(category),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
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
                color: isSelected ? null : Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryPurpleDeep,
              AppColors.primaryPurpleVibrant,
            ],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(
            icon: Icon(Icons.library_music_rounded, size: 20),
            text: 'All Hymns',
          ),
          Tab(icon: Icon(Icons.favorite_rounded, size: 20), text: 'Favorites'),
          Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'Recent'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurpleDeep),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildHymnList(_filteredHymns),
        _buildHymnList(
          _allHymns.where((h) => _favorites.contains(h['number'])).toList(),
        ),
        _buildHymnList(
          _recentHymns
              .map(
                (num) => _allHymns.firstWhere(
                  (h) => h['number'] == num,
                  orElse: () => {},
                ),
              )
              .where((h) => h.isNotEmpty)
              .toList(),
        ),
      ],
    );
  }

  Widget _buildHymnList(List<Map<String, dynamic>> hymns) {
    if (hymns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No hymns found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: hymns.length,
      itemBuilder: (context, index) {
        final hymn = hymns[index];
        return _buildHymnCard(hymn);
      },
    );
  }

  Widget _buildHymnCard(Map<String, dynamic> hymn) {
    final hymnNumber = hymn['number'] as int;
    final isFavorite = _favorites.contains(hymnNumber);

    return Container(
      key: ValueKey(hymnNumber),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openHymn(hymn),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurpleDeep.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$hymnNumber',
                      style: TextStyle(
                        color: AppColors.primaryPurpleDeep,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                        hymn['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hymn['firstLine'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey[400],
                    size: 24,
                  ),
                  onPressed: () => _toggleFavorite(hymnNumber),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Hymn Detail Screen
class HymnDetailScreen extends StatelessWidget {
  final Map<String, dynamic> hymn;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const HymnDetailScreen({
    super.key,
    required this.hymn,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(hymn['title'] ?? ''),
              background: Container(
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
                child: Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: onToggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {
                  // Share hymn
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hymn['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurpleDeep.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hymn['category'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryPurpleDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    hymn['lyrics'] ?? 'No lyrics available.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
