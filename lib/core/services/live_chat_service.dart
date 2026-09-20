import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/supabase_config.dart';
import 'supabase_auth_service.dart';
import 'supabase_database_service.dart';

/// Live chat for streams. Supabase-first (Django fallback).
/// Screen code in live_screen.dart is unchanged (same result shapes).
class LiveChatService {
  final SupabaseDatabaseService _db = SupabaseDatabaseService();
  final SupabaseAuthService _auth = SupabaseAuthService();

  /// Get chat messages for a live stream
  Future<Map<String, dynamic>> getChatMessages({
    required dynamic liveStreamId,
    int limit = 100,
  }) async {
    if (SupabaseConfig.isConfigured) {
      try {
        final uid = _auth.currentUser?.id;
        final messages = await _db.list(
          SupabaseConfig.liveChatMessagesTable,
          orderBy: 'created_at',
          ascending: true,
          limit: limit,
          filters: {'live_stream_id': liveStreamId.toString()},
        );
        // Flag own messages so the UI styles + allows deleting them.
        if (uid != null) {
          for (final m in messages) {
            if (m['user_id']?.toString() == uid) {
              m['is_own_message'] = true;
            }
          }
        }
        return {'success': true, 'messages': messages};
      } catch (e) {
        return {'success': false, 'message': 'Error loading messages: $e'};
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.apiUrl}/church/live-chat/?live_stream=$liveStreamId&limit=$limit',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'messages': data};
      } else {
        return {
          'success': false,
          'message': 'Failed to load messages: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error loading messages: $e'};
    }
  }

  /// Send a chat message
  Future<Map<String, dynamic>> sendMessage({
    required dynamic liveStreamId,
    required String message,
  }) async {
    if (SupabaseConfig.isConfigured) {
      try {
        final user = _auth.currentUser;
        if (user == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
        String displayName = user.email?.split('@').first ?? 'Member';
        try {
          final profile = await _auth.getCurrentProfile();
          final first = (profile?['first_name']?.toString() ?? '').trim();
          final last = (profile?['last_name']?.toString() ?? '').trim();
          final full = '$first $last'.trim();
          if (full.isNotEmpty) displayName = full;
        } catch (_) {}
        final row = await _db.insert(
          SupabaseConfig.liveChatMessagesTable,
          {
            'live_stream_id': liveStreamId.toString(),
            'user_id': user.id,
            'user_name': displayName,
            'message': message,
          },
        );
        return {'success': true, 'message_data': row};
      } catch (e) {
        return {'success': false, 'message': 'Error sending message: $e'};
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/church/live-chat/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'live_stream': liveStreamId, 'message': message}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'message_data': data};
      } else {
        return {
          'success': false,
          'message': 'Failed to send message: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error sending message: $e'};
    }
  }

  /// Delete a chat message (only own messages)
  Future<Map<String, dynamic>> deleteMessage(dynamic messageId) async {
    if (SupabaseConfig.isConfigured) {
      try {
        if (_auth.currentUser == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
        await _db.delete(
          SupabaseConfig.liveChatMessagesTable,
          messageId,
        );
        return {'success': true, 'message': 'Message deleted successfully'};
      } catch (e) {
        return {'success': false, 'message': 'Error deleting message: $e'};
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.apiUrl}/church/live-chat/$messageId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        return {'success': true, 'message': 'Message deleted successfully'};
      } else {
        return {
          'success': false,
          'message': 'Failed to delete message: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error deleting message: $e'};
    }
  }
}
