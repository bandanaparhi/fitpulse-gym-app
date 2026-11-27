import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

/// Centralized Supabase initialization, client access, and safe user-facing
/// exception translation.
class SupabaseService {
  SupabaseService._();

  static bool _isInitialized = false;
  static String? _lastInitError;

  static bool get isInitialized => _isInitialized;
  static String? get lastInitError => _lastInitError;

  /// True when Supabase credentials are configured and client initialization succeeded.
  static bool get isReady => SupabaseConfig.isConfigured && _isInitialized;

  /// Safe initialization for app startup.
  ///
  /// When `SUPABASE_PUBLISHABLE_KEY` is omitted (e.g. automated tests or local
  /// preview without live keys), initialization skips gracefully so repositories
  /// fall back cleanly to centralized mock/local storage.
  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      if (kDebugMode) {
        debugPrint(
          'ℹ️ SupabaseService: SUPABASE_PUBLISHABLE_KEY not supplied via '
          '--dart-define. Running in local/mock repository fallback mode.',
        );
      }
      _isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      _isInitialized = true;
      _lastInitError = null;
    } catch (e) {
      _isInitialized = false;
      _lastInitError = SupabaseErrorMapper.toUserMessage(e);
      if (kDebugMode) {
        debugPrint('⚠️ SupabaseService initialization failed: $e');
      }
    }
  }

  /// Returns the initialized [SupabaseClient], throwing a descriptive
  /// [StateError] if called before initialization.
  static SupabaseClient get client {
    if (!isReady) {
      throw StateError(
        'Supabase client is not initialized. Provide SUPABASE_PUBLISHABLE_KEY '
        'via --dart-define and call SupabaseService.initialize().',
      );
    }
    return Supabase.instance.client;
  }

  /// Nullable accessor safe for fallback checks.
  static SupabaseClient? get clientOrNull =>
      isReady ? Supabase.instance.client : null;
}

/// Converts raw Supabase, Postgres, Storage, Auth, and network exceptions into
/// safe, understandable user messages without exposing SQL or backend details.
class SupabaseErrorMapper {
  SupabaseErrorMapper._();

  static String toUserMessage(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials')) {
        return 'Incorrect email or password. Please verify your credentials and try again.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Please verify your email address using the confirmation link sent to your inbox before signing in.';
      }
      if (msg.contains('user already registered') ||
          msg.contains('already been registered')) {
        return 'An account with this email already exists. Try signing in instead.';
      }
      if (msg.contains('weak password') || msg.contains('password should be')) {
        return 'Your password is too weak. Please choose a stronger password.';
      }
      if (msg.contains('jwt expired') ||
          msg.contains('refresh_token') ||
          msg.contains('session_not_found')) {
        return 'Your session has expired. Please sign in again.';
      }
      if (msg.contains('rate limit') || error.statusCode == '429') {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      return 'Authentication error. Please check your details and try again.';
    }

    if (error is PostgrestException) {
      final code = error.code ?? '';
      if (code == '42501') {
        return 'You do not have permission to perform this action.';
      }
      if (code == '23505') {
        return 'This record already exists.';
      }
      if (code == '23503') {
        return 'Related record was not found. Please refresh and try again.';
      }
      if (code == 'PGRST116') {
        return 'Requested record could not be found.';
      }
      if (code == 'PGRST301' || code == 'PGRST302') {
        return 'Your session has expired. Please sign in again.';
      }
      return 'Unable to complete the database request right now. Please try again.';
    }

    if (error is StorageException) {
      final status = error.statusCode ?? '';
      if (status == '401' || status == '403') {
        return 'You do not have permission to access or upload this file.';
      }
      if (status == '413') {
        return 'The selected file is too large. Please choose a smaller image.';
      }
      return 'Unable to upload or load the file. Please check your connection and try again.';
    }

    if (error is TimeoutException) {
      return 'The server took too long to respond. Please check your connection and try again.';
    }

    final raw = error.toString().toLowerCase();
    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('network is unreachable') ||
        raw.contains('clientexception') ||
        raw.contains('xmlhttprequest error')) {
      return 'No internet connection or network error. Please check your connection and try again.';
    }

    return 'Something went wrong while communicating with the server. Please try again.';
  }
}
