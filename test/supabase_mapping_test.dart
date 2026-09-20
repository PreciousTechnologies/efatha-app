import 'package:flutter_test/flutter_test.dart';
import 'package:efatha_app/core/config/supabase_config.dart';
import 'package:efatha_app/core/services/supabase_auth_service.dart';
import 'package:efatha_app/core/services/supabase_database_service.dart';
import 'package:efatha_app/models/believer_model.dart';

void main() {
  group('SupabaseConfig', () {
    test('isConfigured is false with placeholder defaults', () {
      // In tests no --dart-define flags are passed, so placeholders apply.
      expect(SupabaseConfig.isConfigured, isFalse);
    });

    test('debugReset restores placeholder (unconfigured) state', () {
      SupabaseConfig.debugReset();
      SupabaseConfig.init(); // no .env loaded in tests, no dart-define
      expect(SupabaseConfig.isConfigured, isFalse);
    });

    test('table + bucket names are non-empty', () {
      expect(SupabaseConfig.profilesTable, 'profiles');
      expect(SupabaseConfig.sermonsTable, 'sermons');
      expect(SupabaseConfig.eventsTable, 'events');
      expect(SupabaseConfig.prayerRequestsTable, 'prayer_requests');
      expect(SupabaseConfig.testimoniesTable, 'testimonies');
      expect(SupabaseConfig.profilesBucket, isNotEmpty);
      expect(SupabaseConfig.sermonsBucket, isNotEmpty);
    });
  });

  group('SupabaseDatabaseService normalizers (pure, no network)', () {
    final db = SupabaseDatabaseService();

    test('normalizeSermon maps preacher->pastor alias', () {
      final out = db.normalizeSermon({
        'id': 'uuid-1',
        'title': 'Faith',
        'preacher': 'Pastor John',
      });
      expect(out['pastor'], 'Pastor John');
      expect(out['preacher'], 'Pastor John');
      expect(out['views'], 0);
    });

    test('normalizeSermon keeps Django-style rows intact', () {
      final out = db.normalizeSermon({
        'id': 7,
        'title': 'Grace',
        'pastor': 'Pastor Jane',
        'thumbnail_url': 'http://x/y.jpg',
        'views': 12,
      });
      expect(out['pastor'], 'Pastor Jane');
      expect(out['thumbnail_url'], 'http://x/y.jpg');
      expect(out['views'], 12);
    });

    test('normalizeEvent maps banner_url->banner_image', () {
      final out = db.normalizeEvent({
        'id': 'uuid-2',
        'title': 'Youth Night',
        'banner_url': 'https://cdn/banner.jpg',
        'start_date': '2026-10-01T18:00:00Z',
      });
      expect(out['banner_image'], 'https://cdn/banner.jpg');
    });
  });

  group('SupabaseAuthService.friendlyError (pure, no network)', () {
    test('rate limit maps to wait-and-retry guidance', () {
      final out = SupabaseAuthService.friendlyError(
        'email rate limit exceeded',
      );
      expect(out.toLowerCase(), contains('wait'));
      expect(out.toLowerCase(), contains('hour'));
    });

    test('known cases map, unknown passes through', () {
      expect(
        SupabaseAuthService.friendlyError('User already registered'),
        contains('sign in'),
      );
      expect(
        SupabaseAuthService.friendlyError('Invalid login credentials'),
        contains('Wrong email'),
      );
      expect(
        SupabaseAuthService.friendlyError('Something totally new'),
        'Something totally new',
      );
    });
  });

  group('Announcements filter (pure, no network)', () {
    test('drops expired, keeps missing/future expiry', () {
      final now = DateTime(2026, 9, 19);
      final rows = [
        {'id': 'a', 'expiry_date': null},
        {
          'id': 'b',
          'expiry_date': '2026-10-01T00:00:00Z',
        },
        {
          'id': 'c',
          'expiry_date': '2026-09-01T00:00:00Z',
        },
        {'id': 'd'},
      ];
      final out = SupabaseDatabaseService.filterActiveAnnouncements(
        rows.map((e) => Map<String, dynamic>.from(e)).toList(),
        now,
      );
      expect(out.map((e) => e['id']), containsAll(['a', 'b', 'd']));
      expect(out.map((e) => e['id']), isNot(contains('c')));
    });

    test('giving category mapping covers all UI labels', () {
      expect(
        SupabaseDatabaseService.givingTypeForUiCategory('Tithe'),
        'tithe',
      );
      expect(
        SupabaseDatabaseService.givingTypeForUiCategory('Construction'),
        'building',
      );
      expect(
        SupabaseDatabaseService.givingTypeForUiCategory('All'),
        'other',
      );
      expect(
        SupabaseDatabaseService.givingTypesForUiCategory('All'),
        isNull,
      );
    });
  });

  group('BelieverModel', () {
    test('fullName skips empty middle name', () {
      final m = BelieverModel(
        firstName: 'Amina',
        lastName: 'Juma',
        gender: 'Female',
        birthDate: DateTime(1990, 1, 1),
        phone: '0712345678',
        email: 'a@b.com',
      );
      expect(m.fullName, 'Amina Juma');
      expect(m.isValid, isTrue);
    });

    test('isValid false when required fields missing', () {
      final m = BelieverModel(
        firstName: '',
        lastName: 'Juma',
        gender: 'Female',
        birthDate: DateTime(1990, 1, 1),
        phone: '',
        email: 'a@b.com',
      );
      expect(m.isValid, isFalse);
    });

    test('fromJson/toJson round-trips legacy keys', () {
      final json = {
        'Believer_ID': 'B-1',
        'First_Name': 'Amina',
        'Middle_Name': '',
        'Last_Name': 'Juma',
        'Gender': 'Female',
        'Birth_Date': '1995-04-12',
        'Phone': '0712345678',
        'Email': 'amina@example.com',
        'Church_Position': 'muumini',
      };
      final m = BelieverModel.fromJson(json);
      expect(m.fullName, 'Amina Juma');
      final out = m.toJson();
      expect(out['First_Name'], 'Amina');
      expect(out['Birth_Date'], '1995-04-12');
    });
  });
}
