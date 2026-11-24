/// Model representing a member's notification alert preferences.
class NotificationPreferences {
  final bool membershipReminders;
  final bool paymentReminders;
  final bool workoutReminders;
  final bool classReminders;
  final bool gymAnnouncements;

  const NotificationPreferences({
    this.membershipReminders = true,
    this.paymentReminders = true,
    this.workoutReminders = true,
    this.classReminders = true,
    this.gymAnnouncements = true,
  });

  NotificationPreferences copyWith({
    bool? membershipReminders,
    bool? paymentReminders,
    bool? workoutReminders,
    bool? classReminders,
    bool? gymAnnouncements,
  }) {
    return NotificationPreferences(
      membershipReminders: membershipReminders ?? this.membershipReminders,
      paymentReminders: paymentReminders ?? this.paymentReminders,
      workoutReminders: workoutReminders ?? this.workoutReminders,
      classReminders: classReminders ?? this.classReminders,
      gymAnnouncements: gymAnnouncements ?? this.gymAnnouncements,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'membershipReminders': membershipReminders,
      'paymentReminders': paymentReminders,
      'workoutReminders': workoutReminders,
      'classReminders': classReminders,
      'gymAnnouncements': gymAnnouncements,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      membershipReminders: map['membershipReminders'] as bool? ?? true,
      paymentReminders: map['paymentReminders'] as bool? ?? true,
      workoutReminders: map['workoutReminders'] as bool? ?? true,
      classReminders: map['classReminders'] as bool? ?? true,
      gymAnnouncements: map['gymAnnouncements'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferences &&
          runtimeType == other.runtimeType &&
          membershipReminders == other.membershipReminders &&
          paymentReminders == other.paymentReminders &&
          workoutReminders == other.workoutReminders &&
          classReminders == other.classReminders &&
          gymAnnouncements == other.gymAnnouncements;

  @override
  int get hashCode =>
      membershipReminders.hashCode ^
      paymentReminders.hashCode ^
      workoutReminders.hashCode ^
      classReminders.hashCode ^
      gymAnnouncements.hashCode;
}
