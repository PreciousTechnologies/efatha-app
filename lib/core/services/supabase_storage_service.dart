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

  Future<void> removeFiles({
    required String bucket,
    required List<String> paths,
  }) async {
    await _c.storage.from(bucket).remove(paths);
  }
}
