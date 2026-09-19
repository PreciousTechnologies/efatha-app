import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/services/live_stream_service.dart';
import '../../core/services/live_chat_service.dart';
import '../../core/services/storage_service.dart';
import 'create_live_stream_screen.dart';

/// Live Screen - Live streaming and scheduled broadcasts
class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final LiveStreamService _liveStreamService = LiveStreamService();
  final LiveChatService _liveChatService = LiveChatService();
  final StorageService _storageService = StorageService();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  bool _isLoading = true;
  bool _isAdmin = false;
  Map<String, dynamic>? _currentStream;
  List<Map<String, dynamic>> _upcomingStreams = [];
  List<Map<String, dynamic>> _chatMessages = [];
  YoutubePlayerController? _youtubeController;
  Timer? _chatRefreshTimer;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadStreams();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _chatRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final role = await _storageService.getUserRole();
    setState(() {
      _isAdmin = role == 'admin' || role == 'editor';
    });
  }

  Future<void> _loadStreams() async {
    setState(() => _isLoading = true);

    try {
      // Get current live stream
      final currentResult = await _liveStreamService.getCurrentLiveStream();

      // Get all streams
      final allStreamsResult = await _liveStreamService.getLiveStreams();

      if (mounted) {
        setState(() {
          if (currentResult['success'] == true) {
            _currentStream = currentResult['stream'];
            if (_currentStream != null &&
                _currentStream!['youtube_video_id'] != null) {
              _initializeYoutubePlayer(_currentStream!['youtube_video_id']);
              // Start loading chat messages
              _loadChatMessages();
              // Set up auto-refresh for chat
              _startChatRefresh();
            }
          }

          if (allStreamsResult['success'] == true) {
            final streams = List<Map<String, dynamic>>.from(
              allStreamsResult['streams'] ?? [],
            );
            _upcomingStreams = streams
                .where((s) => s['status'] == 'scheduled')
                .toList();
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading streams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initializeYoutubePlayer(String videoId) {
    try {
      print('Initializing YouTube player with video ID: $videoId');

      // Dispose old controller if exists
      _youtubeController?.dispose();

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false, // Changed to false for slow connections
          mute: false,
          enableCaption: false,
          controlsVisibleAtStart: true,
          hideControls: false,
          loop: false,
          isLive: true, // Important for live streams
          forceHD: false, // Don't force HD on slow connections
          disableDragSeek: false,
        ),
      );

      // Add listener to track player state
      _youtubeController!.addListener(() {
        if (mounted) {
          if (_youtubeController!.value.isReady) {
            print('YouTube player is ready');
          }
          if (_youtubeController!.value.hasError) {
            print(
              'YouTube player error: ${_youtubeController!.value.errorCode}',
            );
            // Show error message to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Playback error. Slow connection detected (260kbps). Consider opening in YouTube app.',
                ),
                action: SnackBarAction(
                  label: 'Open YouTube',
                  onPressed: () {
                    if (_currentStream != null) {
                      _launchYouTube(_currentStream!['youtube_url']);
                    }
                  },
                ),
                duration: const Duration(seconds: 7),
              ),
            );
          }
          if (_youtubeController!.value.playerState == PlayerState.playing) {
            print('YouTube player is playing');
          }
          if (_youtubeController!.value.playerState == PlayerState.buffering) {
            print(
              'YouTube player is buffering (this may take a while on slow connections)',
            );
          }
        }
      });
    } catch (e) {
      print('Error initializing YouTube player: $e');
    }
  }

  // Chat methods
  Future<void> _loadChatMessages() async {
    if (_currentStream == null) return;

    try {
      final result = await _liveChatService.getChatMessages(
        liveStreamId: _currentStream!['id'],
        limit: 100,
      );

      if (mounted && result['success'] == true) {
        setState(() {
          _chatMessages = List<Map<String, dynamic>>.from(
            result['messages'] ?? [],
          );
        });

        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatScrollController.hasClients) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      print('Error loading chat messages: $e');
    }
  }

  void _startChatRefresh() {
    // Refresh chat every 3 seconds
    _chatRefreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadChatMessages(),
    );
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty || _currentStream == null) return;

    final message = _chatController.text.trim();
    _chatController.clear();

    // Get user info for optimistic UI update
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'You';
    final userProfilePicture = prefs.getString('user_profile_picture');

    // Add message optimistically to UI
    final optimisticMessage = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'message': message,
      'user_name': userName,
      'user_profile_picture': userProfilePicture,
      'is_own_message': true,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _chatMessages.add(optimisticMessage);
      _isSendingMessage = true;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final result = await _liveChatService.sendMessage(
        liveStreamId: _currentStream!['id'],
        message: message,
      );

      if (mounted) {
        setState(() => _isSendingMessage = false);

        if (result['success'] == true) {
          // Reload messages to get the actual server response
          _loadChatMessages();
        } else {
          // Remove optimistic message on failure
          setState(() {
            _chatMessages.removeWhere(
              (m) => m['id'] == optimisticMessage['id'],
            );
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to send message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
          // Remove optimistic message on error
          _chatMessages.removeWhere((m) => m['id'] == optimisticMessage['id']);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchYouTube(String url) async {
    final uri = Uri.parse(url);
    try {
      // Try to launch in external app
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Could not launch YouTube: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLive = _currentStream != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Live Stream',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.red, Color(0xFFD32F2F)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurpleLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.primaryPurpleDeep,
                  size: 20,
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateLiveStreamScreen(),
                  ),
                );
                if (result == true) {
                  _loadStreams();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadStreams,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPurpleDeep,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Video Player
                  if (isLive) _buildLivePlayer(),

                  // Stream Info
                  if (isLive)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentStream!['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentStream!['description'] ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _buildInfoChip(
                                Icons.visibility,
                                'Live Now',
                                Colors.red,
                              ),
                              if (_currentStream!['created_at'] != null)
                                _buildInfoChip(
                                  Icons.access_time,
                                  _formatDate(_currentStream!['created_at']),
                                  Colors.blue,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Live Chat Section
                  if (isLive)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Chat header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  color: AppColors.primaryPurpleDeep,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Live Chat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_chatMessages.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Chat messages
                          Container(
                            height: 300,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _chatMessages.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.chat_outlined,
                                          size: 48,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No messages yet',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Be the first to say something!',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _chatScrollController,
                                    itemCount: _chatMessages.length,
                                    itemBuilder: (context, index) {
                                      final message = _chatMessages[index];
                                      final isOwnMessage =
                                          message['is_own_message'] == true;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                          top: 4,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // User avatar
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: isOwnMessage
                                                  ? AppColors.primaryPurpleDeep
                                                  : Colors.grey[300],
                                              backgroundImage:
                                                  message['user_profile_picture'] !=
                                                      null
                                                  ? NetworkImage(
                                                      message['user_profile_picture'],
                                                    )
                                                  : null,
                                              child:
                                                  message['user_profile_picture'] ==
                                                      null
                                                  ? Text(
                                                      (message['user_name'] ??
                                                              'U')[0]
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: isOwnMessage
                                                            ? Colors.white
                                                            : Colors.grey[700],
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            // Message bubble
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        message['user_name'] ??
                                                            'User',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                          color: isOwnMessage
                                                              ? AppColors
                                                                    .primaryPurpleDeep
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        _formatChatTime(
                                                          message['created_at'],
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    message['message'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[800],
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          // Chat input
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _chatController,
                                    decoration: InputDecoration(
                                      hintText: 'Type a message...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    maxLines: 1,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: _isSendingMessage
                                      ? Colors.grey[300]
                                      : AppColors.primaryPurpleDeep,
                                  borderRadius: BorderRadius.circular(24),
                                  child: InkWell(
                                    onTap: _isSendingMessage
                                        ? null
                                        : _sendMessage,
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: _isSendingMessage
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      Colors.white,
                                                    ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.send_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // No Live Stream Message
                  if (!isLive)
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(32),
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.live_tv_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Live Stream',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later or view upcoming streams below',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Upcoming Streams
                  if (_upcomingStreams.isNotEmpty)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Upcoming Streams',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurpleLight
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_upcomingStreams.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryPurpleDeep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...(_upcomingStreams.map(
                            (stream) => _buildUpcomingCard(stream),
                          )),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatChatTime(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildLivePlayer() {
    if (_youtubeController == null) {
      return Container(
        height: 240,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          // YouTube Player with Builder for proper initialization
          YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _youtubeController!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
              progressColors: const ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
                backgroundColor: Colors.grey,
                bufferedColor: Colors.white54,
              ),
              bottomActions: [
                CurrentPosition(),
                ProgressBar(isExpanded: true),
                RemainingDuration(),
                const PlaybackSpeedButton(),
              ],
              onReady: () {
                print('YouTube player ready - Manual play for slow connection');
                // Don't auto-play for slow connections
                // User can tap play when ready
              },
              onEnded: (data) {
                print('Video ended');
              },
            ),
            builder: (context, player) {
              return player;
            },
          ),

          // Slow connection warning
          if (_youtubeController!.value.playerState == PlayerState.buffering)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Buffering...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This may take longer on slow connections',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // Live Badge Overlay
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // "Watch on YouTube" button overlay
          Positioned(
            bottom: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_currentStream != null &&
                      _currentStream!['youtube_url'] != null) {
                    _launchYouTube(_currentStream!['youtube_url']);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Watch on YouTube',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(Map<String, dynamic> stream) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.pink,
    ];
    final color = colors[stream['id'] % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stream['title'] ?? 'Untitled Stream',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (stream['scheduled_for'] != null)
                  Text(
                    _formatScheduledDate(stream['scheduled_for']),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          if (_isAdmin)
            PopupMenuButton(
              icon: Icon(Icons.more_vert, color: color),
              onSelected: (value) async {
                if (value == 'go_live') {
                  await _liveStreamService.updateStreamStatus(
                    streamId: stream['id'],
                    status: 'live',
                  );
                  _loadStreams();
                } else if (value == 'delete') {
                  _showDeleteConfirmation(stream['id']);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'go_live',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, size: 18),
                      SizedBox(width: 8),
                      Text('Go Live'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: color),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reminder set!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatScheduledDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return 'Today at ${TimeOfDay.fromDateTime(date).format(context)}';
      } else if (date.difference(now).inDays == 1) {
        return 'Tomorrow at ${TimeOfDay.fromDateTime(date).format(context)}';
      } else {
        return '${date.month}/${date.day}/${date.year} at ${TimeOfDay.fromDateTime(date).format(context)}';
      }
    } catch (e) {
      return dateString;
    }
  }

  void _showDeleteConfirmation(int streamId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stream?'),
        content: const Text(
          'Are you sure you want to delete this stream? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _liveStreamService.deleteLiveStream(
                streamId,
              );
              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stream deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadStreams();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
