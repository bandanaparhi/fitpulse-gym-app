import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fitness_profile.dart';
import '../models/personal_record.dart';
import '../models/workout_log.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import 'workout_planner_engine.dart';

/// Repository contract for the Personalized Workout & Training Planner.
/// Scoped by [memberId] so each member's profile, plan, logs, and PRs remain isolated
/// and ready for future Firebase/API synchronization.
abstract class TrainingPlannerRepository {
  Future<FitnessProfile> getFitnessProfile(String memberId);
  Future<FitnessProfile> saveFitnessProfile(FitnessProfile profile);

  Future<WorkoutPlan> getActiveWorkoutPlan(String memberId);
  Future<WorkoutPlan> generateAndSavePlan(FitnessProfile profile);
  Future<WorkoutPlan> saveWorkoutPlan(WorkoutPlan plan);

  Future<WorkoutSession?> getSessionById(String memberId, String sessionId);
  Future<WorkoutSession?> getTodaySession(String memberId);

  Future<List<WorkoutLog>> getWorkoutLogs(String memberId);
  Future<void> saveWorkoutLog(WorkoutLog log);
  Future<void> deleteWorkoutLog(String memberId, String logId);

  Future<List<PersonalRecord>> getPersonalRecords(String memberId);
  Future<void> savePersonalRecord(PersonalRecord record);
}

/// Local-storage-backed repository using SharedPreferences with graceful in-memory
/// fallback for test environments, seeded transparently with labeled sample data.
class LocalTrainingPlannerRepository implements TrainingPlannerRepository {
  final Map<String, FitnessProfile> _memProfiles = {};
  final Map<String, WorkoutPlan> _memPlans = {};
  final Map<String, List<WorkoutLog>> _memLogs = {};
  final Map<String, List<PersonalRecord>> _memRecords = {};

  Future<SharedPreferences?> _getPrefsSafe() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  static String _profileKey(String memberId) => 'fitpulse_fitness_profile_$memberId';
  static String _planKey(String memberId) => 'fitpulse_workout_plan_$memberId';
  static String _logsKey(String memberId) => 'fitpulse_workout_logs_$memberId';
  static String _prsKey(String memberId) => 'fitpulse_personal_records_$memberId';

  FitnessProfile _defaultSampleProfile(String memberId) {
    return FitnessProfile(
      memberId: memberId,
      age: 28,
      heightCm: 178,
      weightKg: 76.5,
      targetWeightKg: 79.0,
      fitnessLevel: 'Advanced',
      primaryGoal: 'Muscle Gain',
      trainingExperience: '1.5–3 years',
      trainingDaysPerWeek: 4,
      workoutDurationMinutes: 60,
      workoutLocation: 'Gym',
      availableEquipment: const [
        'Bodyweight',
        'Dumbbells',
        'Barbell & Rack',
        'Machines',
        'Cables',
        'Pull-up Bar',
        'Cardio Machines',
      ],
      preferredExercises: const ['Barbell Bench Press', 'Pull-Ups (or Assisted Pull-Ups)'],
      avoidExercises: const [],
      injuriesOrConcerns: null,
      hasMedicalClearanceNotice: false,
      disclaimerAccepted: true,
      updatedAt: DateTime(2026, 11, 20),
      isSampleData: true,
    );
  }

