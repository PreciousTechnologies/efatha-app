import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Media Library Screen - Browse sermons, music, and videos
class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _sermons = [
    {
      'title': 'The Power of Faith',
      'speaker': 'Pastor John',
      'date': 'Jan 21, 2024',
      'duration': '45:30',
      'downloads': 234,
      'viewers': 1542,
      'isDownloaded': false,
    },
    {
      'title': 'Walking in Love',
      'speaker': 'Pastor Sarah',
      'date': 'Jan 14, 2024',
      'duration': '38:15',
      'downloads': 189,
      'viewers': 978,
      'isDownloaded': false,
    },
    {
      'title': 'Victory in Christ',
      'speaker': 'Pastor Michael',
      'date': 'Jan 7, 2024',
      'duration': '42:20',
      'downloads': 312,
      'viewers': 2156,
      'isDownloaded': true,
    },
  ];

  final List<Map<String, dynamic>> _books = [
    {
      'title': 'Walking with God',
      'author': 'Pastor John Doe',
      'category': 'Spiritual Growth',
      'pages': 245,
      'readers': 1834,
      'downloads': 456,
      'isDownloaded': false,
      'color': [Colors.blue[400]!, Colors.blue[700]!],
    },
    {
      'title': 'Power of Prayer',
      'author': 'Rev. Sarah Smith',
      'category': 'Prayer & Devotion',
      'pages': 180,
      'readers': 2156,
      'downloads': 623,
      'isDownloaded': false,
      'color': [Colors.purple[400]!, Colors.purple[700]!],
    },
    {
      'title': 'Faith in Action',
      'author': 'Dr. Michael Brown',
      'category': 'Christian Living',
      'pages': 312,
      'readers': 1567,
      'downloads': 389,
      'isDownloaded': true,
      'color': [Colors.green[400]!, Colors.green[700]!],
    },
    {
      'title': 'Love Never Fails',
      'author': 'Grace Kimathi',
      'category': 'Relationships',
      'pages': 198,
      'readers': 987,
      'downloads': 234,
      'isDownloaded': false,
      'color': [Colors.pink[400]!, Colors.pink[700]!],
    },
  ];

  final List<Map<String, dynamic>> _music = [
    {
      'title': 'How Great Thou Art',
      'artist': 'Efatha Choir',
      'album': 'Worship Collection',
      'duration': '4:32',
    },
    {
      'title': 'Blessed Assurance',
      'artist': 'Youth Band',
      'album': 'Sunday Worship',
      'duration': '3:45',
    },
    {
      'title': 'Amazing Grace',
      'artist': 'Efatha Choir',
      'album': 'Classic Hymns',
      'duration': '5:12',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Media Library',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: AppColors.primaryPurpleDeep,
            ),
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: AppColors.primaryPurpleDeep),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryPurpleDeep,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryPurpleDeep,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Sermons'),
            Tab(text: 'Books'),
            Tab(text: 'Music'),
            Tab(text: 'Videos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSermonsList(),
          _buildBooksList(),
          _buildMusicList(),
          _buildVideosPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildSermonsList() {
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _sermons.length,
        itemBuilder: (context, index) => _buildSermonGridCard(_sermons[index]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sermons.length,
      itemBuilder: (context, index) => _buildSermonListCard(_sermons[index]),
    );
  }

  Widget _buildSermonGridCard(Map<String, dynamic> sermon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Stack(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurpleDeep,
                      AppColors.primaryPurpleVibrant,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              // Download indicator
              if (sermon['isDownloaded'])
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sermon['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  sermon['speaker'],
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 11,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${sermon['viewers']}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 11,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          sermon['duration'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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

  Widget _buildSermonListCard(Map<String, dynamic> sermon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurpleDeep,
                          AppColors.primaryPurpleVibrant,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  if (sermon['isDownloaded'])
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sermon['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sermon['speaker'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${sermon['viewers']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sermon['duration'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      sermon['isDownloaded'] = !sermon['isDownloaded'];
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          sermon['isDownloaded']
                              ? 'Downloaded successfully!'
                              : 'Download removed',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    sermon['isDownloaded']
                        ? Icons.download_done
                        : Icons.download_outlined,
                    size: 18,
                  ),
                  label: Text(
                    sermon['isDownloaded'] ? 'Downloaded' : 'Download',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: sermon['isDownloaded']
                        ? Colors.green
                        : AppColors.primaryPurpleDeep,
                    side: BorderSide(
                      color: sermon['isDownloaded']
                          ? Colors.green
                          : AppColors.primaryPurpleDeep,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share feature - Coming Soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryPurpleDeep,
                  side: BorderSide(color: AppColors.primaryPurpleDeep),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList() {
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          return _buildBookGridCard(book);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          return _buildBookListCard(book);
        },
      );
    }
  }

  Widget _buildBookGridCard(Map<String, dynamic> book) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: book['color'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.menu_book, color: Colors.white, size: 60),
                ),
              ),
              if (book['isDownloaded'])
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    book['category'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book['author'],
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.person, size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${book['readers']}',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${book['pages']}p',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          book['isDownloaded'] = !book['isDownloaded'];
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              book['isDownloaded']
                                  ? 'Book downloaded!'
                                  : 'Download removed',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        book['isDownloaded']
                            ? Icons.download_done
                            : Icons.download_outlined,
                        size: 11,
                      ),
                      label: Text(
                        book['isDownloaded'] ? 'Downloaded' : 'Download',
                        style: const TextStyle(fontSize: 9),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: book['isDownloaded']
                            ? Colors.green
                            : AppColors.primaryPurpleDeep,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 26),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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

  Widget _buildBookListCard(Map<String, dynamic> book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 70,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: book['color'],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  if (book['isDownloaded'])
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: book['color'][0].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        book['category'],
                        style: TextStyle(
                          fontSize: 10,
                          color: book['color'][1],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book['author'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${book['readers']} readers',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.article,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${book['pages']} pages',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${book['downloads']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      book['isDownloaded'] = !book['isDownloaded'];
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          book['isDownloaded']
                              ? 'Book downloaded successfully!'
                              : 'Download removed',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    book['isDownloaded']
                        ? Icons.download_done
                        : Icons.download_outlined,
                    size: 18,
                  ),
                  label: Text(
                    book['isDownloaded'] ? 'Downloaded' : 'Download',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: book['isDownloaded']
                        ? Colors.green
                        : AppColors.primaryPurpleDeep,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Read feature - Coming Soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.book_outlined, size: 18),
                label: const Text('Read', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryPurpleDeep,
                  side: BorderSide(color: AppColors.primaryPurpleDeep),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMusicList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _music.length,
      itemBuilder: (context, index) {
        final song = _music[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${song['artist']} • ${song['album']}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                song['duration'],
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.play_circle_outline, color: Colors.green[700]),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideosPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.video_library, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            'No videos available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for video content',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
