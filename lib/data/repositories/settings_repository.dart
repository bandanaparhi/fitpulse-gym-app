import '../models/notification_preferences.dart';

/// Abstract contract for managing member application settings & preferences.
abstract class SettingsRepository {
  Future<NotificationPreferences> getNotificationPreferences();
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences preferences,
  );
}

/// Centralized Mock Implementation of SettingsRepository.
///
/// Easily replaceable by a Firestore or REST API implementation in production.
class MockSettingsRepository implements SettingsRepository {
  NotificationPreferences _preferences;
  final Duration latency;

  MockSettingsRepository({
    NotificationPreferences initialPreferences = const NotificationPreferences(
      membershipReminders: true,
      paymentReminders: true,
      workoutReminders: true,
      classReminders: true,
      gymAnnouncements: true,
    ),
    this.latency = const Duration(milliseconds: 100),
  }) : _preferences = initialPreferences;

  NotificationPreferences get preferences => _preferences;

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    return _preferences;
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    _preferences = preferences;
    return _preferences;
  }
}

/// In-memory mock implementation with customizable latency.
class InMemorySettingsRepository implements SettingsRepository {
  NotificationPreferences _preferences;

  InMemorySettingsRepository({
    NotificationPreferences initialPreferences = const NotificationPreferences(),
  }) : _preferences = initialPreferences;

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _preferences;
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _preferences = preferences;
    return _preferences;
  }
}