  List<WorkoutLog> _defaultSampleLogs(String memberId) {
    final now = DateTime.now();
    return [
      WorkoutLog(
        id: 'LOG-SAMPLE-1',
        memberId: memberId,
        sessionId: 'SES-ADV-L1',
        sessionTitle: 'Lower Body Power & Posterior Chain',
        focus: 'Quads, Hamstrings, Glutes & Core',
        startedAt: now.subtract(const Duration(days: 1, hours: 3)),
        completedAt: now.subtract(const Duration(days: 1, hours: 2)),
        durationMinutes: 56,
        perceivedDifficulty: 7,
        generalNotes: 'Squat depth felt smooth. Kept 2 reps in reserve.',
        isSampleData: true,
        exerciseLogs: [
          ExerciseLog(
            exerciseId: 'ex_barbell_squat',
            exerciseName: 'Barbell Back Squat',
            targetMuscles: 'Quadriceps, Glutes & Core',
            sets: [
              SetLog(setNumber: 1, repsCompleted: 8, weightKg: 90, completed: true, loggedAt: now.subtract(const Duration(days: 1, hours: 3))),
              SetLog(setNumber: 2, repsCompleted: 8, weightKg: 90, completed: true, loggedAt: now.subtract(const Duration(days: 1, hours: 3))),
              SetLog(setNumber: 3, repsCompleted: 8, weightKg: 90, completed: true, loggedAt: now.subtract(const Duration(days: 1, hours: 3))),
            ],
          ),
          ExerciseLog(
            exerciseId: 'ex_rdl',
            exerciseName: 'Romanian Deadlift',
            targetMuscles: 'Hamstrings, Glutes & Spinal Erectors',
            sets: [
              SetLog(setNumber: 1, repsCompleted: 9, weightKg: 80, completed: true, loggedAt: now.subtract(const Duration(days: 1, hours: 2))),
              SetLog(setNumber: 2, repsCompleted: 9, weightKg: 80, completed: true, loggedAt: now.subtract(const Duration(days: 1, hours: 2))),
              SetLog(setNumber: 3, repsCompleted: 9, weightKg: 80, completed: true, loggedAt: now.subtract(const Duration(days: 1, hours: 2))),
            ],
          ),
        ],
      ),
      WorkoutLog(
        id: 'LOG-SAMPLE-2',
        memberId: memberId,
        sessionId: 'SES-ADV-U1',
        sessionTitle: 'Upper Body Strength & Hypertrophy',
        focus: 'Chest, Back, Shoulders & Arms',
        startedAt: now.subtract(const Duration(days: 3, hours: 4)),
        completedAt: now.subtract(const Duration(days: 3, hours: 3)),
        durationMinutes: 58,
        perceivedDifficulty: 7,
        generalNotes: 'Controlled bench eccentric; scapulae stayed locked.',
        isSampleData: true,
        exerciseLogs: [
          ExerciseLog(
            exerciseId: 'ex_bench_press',
            exerciseName: 'Barbell Bench Press',
            targetMuscles: 'Chest, Anterior Deltoids & Triceps',
            sets: [
              SetLog(setNumber: 1, repsCompleted: 8, weightKg: 70, completed: true, loggedAt: now.subtract(const Duration(days: 3, hours: 4))),
              SetLog(setNumber: 2, repsCompleted: 8, weightKg: 70, completed: true, loggedAt: now.subtract(const Duration(days: 3, hours: 4))),
              SetLog(setNumber: 3, repsCompleted: 8, weightKg: 70, completed: true, loggedAt: now.subtract(const Duration(days: 3, hours: 4))),
            ],
          ),
          ExerciseLog(
            exerciseId: 'ex_seated_row',
            exerciseName: 'Seated Cable Row',
            targetMuscles: 'Mid Back, Rhomboids, Lats & Biceps',
            sets: [
              SetLog(setNumber: 1, repsCompleted: 11, weightKg: 45, completed: true, loggedAt: now.subtract(const Duration(days: 3, hours: 3))),
              SetLog(setNumber: 2, repsCompleted: 11, weightKg: 45, completed: true, loggedAt: now.subtract(const Duration(days: 3, hours: 3))),
              SetLog(setNumber: 3, repsCompleted: 11, weightKg: 45, completed: true, loggedAt: now.subtract(const Duration(days: 3, hours: 3))),
            ],
          ),
        ],
      ),
      WorkoutLog(
        id: 'LOG-SAMPLE-3',
        memberId: memberId,
        sessionId: 'SES-ADV-L1',
        sessionTitle: 'Lower Body Power & Posterior Chain',
        focus: 'Quads, Hamstrings, Glutes & Core',
        startedAt: now.subtract(const Duration(days: 6, hours: 3)),
        completedAt: now.subtract(const Duration(days: 6, hours: 2)),
        durationMinutes: 55,
        perceivedDifficulty: 8,
        generalNotes: 'Matched all target sets across squats and RDLs.',
        isSampleData: true,
        exerciseLogs: [
          ExerciseLog(
            exerciseId: 'ex_barbell_squat',
            exerciseName: 'Barbell Back Squat',
            targetMuscles: 'Quadriceps, Glutes & Core',
            sets: [
              SetLog(setNumber: 1, repsCompleted: 8, weightKg: 90, completed: true, loggedAt: now.subtract(const Duration(days: 6, hours: 3))),
              SetLog(setNumber: 2, repsCompleted: 8, weightKg: 90, completed: true, loggedAt: now.subtract(const Duration(days: 6, hours: 3))),
              SetLog(setNumber: 3, repsCompleted: 8, weightKg: 90, completed: true, loggedAt: now.subtract(const Duration(days: 6, hours: 3))),
            ],
          ),
          ExerciseLog(
            exerciseId: 'ex_rdl',
            exerciseName: 'Romanian Deadlift',
            targetMuscles: 'Hamstrings, Glutes & Spinal Erectors',
            sets: [
              SetLog(setNumber: 1, repsCompleted: 9, weightKg: 80, completed: true, loggedAt: now.subtract(const Duration(days: 6, hours: 2))),
              SetLog(setNumber: 2, repsCompleted: 9, weightKg: 80, completed: true, loggedAt: now.subtract(const Duration(days: 6, hours: 2))),
              SetLog(setNumber: 3, repsCompleted: 9, weightKg: 80, completed: true, loggedAt: now.subtract(const Duration(days: 6, hours: 2))),
            ],
          ),
        ],
      ),
      WorkoutLog(
        id: 'LOG-SAMPLE-4',
        memberId: memberId,
        sessionId: 'SES-ADV-U1',
        sessionTitle: 'Upper Body Strength & Hypertrophy',
        focus: 'Chest, Back, Shoulders & Arms',
        startedAt: now.subtract(const Duration(days: 8, hours: 3)),
        completedAt: now.subtract(const Duration(days: 8, hours: 2)),
        durationMinutes: 59,
        perceivedDifficulty: 7,
        generalNotes: 'Good shoulder stability on bench press.',
        isSampleData: true,
        exerciseLogs: [
          ExerciseLog(
            exerciseId: 'ex_bench_press',
            exerciseName: 'Barbell Bench Press',
            targetMuscles: 'Chest, Anterior Deltoids & Triceps',
            sets: [
              SetLog(setNumber: 1, repsCompleted: 8, weightKg: 70, completed: true, loggedAt: now.subtract(const Duration(days: 8, hours: 3))),
              SetLog(setNumber: 2, repsCompleted: 8, weightKg: 70, completed: true, loggedAt: now.subtract(const Duration(days: 8, hours: 3))),
              SetLog(setNumber: 3, repsCompleted: 8, weightKg: 70, completed: true, loggedAt: now.subtract(const Duration(days: 8, hours: 3))),
            ],
          ),
        ],
      ),
    ];
  }

