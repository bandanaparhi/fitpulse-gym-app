import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/fitness_profile.dart';
import '../models/personal_record.dart';
import '../models/workout_log.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import 'training_planner_repository.dart';
import 'workout_planner_engine.dart';

/// Supabase-backed [TrainingPlannerRepository] persisting personalized fitness
/// profiles, generated weekly plans, detailed workout logs, and personal records
/// in PostgreSQL with strict RLS user isolation.
class SupabaseTrainingPlannerRepository implements TrainingPlannerRepository {
  SupabaseClient get _client => SupabaseService.client;

  FitnessProfile _defaultProfile(String memberId) {
    return FitnessProfile(
      memberId: memberId,
      age: 28,
      heightCm: 175,
      weightKg: 74,
      fitnessLevel: 'Beginner',
      primaryGoal: 'General Fitness',
      trainingExperience: '6–18 months',
      trainingDaysPerWeek: 3,
      workoutDurationMinutes: 45,
      workoutLocation: 'Gym',
      availableEquipment: const ['Bodyweight', 'Dumbbells', 'Machines'],
      updatedAt: DateTime.now(),
      isSampleData: false,
    );
  }

  @override
  Future<FitnessProfile> getFitnessProfile(String memberId) async {
    try {
      final row = await _client
          .from('fitness_profiles')
          .select()
          .eq('user_id', memberId)
          .maybeSingle();

      if (row == null) return _defaultProfile(memberId);

      return FitnessProfile(
        memberId: memberId,
        age: (row['age'] as int?) ?? 28,
        heightCm: (row['height_cm'] as num?)?.toDouble() ?? 175,
        weightKg: (row['weight_kg'] as num?)?.toDouble() ?? 74,
        targetWeightKg: (row['target_weight_kg'] as num?)?.toDouble(),
        fitnessLevel: (row['fitness_level'] as String?) ?? 'Beginner',
        primaryGoal: (row['primary_goal'] as String?) ?? 'General Fitness',
        trainingExperience:
            (row['training_experience'] as String?) ?? '6–18 months',
        trainingDaysPerWeek: (row['training_days_per_week'] as int?) ?? 3,
        workoutDurationMinutes: (row['workout_duration_minutes'] as int?) ?? 45,
        workoutLocation: (row['workout_location'] as String?) ?? 'Gym',
        availableEquipment:
            List<String>.from(row['available_equipment'] as List? ?? const ['Bodyweight']),
        preferredExercises:
            List<String>.from(row['preferred_exercises'] as List? ?? const []),
        avoidExercises:
            List<String>.from(row['avoid_exercises'] as List? ?? const []),
        injuriesOrConcerns: row['injuries_or_concerns'] as String?,
        hasMedicalClearanceNotice:
            (row['has_medical_clearance_notice'] as bool?) ?? false,
        disclaimerAccepted: (row['disclaimer_accepted'] as bool?) ?? true,
        updatedAt:
            DateTime.tryParse('${row['updated_at']}') ?? DateTime.now(),
        isSampleData: false,
      );
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<FitnessProfile> saveFitnessProfile(FitnessProfile profile) async {
    try {
      await _client.from('fitness_profiles').upsert({
        'user_id': profile.memberId,
        'age': profile.age,
        'height_cm': profile.heightCm,
        'weight_kg': profile.weightKg,
        'target_weight_kg': profile.targetWeightKg,
        'fitness_level': profile.fitnessLevel,
        'primary_goal': profile.primaryGoal,
        'training_experience': profile.trainingExperience,
        'training_days_per_week': profile.trainingDaysPerWeek,
        'workout_duration_minutes': profile.workoutDurationMinutes,
        'workout_location': profile.workoutLocation,
        'available_equipment': profile.availableEquipment,
        'preferred_exercises': profile.preferredExercises,
        'avoid_exercises': profile.avoidExercises,
        'injuries_or_concerns': profile.injuriesOrConcerns,
        'has_medical_clearance_notice': profile.hasMedicalClearanceNotice,
        'disclaimer_accepted': profile.disclaimerAccepted,
      }, onConflict: 'user_id');

      return profile.copyWith(updatedAt: DateTime.now(), isSampleData: false);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<WorkoutPlan> getActiveWorkoutPlan(String memberId) async {
    try {
      final row = await _client
          .from('workout_plans')
          .select()
          .eq('user_id', memberId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row != null && row['schedule'] is Map) {
        final sched = Map<String, dynamic>.from(row['schedule'] as Map);
        if (sched['weekSchedule'] is List && sched['sessions'] is List) {
          return WorkoutPlan(
            id: row['id'] as String,
            memberId: memberId,
            title: (row['plan_name'] as String?) ?? 'Personalized Plan',
            splitSummary: (row['split_summary'] as String?) ?? '',
            goal: (row['fitness_goal'] as String?) ?? 'General Fitness',
            level: (row['fitness_level'] as String?) ?? 'Beginner',
            location: (row['workout_location'] as String?) ?? 'Gym',
            trainingDaysPerWeek: (row['training_days_per_week'] as int?) ?? 3,
            createdAt:
                DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
            weekSchedule: (sched['weekSchedule'] as List)
                .map((e) => WorkoutPlanDay.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList(),
            sessions: (sched['sessions'] as List)
                .map((e) => WorkoutSession.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList(),
            progressionGuidance:
                (row['progression_guidance'] as String?) ?? '',
            recoveryGuidance: (row['recovery_guidance'] as String?) ?? '',
            isSampleData: false,
          );
        }
      }

      final profile = await getFitnessProfile(memberId);
      return await generateAndSavePlan(profile);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<WorkoutPlan> generateAndSavePlan(FitnessProfile profile) async {
    final savedProfile = await saveFitnessProfile(profile);
    final generated = WorkoutPlannerEngine.generatePlan(savedProfile).copyWith(
      isSampleData: false,
    );
    return saveWorkoutPlan(generated);
  }

  @override
  Future<WorkoutPlan> saveWorkoutPlan(WorkoutPlan plan) async {
    try {
      // Archive previous active plans for this member cleanly
      await _client
          .from('workout_plans')
          .update({'status': 'archived'})
          .eq('user_id', plan.memberId)
          .eq('status', 'active');

      final row = await _client
          .from('workout_plans')
          .insert({
            'user_id': plan.memberId,
            'plan_name': plan.title,
            'split_summary': plan.splitSummary,
            'fitness_goal': plan.goal,
            'fitness_level': plan.level,
            'workout_location': plan.location,
            'duration_weeks': 4,
            'training_days_per_week': plan.trainingDaysPerWeek,
            'schedule': {
              'weekSchedule': plan.weekSchedule.map((d) => d.toJson()).toList(),
              'sessions': plan.sessions.map((s) => s.toJson()).toList(),
            },
            'progression_guidance': plan.progressionGuidance,
            'recovery_guidance': plan.recoveryGuidance,
            'status': 'active',
          })
          .select()
          .single();

      return plan.copyWith(id: row['id'] as String, isSampleData: false);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<WorkoutSession?> getSessionById(
    String memberId,
    String sessionId,
  ) async {
    final plan = await getActiveWorkoutPlan(memberId);
    return plan.sessionById(sessionId);
  }

  @override
  Future<WorkoutSession?> getTodaySession(String memberId) async {
    final plan = await getActiveWorkoutPlan(memberId);
    final today = plan.dayForWeekday(DateTime.now().weekday);
    if (today.isRestDay || today.sessionId == null) return null;
    return plan.sessionById(today.sessionId);
  }

  @override
  Future<List<WorkoutLog>> getWorkoutLogs(String memberId) async {
    try {
      final rows = await _client
          .from('workout_logs')
          .select()
          .eq('user_id', memberId)
          .order('completed_at', ascending: false)
          .limit(50);

      return rows.map((row) {
        final exList = (row['exercise_logs'] as List? ?? const [])
            .map((e) => ExerciseLog.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return WorkoutLog(
          id: row['id'] as String,
          memberId: memberId,
          sessionId: (row['session_id'] as String?) ?? '',
          sessionTitle: (row['session_title'] as String?) ?? 'Workout Session',
          focus: (row['focus'] as String?) ?? '',
          startedAt:
              DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
          completedAt: DateTime.tryParse('${row['completed_at']}'),
          durationMinutes: (row['duration'] as int?) ?? 45,
          exerciseLogs: exList,
          perceivedDifficulty: (row['perceived_difficulty'] as int?) ?? 6,
          generalNotes: row['notes'] as String?,
          isCompleted: true,
          stoppedDueToDiscomfort:
              (row['stopped_due_to_discomfort'] as bool?) ?? false,
          discomfortNote: row['discomfort_note'] as String?,
          isSampleData: false,
        );
      }).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<void> saveWorkoutLog(WorkoutLog log) async {
    try {
      await _client.from('workout_logs').insert({
        'user_id': log.memberId,
        'session_id': log.sessionId,
        'session_title': log.sessionTitle,
        'focus': log.focus,
        'sets_completed': log.completedSets,
        'repetitions': log.exerciseLogs.fold<int>(
          0,
          (sum, ex) =>
              sum + ex.sets.fold<int>(0, (s2, s) => s2 + (s.completed ? s.repsCompleted : 0)),
        ),
        'weight_used': log.totalVolumeKg,
        'duration': log.durationMinutes,
        'perceived_difficulty': log.perceivedDifficulty,
        'stopped_due_to_discomfort': log.stoppedDueToDiscomfort,
        'discomfort_note': log.discomfortNote,
        'exercise_logs': log.exerciseLogs.map((e) => e.toJson()).toList(),
        'completed_at': (log.completedAt ?? DateTime.now()).toIso8601String(),
        'notes': log.generalNotes,
      });

      if (log.isCompleted && !log.stoppedDueToDiscomfort) {
        await _syncPersonalRecordsFromLog(log);
      }
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  Future<void> _syncPersonalRecordsFromLog(WorkoutLog log) async {
    final existing = await getPersonalRecords(log.memberId);
    for (final ex in log.exerciseLogs) {
      if (ex.skipped) continue;
      final topWeight = ex.topWeightKg;
      final maxReps = ex.maxRepsCompleted;
      if (topWeight != null && topWeight > 0) {
        final match = existing
            .where((r) =>
                r.exerciseId == ex.exerciseId && r.recordType == 'Max Weight')
            .toList();
        if (match.isEmpty || topWeight > match.first.value) {
          await savePersonalRecord(
            PersonalRecord(
              id: match.isNotEmpty ? match.first.id : '',
              memberId: log.memberId,
              exerciseId: ex.exerciseId,
              exerciseName: ex.exerciseName,
              recordType: 'Max Weight',
              value: topWeight,
              unit: 'kg',
              achievedAt: log.completedAt ?? DateTime.now(),
              notes: 'Logged during ${log.sessionTitle}',
            ),
          );
        }
      } else if (maxReps > 0) {
        final match = existing
            .where((r) =>
                r.exerciseId == ex.exerciseId && r.recordType == 'Max Reps')
            .toList();
        if (match.isEmpty || maxReps > match.first.value) {
          await savePersonalRecord(
            PersonalRecord(
              id: match.isNotEmpty ? match.first.id : '',
              memberId: log.memberId,
              exerciseId: ex.exerciseId,
              exerciseName: ex.exerciseName,
              recordType: 'Max Reps',
              value: maxReps.toDouble(),
              unit: 'reps',
              achievedAt: log.completedAt ?? DateTime.now(),
              notes: 'Logged during ${log.sessionTitle}',
            ),
          );
        }
      }
    }
  }

  @override
  Future<void> deleteWorkoutLog(String memberId, String logId) async {
    try {
      await _client
          .from('workout_logs')
          .delete()
          .eq('id', logId)
          .eq('user_id', memberId);
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<List<PersonalRecord>> getPersonalRecords(String memberId) async {
    try {
      final rows = await _client
          .from('personal_records')
          .select()
          .eq('user_id', memberId)
          .order('achieved_at', ascending: false);

      return rows.map((r) {
        return PersonalRecord(
          id: r['id'] as String,
          memberId: memberId,
          exerciseId: (r['exercise_slug'] as String?) ?? '',
          exerciseName: (r['exercise_name'] as String?) ?? '',
          recordType: (r['record_type'] as String?) ?? 'Max Weight',
          value: (r['value'] as num?)?.toDouble() ?? 0,
          unit: (r['unit'] as String?) ?? 'kg',
          achievedAt:
              DateTime.tryParse('${r['achieved_at']}') ?? DateTime.now(),
          notes: r['notes'] as String?,
          isSampleData: false,
        );
      }).toList();
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }

  @override
  Future<void> savePersonalRecord(PersonalRecord record) async {
    try {
      final isUuid = record.id.contains('-') && record.id.length == 36;
      await _client.from('personal_records').upsert({
        if (isUuid) 'id': record.id,
        'user_id': record.memberId,
        'exercise_slug': record.exerciseId,
        'exercise_name': record.exerciseName,
        'record_type': record.recordType,
        'value': record.value,
        'unit': record.unit,
        'achieved_at': record.achievedAt.toIso8601String(),
        'notes': record.notes,
      });
    } catch (e) {
      throw Exception(SupabaseErrorMapper.toUserMessage(e));
    }
  }
}
