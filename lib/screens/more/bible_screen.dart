import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

/// Bible Screen - KJV Strongs Concordance & Biblia Takatifu (Swahili)
class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedBook = 'Genesis';
  int _selectedChapter = 1;
  List<dynamic> _verses = [];
  bool _isLoading = false;
  String _error = '';

  // Bible API Configuration for KJV English
  static const String _kjvApiKey = '84928751f9913ac558a1e24b4731a29e';
  static const String _kjvBaseUrl = 'https://api.scripture.api.bible/v1';
  static const String _kjvBibleId = 'de4e12af7f28f599-02';

  // Book ID mapping: English name -> (KJV ID, Pasaka book_number)
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadBibleChapter();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadBibleChapter();
    }
  }

  final List<Map<String, dynamic>> _bibleBooks = [
    // Old Testament
    {
      'name': 'Genesis',
      'swahili': 'Mwanzo',
      'chapters': 50,
      'testament': 'Old',
      'id': 'GEN',
    },
    {
      'name': 'Exodus',
      'swahili': 'Kutoka',
      'chapters': 40,
      'testament': 'Old',
      'id': 'EXO',
    },
    {
      'name': 'Leviticus',
      'swahili': 'Mambo ya Walawi',
      'chapters': 27,
      'testament': 'Old',
      'id': 'LEV',
    },
    {
      'name': 'Numbers',
      'swahili': 'Hesabu',
      'chapters': 36,
      'testament': 'Old',
      'id': 'NUM',
    },
    {
      'name': 'Deuteronomy',
      'swahili': 'Kumbukumbu la Torati',
      'chapters': 34,
      'testament': 'Old',
      'id': 'DEU',
    },
    {
      'name': 'Joshua',
      'swahili': 'Yoshua',
      'chapters': 24,
      'testament': 'Old',
      'id': 'JOS',
    },
    {
      'name': 'Judges',
      'swahili': 'Waamuzi',
      'chapters': 21,
      'testament': 'Old',
      'id': 'JDG',
    },
    {
      'name': 'Ruth',
      'swahili': 'Ruthi',
      'chapters': 4,
      'testament': 'Old',
      'id': 'RUT',
    },
    {
      'name': '1 Samuel',
      'swahili': '1 Samweli',
      'chapters': 31,
      'testament': 'Old',
      'id': '1SA',
    },
    {
      'name': '2 Samuel',
      'swahili': '2 Samweli',
      'chapters': 24,
      'testament': 'Old',
      'id': '2SA',
    },
    {
      'name': '1 Kings',
      'swahili': '1 Wafalme',
      'chapters': 22,
      'testament': 'Old',
      'id': '1KI',
    },
    {
      'name': '2 Kings',
      'swahili': '2 Wafalme',
      'chapters': 25,
      'testament': 'Old',
      'id': '2KI',
    },
    {
      'name': 'Psalms',
      'swahili': 'Zaburi',
      'chapters': 150,
      'testament': 'Old',
      'id': 'PSA',
    },
    {
      'name': 'Proverbs',
      'swahili': 'Mithali',
      'chapters': 31,
      'testament': 'Old',
      'id': 'PRO',
    },
    {
      'name': 'Isaiah',
      'swahili': 'Isaya',
      'chapters': 66,
      'testament': 'Old',
      'id': 'ISA',
    },
    {
      'name': 'Jeremiah',
      'swahili': 'Yeremia',
      'chapters': 52,
      'testament': 'Old',
      'id': 'JER',
    },
    {
      'name': 'Daniel',
      'swahili': 'Danieli',
      'chapters': 12,
      'testament': 'Old',
      'id': 'DAN',
    },
    // New Testament
    {
      'name': 'Matthew',
      'swahili': 'Mathayo',
      'chapters': 28,
      'testament': 'New',
      'id': 'MAT',
    },
    {
      'name': 'Mark',
      'swahili': 'Marko',
      'chapters': 16,
      'testament': 'New',
      'id': 'MRK',
    },
    {
      'name': 'Luke',
      'swahili': 'Luka',
      'chapters': 24,
      'testament': 'New',
      'id': 'LUK',
    },
    {
      'name': 'John',
      'swahili': 'Yohana',
      'chapters': 21,
      'testament': 'New',
      'id': 'JHN',
    },
    {
      'name': 'Acts',
      'swahili': 'Matendo',
      'chapters': 28,
      'testament': 'New',
      'id': 'ACT',
    },
    {
      'name': 'Romans',
      'swahili': 'Warumi',
      'chapters': 16,
      'testament': 'New',
      'id': 'ROM',
    },
    {
      'name': '1 Corinthians',
      'swahili': '1 Wakorintho',
      'chapters': 16,
      'testament': 'New',
      'id': '1CO',
    },
    {
      'name': '2 Corinthians',
      'swahili': '2 Wakorintho',
      'chapters': 13,
      'testament': 'New',
      'id': '2CO',
    },
    {
      'name': 'Galatians',
      'swahili': 'Wagalatia',
      'chapters': 6,
      'testament': 'New',
      'id': 'GAL',
    },
    {
      'name': 'Ephesians',
      'swahili': 'Waefeso',
      'chapters': 6,
      'testament': 'New',
      'id': 'EPH',
    },
    {
      'name': 'Philippians',
      'swahili': 'Wafilipi',
      'chapters': 4,
      'testament': 'New',
      'id': 'PHP',
    },
    {
      'name': 'Colossians',
      'swahili': 'Wakolosai',
      'chapters': 4,
      'testament': 'New',
      'id': 'COL',
    },
    {
      'name': '1 Thessalonians',
      'swahili': '1 Wathesalonike',
      'chapters': 5,
      'testament': 'New',
      'id': '1TH',
    },
    {
      'name': '2 Thessalonians',
      'swahili': '2 Wathesalonike',
      'chapters': 3,
      'testament': 'New',
      'id': '2TH',
    },
    {
      'name': '1 Timothy',
      'swahili': '1 Timotheo',
      'chapters': 6,
      'testament': 'New',
      'id': '1TI',
    },
    {
      'name': '2 Timothy',
      'swahili': '2 Timotheo',
      'chapters': 4,
      'testament': 'New',
      'id': '2TI',
    },
    {
      'name': 'Titus',
      'swahili': 'Tito',
      'chapters': 3,
      'testament': 'New',
      'id': 'TIT',
    },
    {
      'name': 'Hebrews',
      'swahili': 'Waebrania',
      'chapters': 13,
      'testament': 'New',
      'id': 'HEB',
    },
    {
      'name': 'James',
      'swahili': 'Yakobo',
      'chapters': 5,
      'testament': 'New',
      'id': 'JAS',
    },
    {
      'name': '1 Peter',
      'swahili': '1 Petro',
      'chapters': 5,
      'testament': 'New',
      'id': '1PE',
    },
    {
      'name': '2 Peter',
      'swahili': '2 Petro',
      'chapters': 3,
      'testament': 'New',
      'id': '2PE',
    },
    {
      'name': '1 John',
      'swahili': '1 Yohana',
      'chapters': 5,
      'testament': 'New',
      'id': '1JN',
    },
    {
      'name': '2 John',
      'swahili': '2 Yohana',
      'chapters': 1,
      'testament': 'New',
      'id': '2JN',
    },
    {
      'name': '3 John',
      'swahili': '3 Yohana',
      'chapters': 1,
      'testament': 'New',
      'id': '3JN',
    },
    {
      'name': 'Jude',
      'swahili': 'Yuda',
      'chapters': 1,
      'testament': 'New',
      'id': 'JUD',
    },
    {
      'name': 'Revelation',
      'swahili': 'Ufunuo',
      'chapters': 22,
      'testament': 'New',
      'id': 'REV',
    },
  ];

  // Get display name based on current language
  String _getBookDisplayName(String bookName) {
    try {
      final book = _bibleBooks.firstWhere(
        (b) => b['name'] == bookName,
        orElse: () => {'name': bookName, 'swahili': bookName},
      );
      final isSwahili = _tabController.index == 1;
      if (isSwahili) {
        final swahiliName = book['swahili'];
        if (swahiliName != null && swahiliName is String) {
          return swahiliName;
        }
        final englishName = book['name'];
        if (englishName != null && englishName is String) {
          return englishName;
        }
        return bookName;
      }
      final englishName = book['name'];
      if (englishName != null && englishName is String) {
        return englishName;
      }
      return bookName;
    } catch (e) {
      print('Error getting book display name for $bookName: $e');
      return bookName;
    }
  }

  // Load Bible chapter from API
  Future<void> _loadBibleChapter() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final isSwahili = _tabController.index == 1;

      if (isSwahili) {
        await _loadPasakaChapter();
      } else {
        await _loadKJVChapter();
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Load KJV chapter from scripture.api.bible API
  Future<void> _loadKJVChapter() async {
    final bookMapping = _bookIdMapping[_selectedBook];
    if (bookMapping == null) {
      setState(() {
        _error = 'Book not found';
        _isLoading = false;
      });
      return;
    }

    final bookId = bookMapping['kjv']!;
    final chapterReference = '$bookId.$_selectedChapter';
    final url =
        '$_kjvBaseUrl/bibles/$_kjvBibleId/chapters/$chapterReference?content-type=text&include-notes=false&include-titles=true&include-chapter-numbers=false&include-verse-numbers=true&include-verse-spans=false';

    print('Loading KJV from API: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'api-key': _kjvApiKey},
      );

      print('KJV API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['data']['content'];

        // Parse verses from KJV content (format: [1] verse text [2] verse text)
        final verses = _parseKJVVerses(content);

        setState(() {
          _verses = verses;
          _isLoading = false;
        });
      } else {
        print('KJV API Error response: ${response.body}');
        setState(() {
          _error = 'Failed to load chapter (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading KJV: $e');
      setState(() {
        _error = 'Error loading KJV Bible: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Load Swahili chapter from local JSON file
  Future<void> _loadPasakaChapter() async {
    final bookMapping = _bookIdMapping[_selectedBook];
    if (bookMapping == null) {
      setState(() {
        _error = 'Book not found';
        _isLoading = false;
      });
      return;
    }

    try {
      final bookNumber = bookMapping['pasaka']!;

      print(
        'Loading Swahili Bible from local file: Book $bookNumber, Chapter $_selectedChapter',
      );

      // Load the JSON file from assets
      final jsonString = await rootBundle.loadString(
        'assets/data/swahili_bible.json',
      );
      final jsonData = json.decode(jsonString);

      // Find the book
      final books = jsonData['BIBLEBOOK'] as List?;
      if (books == null) {
        setState(() {
          _error = 'Invalid Bible data structure';
          _isLoading = false;
        });
        return;
      }

      dynamic book;
      try {
        book = books.firstWhere((b) => b['book_number'] == bookNumber);
      } catch (e) {
        setState(() {
          _error = 'Book not found in Swahili Bible';
          _isLoading = false;
        });
        return;
      }

      // Find the chapter
      final chapters = book['CHAPTER'] as List?;
      if (chapters == null) {
        setState(() {
          _error = 'No chapters found for this book';
          _isLoading = false;
        });
        return;
      }

      dynamic chapter;
      try {
        chapter = chapters.firstWhere(
          (c) => c['chapter_number'] == _selectedChapter.toString(),
        );
      } catch (e) {
        setState(() {
          _error = 'Chapter not found';
          _isLoading = false;
        });
        return;
      }

      // Extract verses
      final versesData = chapter['VERSES'] as List?;
      if (versesData == null) {
        setState(() {
          _error = 'No verses found for this chapter';
          _isLoading = false;
        });
        return;
      }

      final verses = versesData.map((verse) {
        final verseNumber = verse['verse_number']?.toString() ?? '?';
        final verseText = verse['verse_text']?.toString() ?? '';
        return {'number': verseNumber, 'text': verseText};
      }).toList();

      print('Swahili verses loaded: ${verses.length}');

      setState(() {
        _verses = verses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading Swahili Bible: $e');
      setState(() {
        _error = 'Error loading Swahili Bible: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Parse verses from KJV API content
  List<Map<String, dynamic>> _parseKJVVerses(String content) {
    final verses = <Map<String, dynamic>>[];

    // Split by verse numbers (pattern: [1], [2], etc.)
    final versePattern = RegExp(r'\[(\d+)\]\s*([^\[]+)');
    final matches = versePattern.allMatches(content);

    for (final match in matches) {
      final verseNumber = match.group(1);
      final verseText = match.group(2)?.trim() ?? '';

      if (verseText.isNotEmpty) {
        verses.add({'number': verseNumber, 'text': verseText});
      }
    }

    // If no verses found, try alternative parsing
    if (verses.isEmpty && content.isNotEmpty) {
      // Clean up the content and create a single verse
      final cleanContent = content.replaceAll(RegExp(r'[\[\]]'), '').trim();
      verses.add({'number': '1', 'text': cleanContent});
    }

    return verses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header with tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Version selector tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[700],
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'KJV (English)'),
                      Tab(text: 'Swahili'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Current selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _showBookSelector,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryPurpleDeep,
                                  AppColors.primaryPurpleVibrant,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getBookDisplayName(_selectedBook),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showChapterSelector,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryPurpleDeep,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Ch $_selectedChapter',
                                style: TextStyle(
                                  color: AppColors.primaryPurpleDeep,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.primaryPurpleDeep,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Bible content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBibleContent(isSwahili: false),
                _buildBibleContent(isSwahili: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBibleContent({required bool isSwahili}) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryPurpleDeep),
            const SizedBox(height: 16),
            Text(
              'Loading ${isSwahili ? "Swahili" : "KJV"} Bible...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
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

    if (_verses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No verses found',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter title
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_getBookDisplayName(_selectedBook)} $_selectedChapter',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPurpleDeep,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurpleDeep.withOpacity(0.2),
                      AppColors.primaryPurpleVibrant.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_verses.length} verses',
                  style: TextStyle(
                    color: AppColors.primaryPurpleDeep,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Real verses from API
          ...List.generate(_verses.length, (index) {
            final verse = _verses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurpleDeep.withOpacity(0.2),
                          AppColors.primaryPurpleVibrant.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        verse['number'].toString(),
                        style: TextStyle(
                          color: AppColors.primaryPurpleDeep,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      verse['text'],
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showBookSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Book',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurpleDeep,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildTestamentSection('Old Testament'),
                  _buildTestamentSection('New Testament'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestamentSection(String testament) {
    final books = _bibleBooks
        .where(
          (book) =>
              (book['testament'] as String? ?? '') == testament.split(' ')[0],
        )
        .toList();

    final isSwahili = _tabController.index == 1;
    final testamentTitle = testament == 'Old Testament'
        ? (isSwahili ? 'Agano la Kale' : 'Old Testament')
        : (isSwahili ? 'Agano Jipya' : 'New Testament');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            testamentTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: books.map((book) {
            final bookName = book['name'] as String? ?? 'Unknown';
            final isSelected = bookName == _selectedBook;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBook = bookName;
                  _selectedChapter = 1;
                });
                Navigator.pop(context);
                _loadBibleChapter();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.primaryPurpleDeep,
                            AppColors.primaryPurpleVibrant,
                          ],
                        )
                      : null,
                  color: isSelected ? null : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _getBookDisplayName(bookName),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[800],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showChapterSelector() {
    final book = _bibleBooks.firstWhere(
      (b) => b['name'] == _selectedBook,
      orElse: () => {'name': _selectedBook, 'chapters': 1},
    );
    final chapters = book['chapters'] as int? ?? 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Chapter',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurpleDeep,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: chapters,
                itemBuilder: (context, index) {
                  final chapter = index + 1;
                  final isSelected = chapter == _selectedChapter;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedChapter = chapter;
                      });
                      Navigator.pop(context);
                      _loadBibleChapter();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppColors.primaryPurpleDeep,
                                  AppColors.primaryPurpleVibrant,
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          '$chapter',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 16,
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
      ),
    );
  }
}
