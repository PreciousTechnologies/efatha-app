import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/config/api_config.dart';

class SermonDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sermon;

  const SermonDetailScreen({super.key, required this.sermon});

  @override
  State<SermonDetailScreen> createState() => _SermonDetailScreenState();
}

class _SermonDetailScreenState extends State<SermonDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;
  bool _viewCounted = false; // Track if view has been counted

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _incrementViewCount(); // Track view when sermon detail opens
  }

  Future<void> _incrementViewCount() async {
    // Prevent duplicate counting
    if (_viewCounted) {
      print('⚠️ View already counted for this sermon');
      return;
    }

    try {
      final sermonId = widget.sermon['id'];
      print('');
      print('═══════════════════════════════════════');
      print('🔍 Attempting to increment view count');
      print('🔍 Sermon ID: $sermonId');
      print('🔍 Sermon Title: ${widget.sermon['title']}');

      if (sermonId == null) {
        print('❌ ERROR: Sermon ID is null, cannot increment view');
        print('❌ Sermon data: ${widget.sermon}');
        print('═══════════════════════════════════════');
        return;
      }

      // Use ApiConfig for correct IP address (works for both emulator and physical device)
      final url = Uri.parse('${ApiConfig.sermons}$sermonId/increment_view/');
      print('📡 API URL: $url');
      print('📡 Making POST request...');

      final response = await http
          .post(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('❌ REQUEST TIMEOUT after 10 seconds');
              throw Exception('Request timeout');
            },
          );

      print('📥 Response received!');
      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _viewCounted = true; // Mark as counted

        print('✅ SUCCESS! View count incremented!');
        print('✅ New view count: ${data['views']} views');
        print('═══════════════════════════════════════');
        print('');

        // Update the sermon data with new view count
        if (mounted) {
          setState(() {
            widget.sermon['views'] = data['views'];
          });
        }
      } else {
        print('❌ FAILED with status code: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        print('═══════════════════════════════════════');
        print('');
      }
    } catch (e, stackTrace) {
      print('❌ EXCEPTION while incrementing view count!');
      print('❌ Exception: $e');
      print('❌ Exception type: ${e.runtimeType}');
      print('❌ Stack trace: $stackTrace');
      print('═══════════════════════════════════════');
      print('');
      // Don't show error to user, this is a background operation
    }
  }

  Future<void> _initializePlayer() async {
    try {
      final videoUrl = widget.sermon['video_url'];
      final audioUrl = widget.sermon['audio_url'];

      if (videoUrl != null) {
        // Initialize video player
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );
        await _videoController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoController!.value.aspectRatio,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading video', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );

        setState(() {
          _isLoading = false;
        });
      } else if (audioUrl != null) {
        // TODO: Initialize audio player
        setState(() {
          _isLoading = false;
          _error = 'Audio player not yet implemented';
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'No media available for this sermon';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load media: $e';
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _downloadSermon() async {
    final videoUrl = widget.sermon['video_url'];
    final audioUrl = widget.sermon['audio_url'];
    final title = widget.sermon['title'] ?? 'Sermon';

    if (videoUrl == null && audioUrl == null) {
      _showSnackBar('No media file available to download', isError: true);
      return;
    }

    // Request notification permission for Android 13+
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.request();
      if (!notificationStatus.isGranted) {
        _showSnackBar(
          'Notification permission is needed to show download progress',
          isError: true,
        );
      }
    }

    try {
      // Get the download URL and extension
      final downloadUrl = videoUrl ?? audioUrl;
      final extension = videoUrl != null ? 'mp4' : 'mp3';
      final fileName =
          '${title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Get Downloads directory path and create it if it doesn't exist
      String downloadPath;
      if (Platform.isAndroid) {
        downloadPath = '/storage/emulated/0/Download/Efatha_Sermons';
        // Create directory if it doesn't exist
        final dir = Directory(downloadPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } else {
        // For iOS, use Documents directory
        final dir = await getApplicationDocumentsDirectory();
        downloadPath = '${dir.path}/Efatha_Sermons';
        // Create directory if it doesn't exist
        final efathaDir = Directory(downloadPath);
        if (!await efathaDir.exists()) {
          await efathaDir.create(recursive: true);
        }
      }

      // Enqueue the download task
      final taskId = await FlutterDownloader.enqueue(
        url: downloadUrl!,
        savedDir: downloadPath,
        fileName: fileName,
        showNotification: true, // Show download notification
        openFileFromNotification: true, // Click notification to open file
        saveInPublicStorage: true, // Save in public Downloads folder
      );

      if (taskId != null) {
        _showSnackBar(
          'Download started! Check your notification panel',
          isError: false,
        );
      } else {
        _showSnackBar('Failed to start download', isError: true);
      }
    } catch (e) {
      _showSnackBar('Download failed: ${e.toString()}', isError: true);
    }
  }

  Future<void> _shareSermon() async {
    final title = widget.sermon['title'] ?? 'Sermon';
    final pastor = widget.sermon['pastor'] ?? 'Unknown Pastor';
    final description = widget.sermon['description'] ?? '';
    final videoUrl = widget.sermon['video_url'];
    final audioUrl = widget.sermon['audio_url'];

    // Build share message
    String shareMessage =
        '''
🎬 Efatha Church Sermon 🙏

📖 Title: $title
👤 Speaker: $pastor

${description.isNotEmpty ? '📝 $description\n' : ''}''';

    if (videoUrl != null) {
      shareMessage += '\n🎥 Watch Video: $videoUrl';
    }
    if (audioUrl != null) {
      shareMessage += '\n🎧 Listen Audio: $audioUrl';
    }

    shareMessage += '\n\n✨ Download Efatha Church App to watch more sermons!';

    try {
      await Share.share(shareMessage, subject: 'Efatha Church - $title');
    } catch (e) {
      _showSnackBar('Share failed: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.sermon['title'] ?? 'Sermon';
    final pastor = widget.sermon['pastor'] ?? 'Unknown Pastor';
    final category = widget.sermon['category'] ?? 'SERMON';
    final description = widget.sermon['description'] ?? '';

    // Handle topics - can be either a List or a String
    final topicsData = widget.sermon['topics'];
    final List<String> topicsList = [];
    if (topicsData != null) {
      if (topicsData is List) {
        topicsList.addAll(topicsData.map((t) => t.toString()));
      } else if (topicsData is String && topicsData.isNotEmpty) {
        topicsList.addAll(topicsData.split(',').map((t) => t.trim()));
      }
    }

    final duration = widget.sermon['duration'] ?? '00:00';
    final views = widget.sermon['views'] ?? 0;
    final thumbnailUrl = widget.sermon['thumbnail_url'];

    return Scaffold(
      backgroundColor: AppColors.neutralBackgroundLightest,
      body: CustomScrollView(
        slivers: [
          // App Bar with image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnailUrl != null)
                    Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildGradientBackground();
                      },
                    )
                  else
                    _buildGradientBackground(),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Player
                if (_chewieController != null && !_isLoading)
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: Chewie(controller: _chewieController!),
                  )
                else if (_isLoading)
                  Container(
                    height: 200,
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (_error != null)
                  Container(
                    height: 200,
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Sermon Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
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
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        title,
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutralTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Pastor
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primaryPurpleVibrant
                                .withValues(alpha: 0.2),
                            child: Icon(
                              Icons.person,
                              color: AppColors.primaryPurpleDeep,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Speaker',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.neutralTextMuted,
                                ),
                              ),
                              Text(
                                pastor,
                                style: AppTextStyles.bodyMediumWeight.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Stats
                      Row(
                        children: [
                          _buildStat(Icons.access_time, duration),
                          const SizedBox(width: 24),
                          _buildStat(Icons.visibility_outlined, '$views views'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Topics
                      if (topicsList.isNotEmpty) ...[
                        Text(
                          'Topics',
                          style: AppTextStyles.bodyMediumWeight.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: topicsList
                              .map((topic) => _buildTopicChip(topic))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Description
                      if (description.isNotEmpty) ...[
                        Text(
                          'About this sermon',
                          style: AppTextStyles.bodyMediumWeight.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: AppTextStyles.bodyRegular.copyWith(
                            color: AppColors.neutralTextSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _downloadSermon,
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Download'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurpleDeep,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _shareSermon,
                              icon: const Icon(Icons.share_rounded),
                              label: const Text('Share'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryPurpleDeep,
                                side: BorderSide(
                                  color: AppColors.primaryPurpleDeep,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
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
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryPurpleDeep),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.bodyRegular.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.neutralTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicChip(String topic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryPurpleVibrant.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPurpleVibrant.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        topic,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primaryPurpleDeep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
