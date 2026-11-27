/// In-app notification for classes, memberships, payments, and workout updates.
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'membership', 'class', 'payment', 'workout', 'diet', 'trainer', 'announcement'
  final String? actionRoute;
  final String? actionLabel;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.actionRoute,
    this.actionLabel,
  });

  String get effectiveRoute {
    if (actionRoute != null && actionRoute!.isNotEmpty) {
      return actionRoute!;
    }
    switch (type.toLowerCase()) {
      case 'membership':
        return '/membership';
      case 'payment':
        return '/payments';
      case 'workout':
        return '/workouts';
      case 'class':
        return '/classes/bookings';
      case 'trainer':
        return '/trainer';
      case 'diet':
        return '/diet-plan';
      case 'water':
        return '/progress';
      case 'progress':
        return '/progress';
      case 'announcement':
        return '/announcements';
      default:
        return '/dashboard';
    }
  }

  String get effectiveActionLabel {
    if (actionLabel != null && actionLabel!.isNotEmpty) {
      return actionLabel!;
    }
    switch (type.toLowerCase()) {
      case 'membership':
        return 'View Membership';
      case 'payment':
        return 'View Receipt';
      case 'workout':
        return 'View Workout';
      case 'class':
        return 'View Booking';
      case 'trainer':
        return 'View Coach';
      case 'diet':
        return 'View Diet Plan';
      case 'water':
        return 'Log Water Intake';
      case 'progress':
        return 'View Progress';
      case 'announcement':
        return 'Read Notice';
      default:
        return 'View Details';
    }
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    String? actionRoute,
    String? actionLabel,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      actionRoute: actionRoute ?? this.actionRoute,
      actionLabel: actionLabel ?? this.actionLabel,
    );
  }
}
