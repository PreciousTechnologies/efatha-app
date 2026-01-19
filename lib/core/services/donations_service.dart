import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Service for fetching donation data from the backend
class DonationsService {
  /// Get user's donation history
  Future<Map<String, dynamic>> getDonationHistory({
    String? category,
    String? period,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (category != null && category != 'All') {
        queryParams['category'] = category;
      }
      if (period != null) {
        queryParams['period'] = period.toLowerCase();
      }

      final uri = Uri.parse(ApiConfig.giving).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'donations': data['results'] ?? data,
          'total_amount': data['total_amount'] ?? 0,
          'total_count': data['count'] ?? 0,
          'average_amount': data['average_amount'] ?? 0,
          'summary': data['summary'] ?? {},
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch donations: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching donations: $e',
      };
    }
  }

  /// Get donation statistics/summary
  Future<Map<String, dynamic>> getDonationStats({String? period}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      final queryParams = <String, String>{};
      if (period != null) {
        queryParams['period'] = period.toLowerCase();
      }
      queryParams['stats'] = 'true';

      final uri = Uri.parse(ApiConfig.giving).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'total_amount': data['total_amount'] ?? 0,
          'total_count': data['count'] ?? 0,
          'average_amount': data['average_amount'] ?? 0,
          'by_category': data['by_category'] ?? {},
          'currency': data['currency'] ?? 'TZS',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch stats',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching stats: $e',
      };
    }
  }
}
