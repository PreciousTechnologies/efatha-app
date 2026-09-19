/// Supabase Configuration for Efatha Church App
///
/// 1. Create a project at https://supabase.com
/// 2. Copy Project URL + anon public key from Settings > API
/// 3. Paste below (or use --dart-define, see below).
///
/// Recommended (secure): pass at run time so keys are NOT committed:
///   flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
///
/// Fallback: edit the defaults below for local dev only.
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT-REF.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR-SUPABASE-ANON-KEY',
  );

  static bool get isConfigured =>
      !supabaseUrl.contains('YOUR-PROJECT-REF') &&
      !supabaseAnonKey.contains('YOUR-SUPABASE');

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
