import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client_service.dart';

/// Supabase Storage — replaces Django MEDIA uploads.
///
/// Buckets (public, see supabase/schema.sql):
/// profiles, sermons, events, testimonies, prayers, announcements
class SupabaseStorageService {
  SupabaseClient get _c => SupabaseClientService.client;

  /// Upload [file] to [bucket]/[path] and return the public URL.
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
    String? contentType,
  }) async {
    await _c.storage.from(bucket).upload(
          path,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );
    return _c.storage.from(bucket).getPublicUrl(path);
  }

  Future<String> uploadProfilePicture(String userId, File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return uploadFile(
      bucket: 'profiles',
      path: '$userId/avatar.$ext',
      file: file,
      contentType: 'image/$ext',
    );
  }

  Future<String> uploadSermonFile({
    required String sermonId,
    required String kind, // audio | video | thumbnail
    required File file,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    return uploadFile(
      bucket: 'sermons',
      path: '$sermonId/$kind.$ext',
      file: file,
    );
  }

  Future<String> uploadTestimonyFile({
    required String testimonyId,
    required String kind, // photo | video | thumbnail
    required File file,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    return uploadFile(
      bucket: 'testimonies',
      path: '$testimonyId/$kind.$ext',
      file: file,
    );
  }

  Future<String> uploadEventBanner(String eventId, File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return uploadFile(
      bucket: 'events',
      path: '$eventId/banner.$ext',
      file: file,
      contentType: 'image/$ext',
    );
  }

  /// Prayer images allow multiples — timestamp the filename.
  Future<String> uploadPrayerImage(String prayerId, File file) {
    final ext = file.path.split('.').last.toLowerCase();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return uploadFile(
      bucket: 'prayers',
      path: '$prayerId/$stamp.$ext',
      file: file,
      contentType: 'image/$ext',
    );
  }

  Future<void> removeFiles({
    required String bucket,
    required List<String> paths,
  }) async {
    await _c.storage.from(bucket).remove(paths);
  }

  /// Remove all avatar files for a user (any extension).
  Future<void> removeProfilePictures(String userId) async {
    final objects = await _c.storage.from('profiles').list(path: userId);
    final paths = objects
        .where((o) => o.name != null && o.name!.isNotEmpty)
        .map((o) => '$userId/${o.name}')
        .toList();
    if (paths.isNotEmpty) {
      await removeFiles(bucket: 'profiles', paths: paths);
    }
  }
}
