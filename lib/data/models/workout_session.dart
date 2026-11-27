/// Individual set prescription within a workout exercise.
class SetSpec {
  final int setNumber;
  final int targetReps;
  final String? repRangeLabel; // e.g. '8–10', '10–12', '30–45 sec'
  final int? durationSeconds;
  final double? targetWeightKg;
  final String? notes;

  const SetSpec({
    required this.setNumber,
    required this.targetReps,
    this.repRangeLabel,
    this.durationSeconds,
    this.targetWeightKg,
    this.notes,
  });

  SetSpec copyWith({
    int? setNumber,
    int? targetReps,
    String? repRangeLabel,
    int? durationSeconds,
    double? targetWeightKg,
    bool clearWeight = false,
    String? notes,
  }) {
    return SetSpec(
      setNumber: setNumber ?? this.setNumber,
      targetReps: targetReps ?? this.targetReps,
      repRangeLabel: repRangeLabel ?? this.repRangeLabel,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      targetWeightKg: clearWeight ? null : (targetWeightKg ?? this.targetWeightKg),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'setNumber': setNumber,
        'targetReps': targetReps,
        'repRangeLabel': repRangeLabel,
        'durationSeconds': durationSeconds,
        'targetWeightKg': targetWeightKg,
        'notes': notes,
      };

  factory SetSpec.fromJson(Map<String, dynamic> json) => SetSpec(
        setNumber: json['setNumber'] as int? ?? 1,
        targetReps: json['targetReps'] as int? ?? 10,
        repRangeLabel: json['repRangeLabel'] as String?,
        durationSeconds: json['durationSeconds'] as int?,
        targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );
}

/// Complete exercise entry with form instructions, safety cues, and alternatives.
class ExerciseDetail {
  final String id;
  final String name;
  final String targetMuscles;
  final String equipment; // Primary equipment required
  final String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  final String category; // 'Compound', 'Isolation', 'Machine', 'Bodyweight', 'Cardio', 'Core', 'Power', 'Mobility'
  final List<String> instructions;
  final List<String> commonMistakes;
  final String easierVariation;
  final String harderVariation;
  final String? alternativeExerciseId;
  final String? alternativeExerciseName;
  final int restSeconds;
  final List<SetSpec> sets;
  final String? coachingCue;
  final bool requiresSupervisionNote;

  const ExerciseDetail({
    required this.id,
    required this.name,
    required this.targetMuscles,
    required this.equipment,
    required this.difficulty,
    required this.category,
    required this.instructions,
    required this.commonMistakes,
    required this.easierVariation,
    required this.harderVariation,
    this.alternativeExerciseId,
    this.alternativeExerciseName,
    required this.restSeconds,
    required this.sets,
    this.coachingCue,
    this.requiresSupervisionNote = false,
  });

  String get prescriptionSummary {
    if (sets.isEmpty) return '1 set';
    final first = sets.first;
    if (first.repRangeLabel != null && first.repRangeLabel!.isNotEmpty) {
      return '${sets.length} × ${first.repRangeLabel}';
    }
    if (first.durationSeconds != null && first.durationSeconds! > 0) {
      final mins = first.durationSeconds! >= 60 ? '${first.durationSeconds! ~/ 60} min' : '${first.durationSeconds} sec';
      return '${sets.length} × $mins';
    }
    return '${sets.length} × ${first.targetReps} reps';
  }

  ExerciseDetail copyWith({
    String? id,
    String? name,
    String? targetMuscles,
    String? equipment,
    String? difficulty,
    String? category,
    List<String>? instructions,
    List<String>? commonMistakes,
    String? easierVariation,
    String? harderVariation,
    String? alternativeExerciseId,
    String? alternativeExerciseName,
    int? restSeconds,
    List<SetSpec>? sets,
    String? coachingCue,
    bool? requiresSupervisionNote,
  }) {
    return ExerciseDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      instructions: instructions ?? this.instructions,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      easierVariation: easierVariation ?? this.easierVariation,
      harderVariation: harderVariation ?? this.harderVariation,
      alternativeExerciseId: alternativeExerciseId ?? this.alternativeExerciseId,
      alternativeExerciseName: alternativeExerciseName ?? this.alternativeExerciseName,
      restSeconds: restSeconds ?? this.restSeconds,
      sets: sets ?? this.sets,
      coachingCue: coachingCue ?? this.coachingCue,
      requiresSupervisionNote: requiresSupervisionNote ?? this.requiresSupervisionNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetMuscles': targetMuscles,
        'equipment': equipment,
        'difficulty': difficulty,
        'category': category,
        'instructions': instructions,
        'commonMistakes': commonMistakes,
        'easierVariation': easierVariation,
        'harderVariation': harderVariation,
        'alternativeExerciseId': alternativeExerciseId,
        'alternativeExerciseName': alternativeExerciseName,
        'restSeconds': restSeconds,
        'sets': sets.map((s) => s.toJson()).toList(),
        'coachingCue': coachingCue,
        'requiresSupervisionNote': requiresSupervisionNote,
      };

