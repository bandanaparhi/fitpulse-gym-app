import 'workout_session.dart';

/// Single day slot in a personalized 7-day workout plan.
class WorkoutPlanDay {
  final int weekdayIndex; // 1 = Monday ... 7 = Sunday
  final String dayName;
  final bool isRestDay;
  final String sessionLabel;
  final String focusSummary;
  final String? sessionId;
  final int estimatedMinutes;

  const WorkoutPlanDay({
    required this.weekdayIndex,
    required this.dayName,
    required this.isRestDay,
    required this.sessionLabel,
    required this.focusSummary,
    this.sessionId,
    this.estimatedMinutes = 0,
  });

  WorkoutPlanDay copyWith({
    int? weekdayIndex,
    String? dayName,
    bool? isRestDay,
    String? sessionLabel,
    String? focusSummary,
    String? sessionId,
    int? estimatedMinutes,
  }) {
    return WorkoutPlanDay(
      weekdayIndex: weekdayIndex ?? this.weekdayIndex,
      dayName: dayName ?? this.dayName,
      isRestDay: isRestDay ?? this.isRestDay,
      sessionLabel: sessionLabel ?? this.sessionLabel,
      focusSummary: focusSummary ?? this.focusSummary,
      sessionId: sessionId ?? this.sessionId,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'weekdayIndex': weekdayIndex,
        'dayName': dayName,
        'isRestDay': isRestDay,
        'sessionLabel': sessionLabel,
        'focusSummary': focusSummary,
        'sessionId': sessionId,
        'estimatedMinutes': estimatedMinutes,
      };

  factory WorkoutPlanDay.fromJson(Map<String, dynamic> json) => WorkoutPlanDay(
        weekdayIndex: json['weekdayIndex'] as int? ?? 1,
        dayName: json['dayName'] as String? ?? 'Monday',
        isRestDay: json['isRestDay'] as bool? ?? false,
        sessionLabel: json['sessionLabel'] as String? ?? '',
        focusSummary: json['focusSummary'] as String? ?? '',
        sessionId: json['sessionId'] as String?,
        estimatedMinutes: json['estimatedMinutes'] as int? ?? 0,
      );
}

/// Personalized weekly workout plan linked to a member's fitness profile.
class WorkoutPlan {
  final String id;
  final String memberId;
  final String title;
  final String splitSummary;
  final String goal;
  final String level;
  final String location;
  final int trainingDaysPerWeek;
  final DateTime createdAt;
  final List<WorkoutPlanDay> weekSchedule;
  final List<WorkoutSession> sessions;
  final String progressionGuidance;
  final String recoveryGuidance;
  final bool isSampleData;

  const WorkoutPlan({
    required this.id,
    required this.memberId,
    required this.title,
    required this.splitSummary,
    required this.goal,
    required this.level,
    required this.location,
    required this.trainingDaysPerWeek,
    required this.createdAt,
    required this.weekSchedule,
    required this.sessions,
    required this.progressionGuidance,
    required this.recoveryGuidance,
    this.isSampleData = false,
  });

  WorkoutSession? sessionById(String? id) {
    if (id == null) return null;
    for (final s in sessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  WorkoutPlanDay dayForWeekday(int weekday) {
    return weekSchedule.firstWhere(
      (d) => d.weekdayIndex == weekday,
      orElse: () => weekSchedule.first,
    );
  }

  WorkoutPlan copyWith({
    String? id,
    String? memberId,
    String? title,
    String? splitSummary,
    String? goal,
    String? level,
    String? location,
    int? trainingDaysPerWeek,
    DateTime? createdAt,
    List<WorkoutPlanDay>? weekSchedule,
    List<WorkoutSession>? sessions,
    String? progressionGuidance,
    String? recoveryGuidance,
    bool? isSampleData,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      title: title ?? this.title,
      splitSummary: splitSummary ?? this.splitSummary,
      goal: goal ?? this.goal,
      level: level ?? this.level,
      location: location ?? this.location,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      createdAt: createdAt ?? this.createdAt,
      weekSchedule: weekSchedule ?? this.weekSchedule,
      sessions: sessions ?? this.sessions,
      progressionGuidance: progressionGuidance ?? this.progressionGuidance,
      recoveryGuidance: recoveryGuidance ?? this.recoveryGuidance,
      isSampleData: isSampleData ?? this.isSampleData,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'title': title,
        'splitSummary': splitSummary,
        'goal': goal,
        'level': level,
        'location': location,
        'trainingDaysPerWeek': trainingDaysPerWeek,
        'createdAt': createdAt.toIso8601String(),
        'weekSchedule': weekSchedule.map((d) => d.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'progressionGuidance': progressionGuidance,
        'recoveryGuidance': recoveryGuidance,
        'isSampleData': isSampleData,
      };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
        id: json['id'] as String? ?? '',
        memberId: json['memberId'] as String? ?? 'GM-1024',
        title: json['title'] as String? ?? '',
        splitSummary: json['splitSummary'] as String? ?? '',
        goal: json['goal'] as String? ?? 'General Fitness',
        level: json['level'] as String? ?? 'Beginner',
        location: json['location'] as String? ?? 'Gym',
        trainingDaysPerWeek: json['trainingDaysPerWeek'] as int? ?? 3,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        weekSchedule: (json['weekSchedule'] as List? ?? const [])
            .map((e) => WorkoutPlanDay.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        sessions: (json['sessions'] as List? ?? const [])
            .map((e) => WorkoutSession.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        progressionGuidance: json['progressionGuidance'] as String? ?? '',
        recoveryGuidance: json['recoveryGuidance'] as String? ?? '',
        isSampleData: json['isSampleData'] as bool? ?? false,
      );
}
