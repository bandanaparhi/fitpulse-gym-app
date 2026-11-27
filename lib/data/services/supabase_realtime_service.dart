import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

/// Manages scoped Supabase Realtime subscriptions for live gym notifications,
/// membership updates, attendance check-ins, and trainer messages.
///
/// Call [dispose] when the owning provider or controller is disposed so
/// WebSocket channels do not leak.
class SupabaseRealtimeService {
  RealtimeChannel? _channel;

  bool get isSubscribed => _channel != null;

  void subscribeToMemberUpdates({
    required String userId,
    VoidCallback? onNotificationsChanged,
    VoidCallback? onMembershipChanged,
    VoidCallback? onAttendanceChanged,
    VoidCallback? onTrainerMessagesChanged,
  }) {
    final client = SupabaseService.clientOrNull;
    if (client == null || userId.isEmpty) return;

    dispose();

    final channel = client.channel('fitpulse-member-$userId');

    if (onNotificationsChanged != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        callback: (_) => onNotificationsChanged(),
      );
    }

    if (onMembershipChanged != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'memberships',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) => onMembershipChanged(),
      );
    }

    if (onAttendanceChanged != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'attendance',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) => onAttendanceChanged(),
      );
    }

    if (onTrainerMessagesChanged != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'trainer_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) => onTrainerMessagesChanged(),
      );
    }

    _channel = channel..subscribe();
  }

  Future<void> dispose() async {
    final ch = _channel;
    _channel = null;
    final client = SupabaseService.clientOrNull;
    if (ch != null && client != null) {
      await client.removeChannel(ch);
    }
  }
}