  factory ExerciseDetail.fromJson(Map<String, dynamic> json) => ExerciseDetail(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        targetMuscles: json['targetMuscles'] as String? ?? '',
        equipment: json['equipment'] as String? ?? 'Bodyweight',
        difficulty: json['difficulty'] as String? ?? 'Beginner',
        category: json['category'] as String? ?? 'Strength',
        instructions: List<String>.from(json['instructions'] as List? ?? const []),
        commonMistakes: List<String>.from(json['commonMistakes'] as List? ?? const []),
        easierVariation: json['easierVariation'] as String? ?? '',
        harderVariation: json['harderVariation'] as String? ?? '',
        alternativeExerciseId: json['alternativeExerciseId'] as String?,
        alternativeExerciseName: json['alternativeExerciseName'] as String?,
        restSeconds: json['restSeconds'] as int? ?? 60,
        sets: (json['sets'] as List? ?? const [])
            .map((e) => SetSpec.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        coachingCue: json['coachingCue'] as String?,
        requiresSupervisionNote: json['requiresSupervisionNote'] as bool? ?? false,
      );
}

/// Complete structured training session with warm-up, main work, and cool-down.
class WorkoutSession {
  final String id;
  final String title;
  final String focus;
  final int estimatedMinutes;
  final String level;
  final String goal;
  final List<ExerciseDetail> warmUp;
  final List<ExerciseDetail> mainExercises;
  final List<ExerciseDetail> coolDown;
  final String? coachingNotes;
  final String? recoveryGuidance;

  const WorkoutSession({
    required this.id,
    required this.title,
    required this.focus,
    required this.estimatedMinutes,
    required this.level,
    required this.goal,
    required this.warmUp,
    required this.mainExercises,
    required this.coolDown,
    this.coachingNotes,
    this.recoveryGuidance,
  });

  int get totalExercises => mainExercises.length;

  int get totalMainSets =>
      mainExercises.fold(0, (sum, ex) => sum + ex.sets.length);

  WorkoutSession copyWith({
    String? id,
    String? title,
    String? focus,
    int? estimatedMinutes,
    String? level,
    String? goal,
    List<ExerciseDetail>? warmUp,
    List<ExerciseDetail>? mainExercises,
    List<ExerciseDetail>? coolDown,
    String? coachingNotes,
    String? recoveryGuidance,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      title: title ?? this.title,
      focus: focus ?? this.focus,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      level: level ?? this.level,
      goal: goal ?? this.goal,
      warmUp: warmUp ?? this.warmUp,
      mainExercises: mainExercises ?? this.mainExercises,
      coolDown: coolDown ?? this.coolDown,
      coachingNotes: coachingNotes ?? this.coachingNotes,
      recoveryGuidance: recoveryGuidance ?? this.recoveryGuidance,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'focus': focus,
        'estimatedMinutes': estimatedMinutes,
        'level': level,
        'goal': goal,
        'warmUp': warmUp.map((e) => e.toJson()).toList(),
        'mainExercises': mainExercises.map((e) => e.toJson()).toList(),
        'coolDown': coolDown.map((e) => e.toJson()).toList(),
        'coachingNotes': coachingNotes,
        'recoveryGuidance': recoveryGuidance,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        focus: json['focus'] as String? ?? '',
        estimatedMinutes: json['estimatedMinutes'] as int? ?? 45,
        level: json['level'] as String? ?? 'Beginner',
        goal: json['goal'] as String? ?? 'General Fitness',
        warmUp: (json['warmUp'] as List? ?? const [])
            .map((e) => ExerciseDetail.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        mainExercises: (json['mainExercises'] as List? ?? const [])
            .map((e) => ExerciseDetail.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        coolDown: (json['coolDown'] as List? ?? const [])
            .map((e) => ExerciseDetail.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        coachingNotes: json['coachingNotes'] as String?,
        recoveryGuidance: json['recoveryGuidance'] as String?,
      );
}
