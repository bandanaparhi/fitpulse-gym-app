/// Member's personalized fitness & training profile used to generate and adapt
/// weekly workout plans.
class FitnessProfile {
  final String memberId;
  final int age;
  final double heightCm;
  final double weightKg;
  final double? targetWeightKg;
  final String fitnessLevel; // 'Beginner', 'Advanced', 'High-Performance'
  final String primaryGoal; // 'Muscle Gain', 'Fat Loss', 'Strength', 'Endurance', 'General Fitness'
  final String trainingExperience; // 'New / Returning', '< 6 months', '6–18 months', '1.5–3 years', '3+ years'
  final int trainingDaysPerWeek; // 2–6
  final int workoutDurationMinutes; // 30, 45, 60, 75, 90
  final String workoutLocation; // 'Gym', 'Home'
  final List<String> availableEquipment;
  final List<String> preferredExercises;
  final List<String> avoidExercises;
  final String? injuriesOrConcerns; // Optional, skippable
  final bool hasMedicalClearanceNotice;
  final bool disclaimerAccepted;
  final DateTime updatedAt;
  final bool isSampleData;

  const FitnessProfile({
    required this.memberId,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    this.targetWeightKg,
    required this.fitnessLevel,
    required this.primaryGoal,
    required this.trainingExperience,
    required this.trainingDaysPerWeek,
    required this.workoutDurationMinutes,
    required this.workoutLocation,
    required this.availableEquipment,
    this.preferredExercises = const [],
    this.avoidExercises = const [],
    this.injuriesOrConcerns,
    this.hasMedicalClearanceNotice = false,
    this.disclaimerAccepted = true,
    required this.updatedAt,
    this.isSampleData = false,
  });

  FitnessProfile copyWith({
    String? memberId,
    int? age,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    bool clearTargetWeight = false,
    String? fitnessLevel,
    String? primaryGoal,
    String? trainingExperience,
    int? trainingDaysPerWeek,
    int? workoutDurationMinutes,
    String? workoutLocation,
    List<String>? availableEquipment,
    List<String>? preferredExercises,
    List<String>? avoidExercises,
    String? injuriesOrConcerns,
    bool clearInjuries = false,
    bool? hasMedicalClearanceNotice,
    bool? disclaimerAccepted,
    DateTime? updatedAt,
    bool? isSampleData,
  }) {
    return FitnessProfile(
      memberId: memberId ?? this.memberId,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg:
          clearTargetWeight ? null : (targetWeightKg ?? this.targetWeightKg),
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      trainingExperience: trainingExperience ?? this.trainingExperience,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      workoutDurationMinutes:
          workoutDurationMinutes ?? this.workoutDurationMinutes,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      preferredExercises: preferredExercises ?? this.preferredExercises,
      avoidExercises: avoidExercises ?? this.avoidExercises,
      injuriesOrConcerns:
          clearInjuries ? null : (injuriesOrConcerns ?? this.injuriesOrConcerns),
      hasMedicalClearanceNotice:
          hasMedicalClearanceNotice ?? this.hasMedicalClearanceNotice,
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
      updatedAt: updatedAt ?? this.updatedAt,
      isSampleData: isSampleData ?? this.isSampleData,
    );
  }

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'targetWeightKg': targetWeightKg,
        'fitnessLevel': fitnessLevel,
        'primaryGoal': primaryGoal,
        'trainingExperience': trainingExperience,
        'trainingDaysPerWeek': trainingDaysPerWeek,
        'workoutDurationMinutes': workoutDurationMinutes,
        'workoutLocation': workoutLocation,
        'availableEquipment': availableEquipment,
        'preferredExercises': preferredExercises,
        'avoidExercises': avoidExercises,
        'injuriesOrConcerns': injuriesOrConcerns,
        'hasMedicalClearanceNotice': hasMedicalClearanceNotice,
        'disclaimerAccepted': disclaimerAccepted,
        'updatedAt': updatedAt.toIso8601String(),
        'isSampleData': isSampleData,
      };

  factory FitnessProfile.fromJson(Map<String, dynamic> json) {
    return FitnessProfile(
      memberId: json['memberId'] as String? ?? 'GM-1024',
      age: json['age'] as int? ?? 28,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 175.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 75.0,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      fitnessLevel: json['fitnessLevel'] as String? ?? 'Beginner',
      primaryGoal: json['primaryGoal'] as String? ?? 'General Fitness',
      trainingExperience:
          json['trainingExperience'] as String? ?? '6–18 months',
      trainingDaysPerWeek: json['trainingDaysPerWeek'] as int? ?? 3,
      workoutDurationMinutes: json['workoutDurationMinutes'] as int? ?? 45,
      workoutLocation: json['workoutLocation'] as String? ?? 'Gym',
      availableEquipment: List<String>.from(
        json['availableEquipment'] as List? ?? const ['Bodyweight'],
      ),
      preferredExercises: List<String>.from(
        json['preferredExercises'] as List? ?? const [],
      ),
      avoidExercises: List<String>.from(
        json['avoidExercises'] as List? ?? const [],
      ),
      injuriesOrConcerns: json['injuriesOrConcerns'] as String?,
      hasMedicalClearanceNotice:
          json['hasMedicalClearanceNotice'] as bool? ?? false,
      disclaimerAccepted: json['disclaimerAccepted'] as bool? ?? true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isSampleData: json['isSampleData'] as bool? ?? false,
    );
  }
}