  List<PersonalRecord> _defaultSampleRecords(String memberId) {
    final now = DateTime.now();
    return [
      PersonalRecord(
        id: 'PR-SAMPLE-1',
        memberId: memberId,
        exerciseId: 'ex_barbell_squat',
        exerciseName: 'Barbell Back Squat',
        recordType: 'Max Weight',
        value: 95,
        unit: 'kg',
        achievedAt: now.subtract(const Duration(days: 10)),
        notes: 'Sample record — 5 clean reps with rack safeties',
        isSampleData: true,
      ),
      PersonalRecord(
        id: 'PR-SAMPLE-2',
        memberId: memberId,
        exerciseId: 'ex_bench_press',
        exerciseName: 'Barbell Bench Press',
        recordType: 'Max Weight',
        value: 75,
        unit: 'kg',
        achievedAt: now.subtract(const Duration(days: 12)),
        notes: 'Sample record — 6 clean reps with pause',
        isSampleData: true,
      ),
      PersonalRecord(
        id: 'PR-SAMPLE-3',
        memberId: memberId,
        exerciseId: 'ex_rdl',
        exerciseName: 'Romanian Deadlift',
        recordType: 'Max Weight',
        value: 85,
        unit: 'kg',
        achievedAt: now.subtract(const Duration(days: 14)),
        notes: 'Sample record — 8 controlled reps',
        isSampleData: true,
      ),
      PersonalRecord(
        id: 'PR-SAMPLE-4',
        memberId: memberId,
        exerciseId: 'ex_pullups',
        exerciseName: 'Pull-Ups (or Assisted Pull-Ups)',
        recordType: 'Max Reps',
        value: 10,
        unit: 'reps',
        achievedAt: now.subtract(const Duration(days: 7)),
        notes: 'Sample record — strict dead-hang reps',
        isSampleData: true,
      ),
      PersonalRecord(
        id: 'PR-SAMPLE-5',
        memberId: memberId,
        exerciseId: 'ex_plank',
        exerciseName: 'Forearm Plank',
        recordType: 'Best Time',
        value: 60,
        unit: 'sec',
        achievedAt: now.subtract(const Duration(days: 5)),
        notes: 'Sample record — steady nasal breathing',
        isSampleData: true,
      ),
    ];
  }

