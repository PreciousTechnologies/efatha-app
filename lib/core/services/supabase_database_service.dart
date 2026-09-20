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

  /// Map a Supabase sermon row to the legacy keys the UI expects
  /// (Django used `pastor` as alias for `preacher`, int ids, etc).
  Map<String, dynamic> normalizeSermon(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['pastor'] ??= map['preacher'] ?? 'Unknown Pastor';
    map['preacher'] ??= map['pastor'];
    map['thumbnail_url'] ??= map['thumbnail'];
    map['audio_url'] ??= map['audio_file'];
    map['video_url'] ??= map['video_file'];
    map['views'] ??= 0;
    return map;
  }

  // Sermons (replaces ApiService.getSermons/uploadSermon/updateSermon/deleteSermon)
  Future<List<Map<String, dynamic>>> getSermons({
    String? category,
    String? pastor,
    String? topic,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    var q = _c.from(SupabaseConfig.sermonsTable).select('*');
    dynamic query = q;
    query = query.eq('is_active', true);
    if (category != null && category != 'all') {
      query = query.eq('category', category);
    }
    if (pastor != null && pastor.isNotEmpty) {
      query = query.eq('preacher', pastor);
    }
    if (topic != null && topic.isNotEmpty) {
      query = query.ilike('topics', '%$topic%');
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }
    final res = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (res as List)
        .map((e) => normalizeSermon(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> incrementSermonViews(String sermonId, int currentViews) async {
    await _c
        .from(SupabaseConfig.sermonsTable)
        .update({'views': currentViews + 1}).eq('id', sermonId);
  }

  // Events (replaces events_screen/event_detail/upload_event Django calls)
  Future<List<Map<String, dynamic>>> getEvents({int limit = 50}) async {
    final rows = await list(
      SupabaseConfig.eventsTable,
      limit: limit,
      orderBy: 'start_date',
      ascending: true,
    );
    return rows.map(normalizeEvent).toList();
  }

  /// Map a Supabase event row to legacy keys (`banner_image`, etc).
  Map<String, dynamic> normalizeEvent(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['banner_image'] ??= map['banner_url'];
    return map;
  }

  Future<List<Map<String, dynamic>>> getEventRegistrations(
    String eventId,
  ) async {
    final res = await _c
        .from(SupabaseConfig.eventRegistrationsTable)
        .select('*')
        .eq('event_id', eventId);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<Map<String, dynamic>?> getMyEventRegistration(
    String eventId,
    String userId,
  ) async {
    return await _c
        .from(SupabaseConfig.eventRegistrationsTable)
        .select()
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<void> registerForEvent(String eventId, String userId) async {
    await _c.from(SupabaseConfig.eventRegistrationsTable).insert({
      'event_id': eventId,
      'user_id': userId,
    });
  }

  Future<void> unregisterFromEvent(String registrationId) async {
    await _c
        .from(SupabaseConfig.eventRegistrationsTable)
        .delete()
        .eq('id', registrationId);
  }

  // Prayer requests (+ pray toggle, comments, images)
  Future<List<Map<String, dynamic>>> getPrayerRequests({
    int limit = 50,
    String? priority,
    String? userId,
  }) async {
    var q = _c.from(SupabaseConfig.prayerRequestsTable).select('*');
    dynamic query = q;
    if (priority != null && priority.isNotEmpty) {
      query = query.eq('priority', priority);
    }
    if (userId != null && userId.isNotEmpty) {
      query = query.eq('user_id', userId);
    }
    final res = await query
        .order('created_at', ascending: false)
        .range(0, limit - 1);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Enrich prayer rows with legacy UI keys: author name/avatar,
  /// prayer_count, is_praying (for [currentUid]), comment_count, images.
  /// Uses batched queries (no N+1).
  Future<List<Map<String, dynamic>>> enrichPrayers(
    List<Map<String, dynamic>> prayers, {
    String? currentUid,
  }) async {
    if (prayers.isEmpty) return prayers;
    final ids = prayers
        .map((p) => p['id']?.toString())
        .whereType<String>()
        .toList();
    final authorIds = prayers
        .map((p) => p['user_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    // Authors in one query.
    final Map<String, Map<String, dynamic>> authors = {};
    if (authorIds.isNotEmpty) {
      final res = await _c
          .from(SupabaseConfig.profilesTable)
          .select('id, first_name, last_name, profile_picture_url')
          .inFilter('id', authorIds);
      for (final a in (res as List)) {
        final m = Map<String, dynamic>.from(a as Map);
        authors[m['id'].toString()] = m;
      }
    }

    // Supports for these prayers in one query.
    final Map<String, int> supportCounts = {};
    final Set<String> minePraying = {};
    {
      final res = await _c
          .from(SupabaseConfig.prayerSupportsTable)
          .select('prayer_request_id, user_id')
          .inFilter('prayer_request_id', ids);
      for (final s in (res as List)) {
        final m = Map<String, dynamic>.from(s as Map);
        final pid = m['prayer_request_id'].toString();
        supportCounts[pid] = (supportCounts[pid] ?? 0) + 1;
        if (currentUid != null && m['user_id']?.toString() == currentUid) {
          minePraying.add(pid);
        }
      }
    }

    // Comment counts in one query.
    final Map<String, int> commentCounts = {};
    {
      final res = await _c
          .from(SupabaseConfig.prayerCommentsTable)
          .select('prayer_request_id')
          .inFilter('prayer_request_id', ids);
      for (final c in (res as List)) {
        final pid = (c as Map)['prayer_request_id'].toString();
        commentCounts[pid] = (commentCounts[pid] ?? 0) + 1;
      }
    }

    // Images in one query.
    final Map<String, List<Map<String, dynamic>>> imagesByPrayer = {};
    {
      final res = await _c
          .from(SupabaseConfig.prayerImagesTable)
          .select('prayer_request_id, image_url, caption')
          .inFilter('prayer_request_id', ids)
          .order('uploaded_at', ascending: true);
      for (final i in (res as List)) {
        final m = Map<String, dynamic>.from(i as Map);
        final pid = m['prayer_request_id'].toString();
        (imagesByPrayer[pid] ??= []).add({
          'image_url': m['image_url'],
          'caption': m['caption'],
        });
      }
    }

    return prayers.map((p) {
      final map = Map<String, dynamic>.from(p);
      final pid = map['id']?.toString() ?? '';
      final author = authors[map['user_id']?.toString()];
      final first = (author?['first_name']?.toString() ?? '').trim();
      final last = (author?['last_name']?.toString() ?? '').trim();
      final fullName = '$first $last'.trim();
      map['user_name'] = map['is_anonymous'] == true
          ? 'Anonymous'
          : (fullName.isEmpty ? 'Member' : fullName);
      map['user_profile_picture'] = author?['profile_picture_url'];
      map['prayer_count'] = supportCounts[pid] ?? 0;
      map['is_praying'] = minePraying.contains(pid);
      map['comment_count'] = commentCounts[pid] ?? 0;
      map['images'] = imagesByPrayer[pid] ?? [];
      return map;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getPrayerImages(String prayerId) async {
    final res = await _c
        .from(SupabaseConfig.prayerImagesTable)
        .select('image_url, caption')
        .eq('prayer_request_id', prayerId)
        .order('uploaded_at', ascending: true);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> getPrayerComments(
    String prayerId,
  ) async {
    final res = await _c
        .from(SupabaseConfig.prayerCommentsTable)
        .select('*')
        .eq('prayer_request_id', prayerId)
        .order('created_at', ascending: true);
    final comments = List<Map<String, dynamic>>.from(res as List);
    if (comments.isEmpty) return comments;

    // Attach author display info in one query.
    final authorIds = comments
        .map((c) => c['user_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();
    final Map<String, Map<String, dynamic>> authors = {};
    if (authorIds.isNotEmpty) {
      final ares = await _c
          .from(SupabaseConfig.profilesTable)
          .select('id, first_name, last_name, profile_picture_url')
          .inFilter('id', authorIds);
      for (final a in (ares as List)) {
        final m = Map<String, dynamic>.from(a as Map);
        authors[m['id'].toString()] = m;
      }
    }
    return comments.map((c) {
      final map = Map<String, dynamic>.from(c);
      final author = authors[map['user_id']?.toString()];
      final first = (author?['first_name']?.toString() ?? '').trim();
      final last = (author?['last_name']?.toString() ?? '').trim();
      final full = '$first $last'.trim();
      map['user_name'] = full.isEmpty ? 'Member' : full;
      map['user_profile_picture'] = author?['profile_picture_url'];
      final initials = full
          .split(' ')
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0])
          .join()
          .toUpperCase();
      map['user_initials'] = initials.isEmpty ? 'U' : initials;
      return map;
    }).toList();
  }

  Future<Map<String, dynamic>> addPrayerComment({
    required String prayerId,
    required String userId,
    required String content,
  }) async {
    return await _c
        .from(SupabaseConfig.prayerCommentsTable)
        .insert({
          'prayer_request_id': prayerId,
          'user_id': userId,
          'content': content,
        })
        .select()
        .single();
  }

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
  Future<List<Map<String, dynamic>>> getTestimonies({
    int limit = 50,
    String? type,
    String? userId,
    bool approvedOnly = true,
  }) async {
    var q = _c.from(SupabaseConfig.testimoniesTable).select('*');
    dynamic query = q;
    if (approvedOnly) {
      query = query.eq('is_approved', true);
    }
    if (type != null && type.isNotEmpty) {
      query = query.eq('testimony_type', type);
    }
    if (userId != null && userId.isNotEmpty) {
      query = query.eq('user_id', userId);
    }
    final res = await query
        .order('created_at', ascending: false)
        .range(0, limit - 1);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Enrich testimony rows with legacy UI keys: author name/avatar,
  /// praise_count, user_has_praised (for [currentUid]), prayer_request_title.
  Future<List<Map<String, dynamic>>> enrichTestimonies(
    List<Map<String, dynamic>> testimonies, {
    String? currentUid,
  }) async {
    if (testimonies.isEmpty) return testimonies;
    final ids = testimonies
        .map((t) => t['id']?.toString())
        .whereType<String>()
        .toList();
    final authorIds = testimonies
        .map((t) => t['user_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();
    final prayerIds = testimonies
        .map((t) => t['prayer_request_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    final Map<String, Map<String, dynamic>> authors = {};
    if (authorIds.isNotEmpty) {
      final res = await _c
          .from(SupabaseConfig.profilesTable)
          .select('id, first_name, last_name, profile_picture_url')
          .inFilter('id', authorIds);
      for (final a in (res as List)) {
        final m = Map<String, dynamic>.from(a as Map);
        authors[m['id'].toString()] = m;
      }
    }

    final Map<String, int> praiseCounts = {};
    final Set<String> minePraised = {};
    {
      final res = await _c
          .from(SupabaseConfig.testimonyPraisesTable)
          .select('testimony_id, user_id')
          .inFilter('testimony_id', ids);
      for (final s in (res as List)) {
        final m = Map<String, dynamic>.from(s as Map);
        final tid = m['testimony_id'].toString();
        praiseCounts[tid] = (praiseCounts[tid] ?? 0) + 1;
        if (currentUid != null && m['user_id']?.toString() == currentUid) {
          minePraised.add(tid);
        }
      }
    }

    final Map<String, String> prayerTitles = {};
    if (prayerIds.isNotEmpty) {
      final res = await _c
          .from(SupabaseConfig.prayerRequestsTable)
          .select('id, title')
          .inFilter('id', prayerIds);
      for (final p in (res as List)) {
        final m = Map<String, dynamic>.from(p as Map);
        prayerTitles[m['id'].toString()] = m['title']?.toString() ?? '';
      }
    }

    return testimonies.map((t) {
      final map = Map<String, dynamic>.from(t);
      final tid = map['id']?.toString() ?? '';
      final author = authors[map['user_id']?.toString()];
      final first = (author?['first_name']?.toString() ?? '').trim();
      final last = (author?['last_name']?.toString() ?? '').trim();
      final fullName = '$first $last'.trim();
      map['user_name'] = map['is_anonymous'] == true
          ? 'Anonymous'
          : (fullName.isEmpty ? 'A member' : fullName);
      map['user_profile_picture'] = author?['profile_picture_url'];
      map['praise_count'] = praiseCounts[tid] ?? 0;
      map['user_has_praised'] = minePraised.contains(tid);
      if (map['prayer_request_id'] != null) {
        map['prayer_request_title'] =
            prayerTitles[map['prayer_request_id'].toString()];
      }
      return map;
    }).toList();
  }

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

  // Announcements (no in-app UI yet — backend-ready for when one is built)
  Future<List<Map<String, dynamic>>> getAnnouncements({
    int limit = 20,
  }) async {
    final res = await _c
        .from(SupabaseConfig.announcementsTable)
        .select('*')
        .eq('is_published', true)
        .order('publish_date', ascending: false)
        .range(0, limit - 1);
    final rows = List<Map<String, dynamic>>.from(res as List);
    return filterActiveAnnouncements(rows, DateTime.now());
  }

  /// Drop expired announcements (pure — unit tested).
  static List<Map<String, dynamic>> filterActiveAnnouncements(
    List<Map<String, dynamic>> rows,
    DateTime now,
  ) {
    return rows.where((a) {
      final expiry = DateTime.tryParse(a['expiry_date']?.toString() ?? '');
      return expiry == null || expiry.isAfter(now);
    }).toList();
  }

  // Giving (Pesapal flow stays, but record lives in Supabase now)
  Future<Map<String, dynamic>> createGiving(Map<String, dynamic> data) =>
      insert(SupabaseConfig.givingsTable, data);

  Future<Map<String, dynamic>> createPaymentTransaction(
    Map<String, dynamic> data,
  ) =>
      insert(SupabaseConfig.paymentTransactionsTable, data);

  /// My giving history (newest first). Pesapal records land here on success.
  Future<List<Map<String, dynamic>>> getMyGivings({int limit = 100}) async {
    final uid = SupabaseClientService.client.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _c
        .from(SupabaseConfig.givingsTable)
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .range(0, limit - 1);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Map donations-screen UI categories to DB giving_type values.
  /// DB vocabulary: tithe/offering/special/pledge/mission/building/other.
  static List<String>? givingTypesForUiCategory(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return null;
      case 'tithe':
        return ['tithe'];
      case 'charity':
        return ['special'];
      case 'gratitude':
        return ['offering'];
      case 'gospel':
        return ['mission'];
      case 'firstfruits':
        return ['pledge'];
      case 'construction':
        return ['building'];
      default:
        return ['other'];
    }
  }

  /// Map flow-screen UI category to a single DB giving_type.
  static String givingTypeForUiCategory(String category) =>
      givingTypesForUiCategory(category)?.first ?? 'other';
}
