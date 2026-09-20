import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase Configuration for Efatha Church App.
///
/// Key priority (highest first):
///  1. --dart-define=SUPABASE_URL / SUPABASE_ANON_KEY (CI, release builds)
///  2. Local `.env` file in project root (gitignored, dev convenience —
///     this is what makes plain `flutter run` work on your machine)
///  3. Placeholders below (Supabase stays OFF, Django fallback active)
///
/// Never commit real keys: `.env` is gitignored (see .gitignore).
class SupabaseConfig {
  static const String _placeholderUrl = 'https://YOUR-PROJECT-REF.supabase.co';
  static const String _placeholderKey = 'YOUR-SUPABASE-ANON-KEY';

  // Compile-time overrides (empty unless passed via --dart-define).
  static const String _envUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _envKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String _url = _placeholderUrl;
  static String _key = _placeholderKey;
  static bool _initialized = false;

  /// Call once in main() after `dotenv.load()` (safe to call repeatedly).
  /// Tolerates dotenv never being loaded (tests, edge cases).
  static void init() {
    if (_initialized) return;
    _initialized = true;

    String dotenvUrl = '';
    String dotenvKey = '';
    try {
      dotenvUrl = dotenv.maybeGet('SUPABASE_URL')?.trim() ?? '';
      dotenvKey = dotenv.maybeGet('SUPABASE_ANON_KEY')?.trim() ?? '';
    } catch (_) {
      // dotenv.load() was never called — fall through to other sources.
    }

    if (_envUrl.isNotEmpty) {
      _url = _envUrl;
    } else if (dotenvUrl.isNotEmpty) {
      _url = dotenvUrl;
    }

    if (_envKey.isNotEmpty) {
      _key = _envKey;
    } else if (dotenvKey.isNotEmpty) {
      _key = dotenvKey;
    }
  }

  static String get supabaseUrl => _url;
  static String get supabaseAnonKey => _key;

  /// Number of code boxes shown. Supabase sends 6–10 digit email codes
  /// (Cloud default is 8; the length setting is NOT exposed on the hosted
  /// dashboard), so boxes fit the longest common code and verification
  /// accepts any 6–8 digit entry. No dashboard change needed.
  static const int emailOtpLength = 8;

  /// Shortest code the app will submit (Supabase minimum is 6).
  static const int emailOtpMinLength = 6;

  static bool get isConfigured =>
      !_url.contains('YOUR-PROJECT-REF') && !_key.contains('YOUR-SUPABASE');

  /// Test-only reset (lets unit tests control configuration state).
  static void debugReset() {
    _url = _placeholderUrl;
    _key = _placeholderKey;
    _initialized = false;
  }

  // Table names (mirror of Django models -> Supabase tables, see supabase/schema.sql)
  static const String profilesTable = 'profiles';
  static const String sermonsTable = 'sermons';
  static const String eventsTable = 'events';
  static const String eventRegistrationsTable = 'event_registrations';
  static const String prayerRequestsTable = 'prayer_requests';
  static const String prayerSupportsTable = 'prayer_supports';
  static const String prayerImagesTable = 'prayer_images';
  static const String prayerCommentsTable = 'prayer_comments';
  static const String testimoniesTable = 'testimonies';
  static const String testimonyPraisesTable = 'testimony_praises';
  static const String givingsTable = 'givings';
  static const String paymentTransactionsTable = 'payment_transactions';
  static const String announcementsTable = 'announcements';
  static const String liveStreamsTable = 'live_streams';
  static const String liveChatMessagesTable = 'live_chat_messages';
  static const String bibleFavoritesTable = 'bible_favorites';
  static const String bibleHighlightsTable = 'bible_highlights';
  static const String hymnFavoritesTable = 'hymn_favorites';

  // Storage buckets (see supabase/schema.sql for creation)
  static const String profilesBucket = 'profiles';
  static const String sermonsBucket = 'sermons';
  static const String eventsBucket = 'events';
  static const String testimoniesBucket = 'testimonies';
  static const String prayersBucket = 'prayers';
  static const String announcementsBucket = 'announcements';
}
