import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Service for managing live streams
class LiveStreamService {
  /// Get all live streams
  Future<Map<String, dynamic>> getLiveStreams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/church/live-streams/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'streams': data['results'] ?? data};
      } else {
        return {'success': false, 'error': 'Failed to fetch streams'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error fetching streams: $e'};
    }
  }

  /// Get current live stream
  Future<Map<String, dynamic>> getCurrentLiveStream() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/church/live-streams/?status=live'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final streams = data['results'] ?? data;
        return {
          'success': true,
          'stream': streams.isNotEmpty ? streams[0] : null,
        };
      } else {
        return {'success': false, 'error': 'Failed to fetch current stream'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error fetching current stream: $e'};
    }
  }

  /// Create a new live stream
  Future<Map<String, dynamic>> createLiveStream({
    required String title,
    required String youtubeUrl,
    required String description,
    required DateTime scheduledFor,
    String? thumbnailUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      // Extract YouTube video ID from URL
      final videoId = _extractYouTubeId(youtubeUrl);
      if (videoId == null) {
        return {'success': false, 'error': 'Invalid YouTube URL'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/church/live-streams/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'youtube_url': youtubeUrl,
          'youtube_video_id': videoId,
          'description': description,
          'scheduled_for': scheduledFor.toIso8601String(),
          'thumbnail_url': thumbnailUrl,
          'status': 'scheduled',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'stream': data};
      } else {
        return {
          'success': false,
          'error': 'Failed to create stream: ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error creating stream: $e'};
    }
  }

  /// Update live stream status
  Future<Map<String, dynamic>> updateStreamStatus({
    required int streamId,
    required String status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.apiUrl}/church/live-streams/$streamId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'stream': data};
      } else {
        return {'success': false, 'error': 'Failed to update stream'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error updating stream: $e'};
    }
  }

  /// Delete a live stream
  Future<Map<String, dynamic>> deleteLiveStream(int streamId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.apiUrl}/church/live-streams/$streamId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Failed to delete stream'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error deleting stream: $e'};
    }
  }

  /// Extract YouTube video ID from URL
  String? _extractYouTubeId(String url) {
    // Match various YouTube URL formats
    final regexPatterns = [
      RegExp(r'(?:youtube\.com/watch\?v=|youtu\.be/)([^&\?/]+)'),
      RegExp(r'youtube\.com/embed/([^&\?/]+)'),
      RegExp(r'youtube\.com/v/([^&\?/]+)'),
      RegExp(r'youtube\.com/live/([^&\?/]+)'), // Added support for /live/ URLs
    ];

    for (final regex in regexPatterns) {
      final match = regex.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }

    // If it's just the video ID
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return url;
    }

    return null;
  }
}
