import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../core/services/supabase_service.dart';

/// Handles authenticated uploads and private signed URL retrieval via
/// Supabase Storage (`profile-images`, `progress-images`, `exercise-media`).
class SupabaseStorageService {
  const SupabaseStorageService();

  SupabaseClient get _client => SupabaseService.client;

  /// Uploads or replaces a member's profile photo inside `profile-images/<userId>/avatar.<ext>`
  /// and saves the storage path on `profiles.profile_image`.
  Future<String> uploadProfileImage({
    required String userId,
    required Uint8List bytes,
    String fileExtension = 'jpg',
  }) async {
    try {
      final safeExt = fileExtension.toLowerCase().replaceAll('.', '');
      final mime = safeExt == 'png'
          ? 'image/png'
          : (safeExt == 'webp' ? 'image/webp' : 'image/jpeg');
      final storagePath = '$userId/avatar.$safeExt';

      await _client.storage.from(SupabaseConfig.profileImagesBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: true),
          );

      await _client
          .from('profiles')
          .update({'profile_image': storagePath}).eq('id', userId);

      return await getSignedUrl(
        bucket: SupabaseConfig.profileImagesBucket,
        path: storagePath,
      );
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  /// Uploads a strictly private member progress photo to `progress-images/<userId>/<fileName>`.
  /// Never makes private progress photos publicly accessible.
  Future<String> uploadProgressImage({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
      final ext = cleanName.split('.').last.toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

      await _client
          .storage
          .from(SupabaseConfig.progressImagesBucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );

      return storagePath;
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  /// Generates a time-limited signed URL for private buckets.
  Future<String> getSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 3600,
  }) async {
    try {
      return await _client.storage
          .from(bucket)
          .createSignedUrl(path, expiresInSeconds);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }
}
