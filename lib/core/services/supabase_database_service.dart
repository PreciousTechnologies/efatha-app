import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client_service.dart';
import '../config/supabase_config.dart';

/// Generic Supabase data layer — replaces Django REST endpoints.
///
/// Django -> Supabase table mapping:
/// church/sermons/            -> sermons
/// church/events/             -> events
/// church/event-registrations -> event_registrations
/// church/prayer-requests/    -> prayer_requests (+ supports/images/comments)
/// church/testimonies/        -> testimonies (+ praises)
/// church/giving/             -> givings (+ payment_transactions)
/// church/announcements/      -> announcements
/// church/live-streams|chat   -> live_streams + live_chat_messages
/// bible/*, hymns/*           -> bible_favorites/highlights, hymn_favorites
class SupabaseDatabaseService {
  SupabaseClient get _c => SupabaseClientService.client;

  // ---------------- generic helpers ----------------

  Future<List<Map<String, dynamic>>> list(
    String table, {
    String orderBy = 'created_at',
    bool ascending = false,
    int limit = 20,
    int offset = 0,
    Map<String, dynamic> filters = const {},
    String select = '*',
  }) async {
    var query = _c.from(table).select(select);
    // NOTE: supabase_flutter v2 uses a builder API; keep simple ordering here
    // and apply filters via .eq below through PostgrestFilterBuilder.
    dynamic q = query;
    filters.forEach((key, value) {
      q = q.eq(key, value);
    });
    final res = await q
        .order(orderBy, ascending: ascending)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<Map<String, dynamic>?> getById(String table, dynamic id) async {
    return await _c.from(table).select().eq('id', id).maybeSingle();
  }

  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    return await _c.from(table).insert(data).select().single();
  }

  Future<Map<String, dynamic>> update(
    String table,
    dynamic id,
    Map<String, dynamic> data,
  ) async {
    return await _c.from(table).update(data).eq('id', id).select().single();
  }

  Future<void> delete(String table, dynamic id) async {
    await _c.from(table).delete().eq('id', id);
  }

  // ---------------- domain shortcuts ----------------

  // Sermons (replaces ApiService.getSermons/uploadSermon/updateSermon/deleteSermon)
  Future<List<Map<String, dynamic>>> getSermons({
    String? category,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    var q = _c.from(SupabaseConfig.sermonsTable).select('*');
    dynamic query = q;
    if (category != null && category != 'all') {
      query = query.eq('category', category);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }
    final res = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> incrementSermonViews(String sermonId, int currentViews) async {
    await _c
        .from(SupabaseConfig.sermonsTable)
        .update({'views': currentViews + 1}).eq('id', sermonId);
  }

  // Events
  Future<List<Map<String, dynamic>>> getEvents({int limit = 50}) =>
      list(SupabaseConfig.eventsTable, limit: limit, orderBy: 'start_date');

  // Prayer requests (+ pray toggle, comments)
  Future<List<Map<String, dynamic>>> getPrayerRequests({int limit = 20}) =>
      list(SupabaseConfig.prayerRequestsTable, limit: limit);

  Future<void> togglePray(String prayerId, String userId) async {
    final existing = await _c
        .from(SupabaseConfig.prayerSupportsTable)
        .select()
        .eq('prayer_request_id', prayerId)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing == null) {
      await _c.from(SupabaseConfig.prayerSupportsTable).insert({
        'prayer_request_id': prayerId,
        'user_id': userId,
      });
    } else {
      await _c
          .from(SupabaseConfig.prayerSupportsTable)
          .delete()
          .eq('id', existing['id']);
    }
  }

  // Testimonies (+ praise toggle)
  Future<List<Map<String, dynamic>>> getTestimonies({int limit = 20}) =>
      list(SupabaseConfig.testimoniesTable, limit: limit);

  Future<void> togglePraise(String testimonyId, String userId) async {
    final existing = await _c
        .from(SupabaseConfig.testimonyPraisesTable)
        .select()
        .eq('testimony_id', testimonyId)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing == null) {
      await _c.from(SupabaseConfig.testimonyPraisesTable).insert({
        'testimony_id': testimonyId,
        'user_id': userId,
      });
    } else {
      await _c
          .from(SupabaseConfig.testimonyPraisesTable)
          .delete()
          .eq('id', existing['id']);
    }
  }

  // Live streams + chat (with realtime available via channel API in UI)
  Future<Map<String, dynamic>?> getCurrentLiveStream() async {
    return await _c
        .from(SupabaseConfig.liveStreamsTable)
        .select()
        .eq('status', 'live')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  // Giving (Pesapal flow stays, but record lives in Supabase now)
  Future<Map<String, dynamic>> createGiving(Map<String, dynamic> data) =>
      insert(SupabaseConfig.givingsTable, data);
}
