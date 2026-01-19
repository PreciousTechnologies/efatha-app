import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced Bible Screen - KJV Strongs Concordance & Biblia Takatifu (Swahili)
/// Features: Favorites, Search, Verse Highlighting, Enhanced UI/UX
class EnhancedBibleScreen extends StatefulWidget {
  const EnhancedBibleScreen({super.key});

  @override
  State<EnhancedBibleScreen> createState() => _EnhancedBibleScreenState();
}

class _EnhancedBibleScreenState extends State<EnhancedBibleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _selectedBook = 'Genesis';
  int _selectedChapter = 1;
  List<dynamic> _verses = [];
  bool _isLoading = false;
  String _error = '';
  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  // Favorites and Highlighting
  Set<String> _favoriteVerses = {}; // Format: "Book_Chapter_Verse"
  Map<String, String> _verseColors =
      {}; // Format: "Book_Chapter_Verse" -> color
  double _fontSize = 16.0;
  bool _readingMode = false;

  // Available highlight colors
  final Map<String, Color> _highlightColors = {
    'yellow': Colors.yellow.shade200,
    'green': Colors.green.shade200,
    'blue': Colors.blue.shade200,
    'pink': Colors.pink.shade200,
    'orange': Colors.orange.shade200,
    'purple': Colors.purple.shade200,
  };

  // Bible API Configuration for KJV English
  static const String _kjvApiKey = '84928751f9913ac558a1e24b4731a29e';
  static const String _kjvBaseUrl = 'https://api.scripture.api.bible/v1';
  static const String _kjvBibleId = 'de4e12af7f28f599-02';

  // Book ID mapping
  final Map<String, Map<String, String>> _bookIdMapping = {
    'Genesis': {'kjv': 'GEN', 'pasaka': '1'},
    'Exodus': {'kjv': 'EXO', 'pasaka': '2'},
    'Leviticus': {'kjv': 'LEV', 'pasaka': '3'},
    'Numbers': {'kjv': 'NUM', 'pasaka': '4'},
    'Deuteronomy': {'kjv': 'DEU', 'pasaka': '5'},
    'Joshua': {'kjv': 'JOS', 'pasaka': '6'},
    'Judges': {'kjv': 'JDG', 'pasaka': '7'},
    'Ruth': {'kjv': 'RUT', 'pasaka': '8'},
    '1 Samuel': {'kjv': '1SA', 'pasaka': '9'},
    '2 Samuel': {'kjv': '2SA', 'pasaka': '10'},
    '1 Kings': {'kjv': '1KI', 'pasaka': '11'},
    '2 Kings': {'kjv': '2KI', 'pasaka': '12'},
    'Psalms': {'kjv': 'PSA', 'pasaka': '19'},
    'Proverbs': {'kjv': 'PRO', 'pasaka': '20'},
    'Isaiah': {'kjv': 'ISA', 'pasaka': '23'},
    'Jeremiah': {'kjv': 'JER', 'pasaka': '24'},
    'Daniel': {'kjv': 'DAN', 'pasaka': '27'},
    'Matthew': {'kjv': 'MAT', 'pasaka': '40'},
    'Mark': {'kjv': 'MRK', 'pasaka': '41'},
    'Luke': {'kjv': 'LUK', 'pasaka': '42'},
    'John': {'kjv': 'JHN', 'pasaka': '43'},
    'Acts': {'kjv': 'ACT', 'pasaka': '44'},
    'Romans': {'kjv': 'ROM', 'pasaka': '45'},
    '1 Corinthians': {'kjv': '1CO', 'pasaka': '46'},
    '2 Corinthians': {'kjv': '2CO', 'pasaka': '47'},
    'Galatians': {'kjv': 'GAL', 'pasaka': '48'},
    'Ephesians': {'kjv': 'EPH', 'pasaka': '49'},
    'Philippians': {'kjv': 'PHP', 'pasaka': '50'},
    'Colossians': {'kjv': 'COL', 'pasaka': '51'},
    '1 Thessalonians': {'kjv': '1TH', 'pasaka': '52'},
    '2 Thessalonians': {'kjv': '2TH', 'pasaka': '53'},
    '1 Timothy': {'kjv': '1TI', 'pasaka': '54'},
    '2 Timothy': {'kjv': '2TI', 'pasaka': '55'},
    'Titus': {'kjv': 'TIT', 'pasaka': '56'},
    'Hebrews': {'kjv': 'HEB', 'pasaka': '58'},
    'James': {'kjv': 'JAS', 'pasaka': '59'},
    '1 Peter': {'kjv': '1PE', 'pasaka': '60'},
    '2 Peter': {'kjv': '2PE', 'pasaka': '61'},
    '1 John': {'kjv': '1JN', 'pasaka': '62'},
    '2 John': {'kjv': '2JN', 'pasaka': '63'},
    '3 John': {'kjv': '3JN', 'pasaka': '64'},
    'Jude': {'kjv': 'JUD', 'pasaka': '65'},
    'Revelation': {'kjv': 'REV', 'pasaka': '66'},
  };

  final List<Map<String, dynamic>> _bibleBooks = [
    {
      'name': 'Genesis',
      'swahili': 'Mwanzo',
      'testament': 'old',
      'chapters': 50,
    },
    {'name': 'Exodus', 'swahili': 'Kutoka', 'testament': 'old', 'chapters': 40},
    {
      'name': 'Leviticus',
      'swahili': 'Mambo ya Walawi',
      'testament': 'old',
      'chapters': 27,
    },
    {
      'name': 'Numbers',
      'swahili': 'Hesabu',
      'testament': 'old',
      'chapters': 36,
    },
    {
      'name': 'Deuteronomy',
      'swahili': 'Kumbukumbu la Torati',
      'testament': 'old',
      'chapters': 34,
    },
    {'name': 'Joshua', 'swahili': 'Yoshua', 'testament': 'old', 'chapters': 24},
    {
      'name': 'Judges',
      'swahili': 'Waamuzi',
      'testament': 'old',
      'chapters': 21,
    },
    {'name': 'Ruth', 'swahili': 'Ruthu', 'testament': 'old', 'chapters': 4},
    {
      'name': '1 Samuel',
      'swahili': '1 Samweli',
      'testament': 'old',
      'chapters': 31,
    },
    {
      'name': '2 Samuel',
      'swahili': '2 Samweli',
      'testament': 'old',
      'chapters': 24,
    },
    {
      'name': '1 Kings',
      'swahili': '1 Wafalme',
      'testament': 'old',
      'chapters': 22,
    },
    {
      'name': '2 Kings',
      'swahili': '2 Wafalme',
      'testament': 'old',
      'chapters': 25,
    },
    {
      'name': 'Psalms',
      'swahili': 'Zaburi',
      'testament': 'old',
      'chapters': 150,
    },
    {
      'name': 'Proverbs',
      'swahili': 'Mithali',
      'testament': 'old',
      'chapters': 31,
    },
    {'name': 'Isaiah', 'swahili': 'Isaya', 'testament': 'old', 'chapters': 66},
    {
      'name': 'Jeremiah',
      'swahili': 'Yeremia',
      'testament': 'old',
      'chapters': 52,
    },
    {
      'name': 'Daniel',
      'swahili': 'Danieli',
      'testament': 'old',
      'chapters': 12,
    },
    {
      'name': 'Matthew',
      'swahili': 'Mathayo',
      'testament': 'new',
      'chapters': 28,
    },
    {'name': 'Mark', 'swahili': 'Marko', 'testament': 'new', 'chapters': 16},
    {'name': 'Luke', 'swahili': 'Luka', 'testament': 'new', 'chapters': 24},
    {'name': 'John', 'swahili': 'Yohana', 'testament': 'new', 'chapters': 21},
    {
      'name': 'Acts',
      'swahili': 'Matendo Ya Mitume',
      'testament': 'new',
      'chapters': 28,
    },
    {'name': 'Romans', 'swahili': 'Warumi', 'testament': 'new', 'chapters': 16},
    {
      'name': '1 Corinthians',
      'swahili': '1 Wakorintho',
      'testament': 'new',
      'chapters': 16,
    },
    {
      'name': '2 Corinthians',
      'swahili': '2 Wakorintho',
      'testament': 'new',
      'chapters': 13,
    },
    {
      'name': 'Galatians',
      'swahili': 'Wagalatia',
      'testament': 'new',
      'chapters': 6,
    },
    {
      'name': 'Ephesians',
      'swahili': 'Waefeso',
      'testament': 'new',
      'chapters': 6,
    },
    {
      'name': 'Philippians',
      'swahili': 'Wafilipi',
      'testament': 'new',
      'chapters': 4,
    },
    {
      'name': 'Colossians',
      'swahili': 'Wakolosai',
      'testament': 'new',
      'chapters': 4,
    },
    {
      'name': '1 Thessalonians',
      'swahili': '1 Wathesalonike',
      'testament': 'new',
      'chapters': 5,
    },
    {
      'name': '2 Thessalonians',
      'swahili': '2 Wathesalonike',
      'testament': 'new',
      'chapters': 3,
    },
    {
      'name': '1 Timothy',
      'swahili': '1 Timotheo',
      'testament': 'new',
      'chapters': 6,
    },
    {
      'name': '2 Timothy',
      'swahili': '2 Timotheo',
      'testament': 'new',
      'chapters': 4,
    },
    {'name': 'Titus', 'swahili': 'Tito', 'testament': 'new', 'chapters': 3},
    {
      'name': 'Hebrews',
      'swahili': 'Waebrania',
      'testament': 'new',
      'chapters': 13,
    },
    {'name': 'James', 'swahili': 'Yakobo', 'testament': 'new', 'chapters': 5},
    {
      'name': '1 Peter',
      'swahili': '1 Petro',
      'testament': 'new',
      'chapters': 5,
    },
    {
      'name': '2 Peter',
      'swahili': '2 Petro',
      'testament': 'new',
      'chapters': 3,
    },
    {
      'name': '1 John',
      'swahili': '1 Yohana',
      'testament': 'new',
      'chapters': 5,
    },
    {
      'name': '2 John',
      'swahili': '2 Yohana',
      'testament': 'new',
      'chapters': 1,
    },
    {
      'name': '3 John',
      'swahili': '3 Yohana',
      'testament': 'new',
      'chapters': 1,
    },
    {'name': 'Jude', 'swahili': 'Yuda', 'testament': 'new', 'chapters': 1},
    {
      'name': 'Revelation',
      'swahili': 'Ufunuo',
      'testament': 'new',
      'chapters': 22,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    ); // Added Favorites tab
    _tabController.addListener(_onTabChanged);
    _loadFavorites();
    _loadVerseColors();
    _loadBibleChapter();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      if (_tabController.index < 2) {
        // Only reload for KJV and Swahili tabs
        _loadBibleChapter();
      }
    }
  }

  // Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorite_verses') ?? [];
    if (mounted) {
      setState(() {
        _favoriteVerses = favs.toSet();
      });
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_verses', _favoriteVerses.toList());
  }

  // Load verse colors from SharedPreferences
  Future<void> _loadVerseColors() async {
    final prefs = await SharedPreferences.getInstance();
    final colors = prefs.getStringList('verse_colors') ?? [];
    final Map<String, String> colorMap = {};
    for (var entry in colors) {
      final parts = entry.split('|');
      if (parts.length == 2) {
        colorMap[parts[0]] = parts[1];
      }
    }
    if (mounted) {
      setState(() {
        _verseColors = colorMap;
      });
    }
  }

  // Save verse colors to SharedPreferences
  Future<void> _saveVerseColors() async {
    final prefs = await SharedPreferences.getInstance();
    final colors = _verseColors.entries
        .map((e) => '${e.key}|${e.value}')
        .toList();
    await prefs.setStringList('verse_colors', colors);
  }

  // Toggle favorite verse
  void _toggleFavorite(String verseId) {
    setState(() {
      if (_favoriteVerses.contains(verseId)) {
        _favoriteVerses.remove(verseId);
      } else {
        _favoriteVerses.add(verseId);
      }
    });
    _saveFavorites();
  }

  // Set verse highlight color
  void _setVerseColor(String verseId, String colorKey) {
    setState(() {
      if (_verseColors[verseId] == colorKey) {
        _verseColors.remove(verseId);
      } else {
        _verseColors[verseId] = colorKey;
      }
    });
    _saveVerseColors();
  }

  // Search for verses containing keywords
  Future<void> _searchVerses(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSearching = true;
        _isLoading = true;
      });
    }

    // Search current chapter
    final results = _verses.where((verse) {
      final text = verse['text']?.toString().toLowerCase() ?? '';
      return text.contains(query.toLowerCase());
    }).toList();

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  String _getVerseId(int verseNumber) {
    return '${_selectedBook}_${_selectedChapter}_$verseNumber';
  }

  Future<void> _loadBibleChapter() async {
    final isKJV = _tabController.index == 0;

    if (isKJV) {
      await _loadKJVChapter();
    } else {
      await _loadPasakaChapter();
    }
  }

  Future<void> _loadKJVChapter() async {
    // ... (Keep existing API loading code)
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final bookMapping = _bookIdMapping[_selectedBook];
      if (bookMapping == null) {
        throw Exception('Book mapping not found');
      }

      final bookId = bookMapping['kjv']!;
      final chapterReference = '$bookId.$_selectedChapter';
      final url =
          '$_kjvBaseUrl/bibles/$_kjvBibleId/chapters/$chapterReference?content-type=text&include-notes=false&include-titles=true&include-chapter-numbers=false&include-verse-numbers=true&include-verse-spans=false';

      print('Loading KJV from API: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'api-key': _kjvApiKey},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final content = jsonData['data']['content'] as String;
        final verses = _parseKJVVerses(content);

        if (mounted) {
          setState(() {
            _verses = verses;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load chapter: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading KJV: $e');
      if (mounted) {
        setState(() {
          _error = 'Unable to load chapter. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _parseKJVVerses(String content) {
    final verses = <Map<String, dynamic>>[];
    final versePattern = RegExp(r'\[(\d+)\]\s*([^\[]+)');
    final matches = versePattern.allMatches(content);

    for (var match in matches) {
      final verseNumber = int.parse(match.group(1)!);
      final verseText = match.group(2)!.trim();

      verses.add({'verse': verseNumber, 'text': verseText});
    }

    if (verses.isEmpty) {
      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty) {
          verses.add({'verse': i + 1, 'text': line});
        }
      }
    }

    return verses;
  }

  Future<void> _loadPasakaChapter() async {
    // ... (Keep existing Swahili loading code)
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/swahili_bible.json',
      );
      final jsonData = json.decode(jsonString);

      final bookMapping = _bookIdMapping[_selectedBook];
      if (bookMapping == null) {
        throw Exception('Book mapping not found');
      }

      final bookNumber = int.parse(bookMapping['pasaka']!);

      // Access the BIBLEBOOK array from the root object
      final bibleBooks = jsonData['BIBLEBOOK'] as List;

      dynamic targetBook = bibleBooks.firstWhere((book) {
        try {
          final num = book['book_number'];
          if (num is int) {
            return num == bookNumber;
          } else if (num is String) {
            return int.parse(num) == bookNumber;
          }
          return false;
        } catch (e) {
          return false;
        }
      }, orElse: () => null);

      if (targetBook == null) {
        throw Exception(
          'Book not found in Swahili Bible (book number: $bookNumber)',
        );
      }

      // Access CHAPTER array (uppercase in JSON)
      final chapters = targetBook['CHAPTER'] as List;
      dynamic targetChapter = chapters.firstWhere((chapter) {
        try {
          final num = chapter['chapter_number'];
          if (num is int) {
            return num == _selectedChapter;
          } else if (num is String) {
            return int.parse(num) == _selectedChapter;
          }
          return false;
        } catch (e) {
          return false;
        }
      }, orElse: () => null);

      if (targetChapter == null) {
        throw Exception('Chapter not found');
      }

      // Access VERSES array and map to expected format
      final verses = (targetChapter['VERSES'] as List).map((verse) {
        return {
          'verse': verse['verse_number'] is int
              ? verse['verse_number']
              : int.parse(verse['verse_number'].toString()),
          'text': verse['verse_text'].toString(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _verses = verses;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading Pasaka: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading Swahili Bible chapter.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildEnhancedHeader(),
          if (!_readingMode) _buildSearchBar(),
          if (!_readingMode) _buildNavigationControls(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryPurpleDeep, AppColors.primaryPurpleVibrant],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurpleDeep.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
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
                  _tabController.index == 0
                      ? 'Holy Bible (KJV)'
                      : 'Biblia Takatifu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_favoriteVerses.length} Favorite${_favoriteVerses.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _readingMode = !_readingMode;
              });
            },
            icon: Icon(
              _readingMode ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Reading Mode',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
      child: TextField(
        controller: _searchController,
        onChanged: _searchVerses,
        decoration: InputDecoration(
          hintText: 'Search verses by keywords...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primaryPurpleDeep,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _searchVerses('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    final currentBook = _bibleBooks.firstWhere(
      (book) => book['name'] == _selectedBook,
      orElse: () => _bibleBooks[0],
    );
    final maxChapters = currentBook['chapters'] as int;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildBookSelector()),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurpleDeep.withValues(alpha: 0.1),
                  AppColors.primaryPurpleVibrant.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryPurpleVibrant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _selectedChapter > 1
                      ? () {
                          setState(() {
                            _selectedChapter--;
                            _loadBibleChapter();
                          });
                        }
                      : null,
                  iconSize: 28,
                  color: AppColors.primaryPurpleDeep,
                ),
                GestureDetector(
                  onTap: () => _showChapterSelector(maxChapters),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurpleDeep,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Ch $_selectedChapter',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _selectedChapter < maxChapters
                      ? () {
                          setState(() {
                            _selectedChapter++;
                            _loadBibleChapter();
                          });
                        }
                      : null,
                  iconSize: 28,
                  color: AppColors.primaryPurpleDeep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookSelector() {
    return GestureDetector(
      onTap: _showBookSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryPurpleVibrant,
              AppColors.primaryPurpleDeep,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurpleVibrant.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _getBookDisplayName(_selectedBook),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  String _getBookDisplayName(String bookName) {
    try {
      final book = _bibleBooks.firstWhere((b) => b['name'] == bookName);
      final isSwahili = _tabController.index == 1;

      if (isSwahili) {
        final swahiliName = book['swahili'];
        if (swahiliName != null && swahiliName is String) {
          return swahiliName;
        }
      }

      final englishName = book['name'];
      if (englishName != null && englishName is String) {
        return englishName;
      }

      return bookName;
    } catch (e) {
      return bookName;
    }
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.book, size: 20), text: 'KJV'),
          Tab(icon: Icon(Icons.translate, size: 20), text: 'Swahili'),
          Tab(icon: Icon(Icons.favorite, size: 20), text: 'Favorites'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_tabController.index == 2) {
      return _buildFavoritesView();
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryPurpleDeep),
            const SizedBox(height: 16),
            const Text('Loading chapter...'),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadBibleChapter,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurpleDeep,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final versesToShow = _isSearching && _searchResults.isNotEmpty
        ? _searchResults
        : _verses;

    if (versesToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.book_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No verses found' : 'No verses available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(_readingMode ? 6 : 12),
      itemCount: versesToShow.length,
      itemBuilder: (context, index) {
        final verse = versesToShow[index];
        return _buildEnhancedVerseCard(verse);
      },
    );
  }

  Widget _buildEnhancedVerseCard(Map<String, dynamic> verse) {
    final verseNumber = verse['verse'] as int;
    final verseText = verse['text'] as String;
    final verseId = _getVerseId(verseNumber);
    final isFavorite = _favoriteVerses.contains(verseId);
    final colorKey = _verseColors[verseId];
    final highlightColor = colorKey != null ? _highlightColors[colorKey] : null;

    if (_readingMode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$verseNumber ',
                style: TextStyle(
                  fontSize: _fontSize - 2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurpleDeep,
                ),
              ),
              TextSpan(
                text: verseText,
                style: TextStyle(
                  fontSize: _fontSize,
                  color: Colors.black87,
                  height: 1.6,
                  backgroundColor: highlightColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: highlightColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFavorite ? Colors.red.shade300 : Colors.grey.shade200,
          width: isFavorite ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isFavorite
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showVerseActions(verseId, verseNumber, verseText),
        onLongPress: () => _toggleFavorite(verseId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFavorite
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : [
                            AppColors.primaryPurpleVibrant.withValues(
                              alpha: 0.7,
                            ),
                            AppColors.primaryPurpleDeep.withValues(alpha: 0.7),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$verseNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SelectableText(
                  verseText,
                  style: TextStyle(
                    fontSize: _fontSize,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey[400],
                  size: 22,
                ),
                onPressed: () => _toggleFavorite(verseId),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesView() {
    if (_favoriteVerses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No favorite verses yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any verse to save it',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteVerses.length,
      itemBuilder: (context, index) {
        final verseId = _favoriteVerses.elementAt(index);
        final parts = verseId.split('_');
        if (parts.length != 3) return const SizedBox();

        final book = parts[0];
        final chapter = parts[1];
        final verse = parts[2];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.favorite, color: Colors.white),
            ),
            title: Text(
              '$book $chapter:$verse',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Tap to view',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _toggleFavorite(verseId),
            ),
            onTap: () {
              // Navigate to the verse
              setState(() {
                _selectedBook = book;
                _selectedChapter = int.parse(chapter);
                _tabController.index = 0; // Switch to KJV tab
              });
              _loadBibleChapter();
            },
          ),
        );
      },
    );
  }

  void _showVerseActions(String verseId, int verseNumber, String verseText) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Verse $verseNumber',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Highlight Color',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: _highlightColors.entries.map((entry) {
                  final isSelected = _verseColors[verseId] == entry.key;
                  return GestureDetector(
                    onTap: () {
                      _setVerseColor(verseId, entry.key);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryPurpleDeep
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.black54)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Copy verse
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Share verse
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurpleDeep,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showBookSelector() {
    // ... (Keep existing book selector code)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Book',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _bibleBooks.length,
                    itemBuilder: (context, index) {
                      final book = _bibleBooks[index];
                      final isSelected = book['name'] == _selectedBook;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppColors.primaryPurpleLight
                            .withValues(alpha: 0.1),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primaryPurpleVibrant,
                                      AppColors.primaryPurpleDeep,
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          _getBookDisplayName(book['name']),
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${book['chapters']} chapters',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedBook = book['name'];
                            _selectedChapter = 1;
                          });
                          Navigator.pop(context);
                          _loadBibleChapter();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChapterSelector(int maxChapters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Chapter',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: maxChapters,
                  itemBuilder: (context, index) {
                    final chapter = index + 1;
                    final isSelected = chapter == _selectedChapter;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedChapter = chapter;
                        });
                        Navigator.pop(context);
                        _loadBibleChapter();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppColors.primaryPurpleVibrant,
                                    AppColors.primaryPurpleDeep,
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryPurpleDeep
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$chapter',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
