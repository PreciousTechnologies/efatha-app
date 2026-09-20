import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/supabase_config.dart';
import 'storage_service.dart';
import 'supabase_auth_service.dart';
import 'supabase_database_service.dart';

/// Service for fetching donation data.
/// Supabase-first (Django fallback while migrating).
///
/// NOTE: fixed the legacy bug where the Django path read a nonexistent
/// 'auth_token' key — it now uses StorageService (same 'access_token').
class DonationsService {
  final StorageService _storage = StorageService();
  final SupabaseDatabaseService _db = SupabaseDatabaseService();

  bool _inPeriod(DateTime created, String? period) {
    if (period == null) return true;
    final now = DateTime.now();
    switch (period.toLowerCase()) {
      case 'weekly':
        return created.isAfter(now.subtract(const Duration(days: 7)));
      case 'monthly':
        return created.year == now.year && created.month == now.month;
      case 'yearly':
        return created.year == now.year;
      default:
        return true;
    }
  }

  /// Get user's donation history (Supabase path computes client-side).
  Future<Map<String, dynamic>> getDonationHistory({
    String? category,
    String? period,
  }) async {
    if (SupabaseConfig.isConfigured) {
      try {
        if (SupabaseAuthService().currentUser == null) {
          return {'success': false, 'error': 'Not authenticated'};
        }
        var givings = await _db.getMyGivings(limit: 200);

        final types = category == null
            ? null
            : SupabaseDatabaseService.givingTypesForUiCategory(category);
        final filtered = givings.where((g) {
          if (types != null &&
              !types.contains(
                g['giving_type']?.toString().toLowerCase(),
              )) {
            return false;
          }
          final created = DateTime.tryParse(
            g['created_at']?.toString() ?? '',
          );
          if (created == null) return false;
          return _inPeriod(created, period);
        }).toList();

        final completed = filtered
            .where((g) => g['payment_status'] == 'completed')
            .toList();
        final total = completed.fold<double>(
          0,
          (sum, g) => sum + ((g['amount'] as num?)?.toDouble() ?? 0),
        );
        return {
          'success': true,
          'donations': filtered,
          'total_amount': total,
          'total_count': completed.length,
          'average_amount': completed.isEmpty
              ? 0
              : total / completed.length,
          'summary': {},
        };
      } catch (e) {
        return {'success': false, 'error': 'Error fetching donations: $e'};
      }
    }

    try {
      final token = await _storage.getAccessToken();

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
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
      return {'success': false, 'error': 'Error fetching donations: $e'};
    }
  }

  /// Get donation statistics/summary.
  Future<Map<String, dynamic>> getDonationStats({String? period}) async {
    if (SupabaseConfig.isConfigured) {
      try {
        if (SupabaseAuthService().currentUser == null) {
          return {'success': false, 'error': 'Not authenticated'};
        }
        final givings = await _db.getMyGivings(limit: 500);
        final inPeriod = givings.where((g) {
          final created = DateTime.tryParse(
            g['created_at']?.toString() ?? '',
          );
          if (created == null) return false;
          return _inPeriod(created, period);
        }).toList();
        final completed = inPeriod
            .where((g) => g['payment_status'] == 'completed')
            .toList();
        final total = completed.fold<double>(
          0,
          (sum, g) => sum + ((g['amount'] as num?)?.toDouble() ?? 0),
        );
        final byCategory = <String, double>{};
        for (final g in completed) {
          final key = g['giving_type']?.toString() ?? 'other';
          byCategory[key] =
              (byCategory[key] ?? 0) +
              (((g['amount'] as num?)?.toDouble() ?? 0));
        }
        String currency = 'TZS';
        if (completed.isNotEmpty) {
          currency = completed.first['currency']?.toString() ?? 'TZS';
        }
        return {
          'success': true,
          'total_amount': total,
          'total_count': completed.length,
          'average_amount': completed.isEmpty ? 0 : total / completed.length,
          'by_category': byCategory,
          'currency': currency,
        };
      } catch (e) {
        return {'success': false, 'error': 'Error fetching stats: $e'};
      }
    }

    try {
      final token = await _storage.getAccessToken();

      if (token == null) {
        return {'success': false, 'error': 'Not authenticated'};
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
        return {'success': false, 'error': 'Failed to fetch stats'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error fetching stats: $e'};
    }
  }
}