  @override
  Future<FitnessProfile> getFitnessProfile(String memberId) async {
    if (_memProfiles.containsKey(memberId)) {
      return _memProfiles[memberId]!;
    }
    final prefs = await _getPrefsSafe();
    final raw = prefs?.getString(_profileKey(memberId));
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final profile = FitnessProfile.fromJson(decoded);
        _memProfiles[memberId] = profile;
        return profile;
      } catch (_) {
        // Fall through to sample default
      }
    }
    final sample = _defaultSampleProfile(memberId);
    _memProfiles[memberId] = sample;
    return sample;
  }

  @override
  Future<FitnessProfile> saveFitnessProfile(FitnessProfile profile) async {
    final saved = profile.copyWith(
      updatedAt: DateTime.now(),
      isSampleData: false,
    );
    _memProfiles[profile.memberId] = saved;
    final prefs = await _getPrefsSafe();
    await prefs?.setString(_profileKey(profile.memberId), jsonEncode(saved.toJson()));
    return saved;
  }

  @override
  Future<WorkoutPlan> getActiveWorkoutPlan(String memberId) async {
    if (_memPlans.containsKey(memberId)) {
      return _memPlans[memberId]!;
    }
    final prefs = await _getPrefsSafe();
    final raw = prefs?.getString(_planKey(memberId));
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final plan = WorkoutPlan.fromJson(decoded);
        _memPlans[memberId] = plan;
        return plan;
      } catch (_) {
        // Fall through to generate from profile
      }
    }
    final profile = await getFitnessProfile(memberId);
    final generated = WorkoutPlannerEngine.generatePlan(profile);
    _memPlans[memberId] = generated;
    return generated;
  }

  @override
  Future<WorkoutPlan> generateAndSavePlan(FitnessProfile profile) async {
    final savedProfile = await saveFitnessProfile(profile);
    final plan = WorkoutPlannerEngine.generatePlan(savedProfile).copyWith(
      isSampleData: false,
    );
    return saveWorkoutPlan(plan);
  }

  @override
  Future<WorkoutPlan> saveWorkoutPlan(WorkoutPlan plan) async {
    _memPlans[plan.memberId] = plan;
    final prefs = await _getPrefsSafe();
    await prefs?.setString(_planKey(plan.memberId), jsonEncode(plan.toJson()));
    return plan;
  }

  @override
  Future<WorkoutSession?> getSessionById(String memberId, String sessionId) async {
    final plan = await getActiveWorkoutPlan(memberId);
    return plan.sessionById(sessionId);
  }

  @override
  Future<WorkoutSession?> getTodaySession(String memberId) async {
    final plan = await getActiveWorkoutPlan(memberId);
    final weekday = DateTime.now().weekday; // 1 = Mon ... 7 = Sun
    final todayDay = plan.dayForWeekday(weekday);
    if (todayDay.isRestDay || todayDay.sessionId == null) {
      return null;
    }
    return plan.sessionById(todayDay.sessionId);
  }

  @override
  Future<List<WorkoutLog>> getWorkoutLogs(String memberId) async {
    if (_memLogs.containsKey(memberId)) {
      return List.unmodifiable(_memLogs[memberId]!);
    }
    final prefs = await _getPrefsSafe();
    final raw = prefs?.getString(_logsKey(memberId));
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => WorkoutLog.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
        _memLogs[memberId] = list;
        return List.unmodifiable(list);
      } catch (_) {
        // Fall back to sample logs
      }
    }
    final sample = _defaultSampleLogs(memberId);
    _memLogs[memberId] = sample;
    return List.unmodifiable(sample);
  }

  @override
  Future<void> saveWorkoutLog(WorkoutLog log) async {
    final current = List<WorkoutLog>.from(await getWorkoutLogs(log.memberId));
    current.removeWhere((e) => e.id == log.id);
    current.insert(0, log.copyWith(isSampleData: false));
    _memLogs[log.memberId] = current;

    final prefs = await _getPrefsSafe();
    await prefs?.setString(
      _logsKey(log.memberId),
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );

    // Update Personal Records automatically if a new best is achieved cleanly
    if (log.isCompleted && !log.stoppedDueToDiscomfort) {
      await _updatePersonalRecordsFromLog(log);
    }
  }

  Future<void> _updatePersonalRecordsFromLog(WorkoutLog log) async {
    final existing = List<PersonalRecord>.from(await getPersonalRecords(log.memberId));
    bool changed = false;

    for (final exLog in log.exerciseLogs) {
      if (exLog.skipped) continue;
      final topWeight = exLog.topWeightKg;
      final maxReps = exLog.maxRepsCompleted;

      if (topWeight != null && topWeight > 0) {
        final idx = existing.indexWhere(
          (r) => r.exerciseId == exLog.exerciseId && r.recordType == 'Max Weight',
        );
        if (idx == -1 || topWeight > existing[idx].value) {
          final pr = PersonalRecord(
            id: 'PR-${exLog.exerciseId}-WT',
            memberId: log.memberId,
            exerciseId: exLog.exerciseId,
            exerciseName: exLog.exerciseName,
            recordType: 'Max Weight',
            value: topWeight,
            unit: 'kg',
            achievedAt: log.completedAt ?? DateTime.now(),
            notes: 'Logged during ${log.sessionTitle}',
            isSampleData: false,
          );
          if (idx == -1) {
            existing.insert(0, pr);
          } else {
            existing[idx] = pr;
          }
          changed = true;
        }
      } else if (maxReps > 0) {
        final idx = existing.indexWhere(
          (r) => r.exerciseId == exLog.exerciseId && r.recordType == 'Max Reps',
        );
        if (idx == -1 || maxReps > existing[idx].value) {
          final pr = PersonalRecord(
            id: 'PR-${exLog.exerciseId}-REP',
            memberId: log.memberId,
            exerciseId: exLog.exerciseId,
            exerciseName: exLog.exerciseName,
            recordType: 'Max Reps',
            value: maxReps.toDouble(),
            unit: 'reps',
            achievedAt: log.completedAt ?? DateTime.now(),
            notes: 'Logged during ${log.sessionTitle}',
            isSampleData: false,
          );
          if (idx == -1) {
            existing.insert(0, pr);
          } else {
            existing[idx] = pr;
          }
          changed = true;
        }
      }
    }

    if (changed) {
      _memRecords[log.memberId] = existing;
      final prefs = await _getPrefsSafe();
      await prefs?.setString(
        _prsKey(log.memberId),
        jsonEncode(existing.map((e) => e.toJson()).toList()),
      );
    }
  }

  @override
  Future<void> deleteWorkoutLog(String memberId, String logId) async {
    final current = List<WorkoutLog>.from(await getWorkoutLogs(memberId));
    current.removeWhere((e) => e.id == logId);
    _memLogs[memberId] = current;

    final prefs = await _getPrefsSafe();
    await prefs?.setString(
      _logsKey(memberId),
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<List<PersonalRecord>> getPersonalRecords(String memberId) async {
    if (_memRecords.containsKey(memberId)) {
      return List.unmodifiable(_memRecords[memberId]!);
    }
    final prefs = await _getPrefsSafe();
    final raw = prefs?.getString(_prsKey(memberId));
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => PersonalRecord.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
        _memRecords[memberId] = list;
        return List.unmodifiable(list);
      } catch (_) {
        // Fall through
      }
    }
    final sample = _defaultSampleRecords(memberId);
    _memRecords[memberId] = sample;
    return List.unmodifiable(sample);
  }

  @override
  Future<void> savePersonalRecord(PersonalRecord record) async {
    final current = List<PersonalRecord>.from(await getPersonalRecords(record.memberId));
    current.removeWhere((r) => r.id == record.id);
    current.insert(0, record.copyWith(isSampleData: false));
    _memRecords[record.memberId] = current;

    final prefs = await _getPrefsSafe();
    await prefs?.setString(
      _prsKey(record.memberId),
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
  }
}
