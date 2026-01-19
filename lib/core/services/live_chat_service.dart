import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class LiveChatService {
  /// Get chat messages for a live stream
  Future<Map<String, dynamic>> getChatMessages({
    required int liveStreamId,
    int limit = 100,
  }) async {
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
    required int liveStreamId,
    required String message,
  }) async {
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
  Future<Map<String, dynamic>> deleteMessage(int messageId) async {
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
