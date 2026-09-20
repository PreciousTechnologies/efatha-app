import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/supabase_config.dart';
import 'supabase_auth_service.dart';
import 'supabase_database_service.dart';

/// Service for managing live streams.
/// Supabase-first (Django fallback while migrating). Signatures unchanged
/// so live_screen / create_live_stream_screen work on both backends
/// (Supabase ids are uuid strings, Django ids are ints -> dynamic).
class LiveStreamService {
  final SupabaseDatabaseService _db = SupabaseDatabaseService();

  /// Get all live streams
  Future<Map<String, dynamic>> getLiveStreams() async {
    if (SupabaseConfig.isConfigured) {
      try {
        final rows = await _db.list(
          SupabaseConfig.liveStreamsTable,
          orderBy: 'created_at',
          limit: 50,
        );
        return {'success': true, 'streams': rows};
      } catch (e) {
        return {'success': false, 'error': 'Error fetching streams: $e'};
      }
    }

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
    if (SupabaseConfig.isConfigured) {
      try {
        final stream = await _db.getCurrentLiveStream();
        return {'success': true, 'stream': stream};
      } catch (e) {
        return {
          'success': false,
          'error': 'Error fetching current stream: $e',
        };
      }
    }

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
    // Extract YouTube video ID from URL (backend-independent).
    final videoId = _extractYouTubeId(youtubeUrl);
    if (videoId == null) {
      return {'success': false, 'error': 'Invalid YouTube URL'};
    }

    if (SupabaseConfig.isConfigured) {
      try {
        final uid = SupabaseAuthService().currentUser?.id;
        if (uid == null) {
          return {'success': false, 'error': 'Not authenticated'};
        }
        final row = await _db.insert(SupabaseConfig.liveStreamsTable, {
          'title': title,
          'youtube_url': youtubeUrl,
          'youtube_video_id': videoId,
          'description': description,
          'scheduled_for': scheduledFor.toIso8601String(),
          'thumbnail_url': thumbnailUrl,
          'status': 'scheduled',
          'created_by': uid,
        });
        return {'success': true, 'stream': row};
      } catch (e) {
        return {'success': false, 'error': 'Error creating stream: $e'};
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
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
    required dynamic streamId,
    required String status,
  }) async {
    if (SupabaseConfig.isConfigured) {
      try {
        final uid = SupabaseAuthService().currentUser?.id;
        if (uid == null) {
          return {'success': false, 'error': 'Not authenticated'};
        }
        final row = await _db.update(
          SupabaseConfig.liveStreamsTable,
          streamId,
          {'status': status},
        );
        return {'success': true, 'stream': row};
      } catch (e) {
        return {'success': false, 'error': 'Error updating stream: $e'};
      }
    }

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
  Future<Map<String, dynamic>> deleteLiveStream(dynamic streamId) async {
    if (SupabaseConfig.isConfigured) {
      try {
        final uid = SupabaseAuthService().currentUser?.id;
        if (uid == null) {
          return {'success': false, 'error': 'Not authenticated'};
        }
        await _db.delete(SupabaseConfig.liveStreamsTable, streamId);
        return {'success': true};
      } catch (e) {
        return {'success': false, 'error': 'Error deleting stream: $e'};
      }
    }

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
