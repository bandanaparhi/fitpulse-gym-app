/// Recorded personal best performance for an exercise.
class PersonalRecord {
  final String id;
  final String memberId;
  final String exerciseId;
  final String exerciseName;
  final String recordType; // 'Max Weight', 'Max Reps', 'Best Time'
  final double value;
  final String unit; // 'kg', 'reps', 'sec'
  final DateTime achievedAt;
  final String? notes;
  final bool isSampleData;

  const PersonalRecord({
    required this.id,
    required this.memberId,
    required this.exerciseId,
    required this.exerciseName,
    required this.recordType,
    required this.value,
    required this.unit,
    required this.achievedAt,
    this.notes,
    this.isSampleData = false,
  });

  String get formattedValue {
    final valStr = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$valStr $unit';
  }

  PersonalRecord copyWith({
    String? id,
    String? memberId,
    String? exerciseId,
    String? exerciseName,
    String? recordType,
    double? value,
    String? unit,
    DateTime? achievedAt,
    String? notes,
    bool? isSampleData,
  }) {
    return PersonalRecord(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      recordType: recordType ?? this.recordType,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      achievedAt: achievedAt ?? this.achievedAt,
      notes: notes ?? this.notes,
      isSampleData: isSampleData ?? this.isSampleData,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'recordType': recordType,
        'value': value,
        'unit': unit,
        'achievedAt': achievedAt.toIso8601String(),
        'notes': notes,
        'isSampleData': isSampleData,
      };

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(
        id: json['id'] as String? ?? '',
        memberId: json['memberId'] as String? ?? 'GM-1024',
        exerciseId: json['exerciseId'] as String? ?? '',
        exerciseName: json['exerciseName'] as String? ?? '',
        recordType: json['recordType'] as String? ?? 'Max Weight',
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? 'kg',
        achievedAt: json['achievedAt'] != null
            ? DateTime.tryParse(json['achievedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        notes: json['notes'] as String?,
        isSampleData: json['isSampleData'] as bool? ?? false,
      );
}

/// Safe progression suggestion evaluated strictly from multi-session consistency.
class ProgressionSuggestion {
  final String exerciseId;
  final String exerciseName;
  final double? currentWeightKg;
  final double? suggestedWeightKg;
  final String recommendation;
  final String rationale;
  final bool readyToProgress;

  const ProgressionSuggestion({
    required this.exerciseId,
    required this.exerciseName,
    this.currentWeightKg,
    this.suggestedWeightKg,
    required this.recommendation,
    required this.rationale,
    required this.readyToProgress,
  });
}
