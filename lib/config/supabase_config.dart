/// Environment-driven Supabase configuration for the FitPulse Gym Management app.
///
/// Pass the publishable key at build/run time via `--dart-define`:
/// ```bash
/// flutter run -d chrome \
///   --dart-define=SUPABASE_URL=https://tnaxqehjowbatqghbbuk.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=<your-publishable-key>
/// ```
///
/// Never place `service_role` keys, database passwords, or admin tokens in
/// client-side Flutter configuration.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tnaxqehjowbatqghbbuk.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_M23un-n6XteI8v2XBW59Ug__YDGPzDO',
  );

  /// True when both project URL and publishable key are configured.
  static bool get isConfigured =>
      url.trim().isNotEmpty && publishableKey.trim().isNotEmpty;

  // Storage bucket names
  static const String profileImagesBucket = 'profile-images';
  static const String progressImagesBucket = 'progress-images';
  static const String exerciseMediaBucket = 'exercise-media';
}
