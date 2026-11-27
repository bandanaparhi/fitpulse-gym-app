/// Logged set performance during a workout session.
class SetLog {
  final int setNumber;
  final int repsCompleted;
  final double? weightKg;
  final bool completed;
  final bool skipped;
  final DateTime loggedAt;

  const SetLog({
    required this.setNumber,
    required this.repsCompleted,
    this.weightKg,
    this.completed = false,
    this.skipped = false,
    required this.loggedAt,
  });

  double get volumeKg => completed ? (weightKg ?? 0) * repsCompleted : 0;

  SetLog copyWith({
    int? setNumber,
    int? repsCompleted,
    double? weightKg,
    bool clearWeight = false,
    bool? completed,
    bool? skipped,
    DateTime? loggedAt,
  }) {
    return SetLog(
      setNumber: setNumber ?? this.setNumber,
      repsCompleted: repsCompleted ?? this.repsCompleted,
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      completed: completed ?? this.completed,
      skipped: skipped ?? this.skipped,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'setNumber': setNumber,
        'repsCompleted': repsCompleted,
        'weightKg': weightKg,
        'completed': completed,
        'skipped': skipped,
        'loggedAt': loggedAt.toIso8601String(),
      };

  factory SetLog.fromJson(Map<String, dynamic> json) => SetLog(
        setNumber: json['setNumber'] as int? ?? 1,
        repsCompleted: json['repsCompleted'] as int? ?? 0,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        completed: json['completed'] as bool? ?? false,
        skipped: json['skipped'] as bool? ?? false,
        loggedAt: json['loggedAt'] != null
            ? DateTime.tryParse(json['loggedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Logged performance for a single exercise within a workout.
class ExerciseLog {
  final String exerciseId;
  final String exerciseName;
  final String targetMuscles;
  final List<SetLog> sets;
  final bool skipped;
  final String? replacedFromName;
  final String? notes;

  const ExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    this.targetMuscles = '',
    required this.sets,
    this.skipped = false,
    this.replacedFromName,
    this.notes,
  });

  bool get isFullyCompleted =>
      !skipped && sets.isNotEmpty && sets.every((s) => s.completed);

  int get completedSetsCount => sets.where((s) => s.completed).length;

  double get totalVolumeKg =>
      sets.fold(0.0, (sum, s) => sum + s.volumeKg);

  double? get topWeightKg {
    double? best;
    for (final s in sets) {
      if (s.completed && s.weightKg != null) {
        if (best == null || s.weightKg! > best) best = s.weightKg;
      }
    }
    return best;
  }

  int get maxRepsCompleted {
    int best = 0;
    for (final s in sets) {
      if (s.completed && s.repsCompleted > best) {
        best = s.repsCompleted;
      }
    }
    return best;
  }

  ExerciseLog copyWith({
    String? exerciseId,
    String? exerciseName,
    String? targetMuscles,
    List<SetLog>? sets,
    bool? skipped,
    String? replacedFromName,
    String? notes,
  }) {
    return ExerciseLog(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      sets: sets ?? this.sets,
      skipped: skipped ?? this.skipped,
      replacedFromName: replacedFromName ?? this.replacedFromName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'targetMuscles': targetMuscles,
        'sets': sets.map((s) => s.toJson()).toList(),
        'skipped': skipped,
        'replacedFromName': replacedFromName,
        'notes': notes,
      };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
        exerciseId: json['exerciseId'] as String? ?? '',
        exerciseName: json['exerciseName'] as String? ?? '',
        targetMuscles: json['targetMuscles'] as String? ?? '',
        sets: (json['sets'] as List? ?? const [])
            .map((e) => SetLog.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        skipped: json['skipped'] as bool? ?? false,
        replacedFromName: json['replacedFromName'] as String?,
        notes: json['notes'] as String?,
      );
}

/// Complete record of a logged personalized workout session.
class WorkoutLog {
  final String id;
  final String memberId;
  final String sessionId;
  final String sessionTitle;
  final String focus;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationMinutes;
  final List<ExerciseLog> exerciseLogs;
  final int perceivedDifficulty; // 1–10
  final String? generalNotes;
  final bool isCompleted;
  final bool stoppedDueToDiscomfort;
  final String? discomfortNote;
  final bool isSampleData;

  const WorkoutLog({
    required this.id,
    required this.memberId,
    required this.sessionId,
    required this.sessionTitle,
    required this.focus,
    required this.startedAt,
    this.completedAt,
    required this.durationMinutes,
    required this.exerciseLogs,
    this.perceivedDifficulty = 6,
    this.generalNotes,
    this.isCompleted = true,
    this.stoppedDueToDiscomfort = false,
    this.discomfortNote,
    this.isSampleData = false,
  });

  double get totalVolumeKg =>
      exerciseLogs.fold(0.0, (sum, ex) => sum + ex.totalVolumeKg);

  int get completedSets =>
      exerciseLogs.fold(0, (sum, ex) => sum + ex.completedSetsCount);

  int get completedExercisesCount =>
      exerciseLogs.where((ex) => ex.completedSetsCount > 0).length;

  WorkoutLog copyWith({
    String? id,
    String? memberId,
    String? sessionId,
    String? sessionTitle,
    String? focus,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationMinutes,
    List<ExerciseLog>? exerciseLogs,
    int? perceivedDifficulty,
    String? generalNotes,
    bool? isCompleted,
    bool? stoppedDueToDiscomfort,
    String? discomfortNote,
    bool? isSampleData,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      sessionId: sessionId ?? this.sessionId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      focus: focus ?? this.focus,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      perceivedDifficulty: perceivedDifficulty ?? this.perceivedDifficulty,
      generalNotes: generalNotes ?? this.generalNotes,
      isCompleted: isCompleted ?? this.isCompleted,
      stoppedDueToDiscomfort:
          stoppedDueToDiscomfort ?? this.stoppedDueToDiscomfort,
      discomfortNote: discomfortNote ?? this.discomfortNote,
      isSampleData: isSampleData ?? this.isSampleData,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'sessionId': sessionId,
        'sessionTitle': sessionTitle,
        'focus': focus,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'durationMinutes': durationMinutes,
        'exerciseLogs': exerciseLogs.map((e) => e.toJson()).toList(),
        'perceivedDifficulty': perceivedDifficulty,
        'generalNotes': generalNotes,
        'isCompleted': isCompleted,
        'stoppedDueToDiscomfort': stoppedDueToDiscomfort,
        'discomfortNote': discomfortNote,
        'isSampleData': isSampleData,
      };

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => WorkoutLog(
        id: json['id'] as String? ?? '',
        memberId: json['memberId'] as String? ?? 'GM-1024',
        sessionId: json['sessionId'] as String? ?? '',
        sessionTitle: json['sessionTitle'] as String? ?? '',
        focus: json['focus'] as String? ?? '',
        startedAt: json['startedAt'] != null
            ? DateTime.tryParse(json['startedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
        durationMinutes: json['durationMinutes'] as int? ?? 45,
        exerciseLogs: (json['exerciseLogs'] as List? ?? const [])
            .map((e) => ExerciseLog.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        perceivedDifficulty: json['perceivedDifficulty'] as int? ?? 6,
        generalNotes: json['generalNotes'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? true,
        stoppedDueToDiscomfort:
            json['stoppedDueToDiscomfort'] as bool? ?? false,
        discomfortNote: json['discomfortNote'] as String?,
        isSampleData: json['isSampleData'] as bool? ?? false,
      );
}
