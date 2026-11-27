import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/personal_record.dart';
import '../../../../data/repositories/workout_planner_engine.dart';

/// Displays recorded Personal Fitness Records (Max Weight, Max Reps, Best Time)
/// directly on `/progress`, with quick logging and a link to `/workouts/records`.
class PersonalRecordsSummaryCard extends ConsumerWidget {
  final String memberId;
  final bool isMetric;

  const PersonalRecordsSummaryCard({
    super.key,
    required this.memberId,
    required this.isMetric,
  });

  Future<void> _openQuickLogDialog(BuildContext context, WidgetRef ref) async {
    final exercises = WorkoutPlannerEngine.allExercises;
    if (exercises.isEmpty) return;

    var selectedExercise = exercises.first;
    var recordType = 'Max Weight';
    final valueCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final created = await showDialog<PersonalRecord>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final unitLabel = recordType == 'Max Weight'
              ? (isMetric ? 'kg' : 'lb')
              : (recordType == 'Max Reps' ? 'reps' : 'sec');
          return AlertDialog(
            title: const Text(
              'Log Personal Fitness Record',
              style: AppTextStyles.titleLarge,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedExercise.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Exercise',
                      isDense: true,
                    ),
                    items: exercises
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      setModalState(() {
                        selectedExercise =
                            exercises.firstWhere((e) => e.id == id);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: recordType,
                    decoration: const InputDecoration(
                      labelText: 'Record Type',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Max Weight',
                        child: Text('Max Weight'),
                      ),
                      DropdownMenuItem(
                        value: 'Max Reps',
                        child: Text('Max Reps'),
                      ),
                      DropdownMenuItem(
                        value: 'Best Time',
                        child: Text('Best Time'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setModalState(() => recordType = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: valueCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Value ($unitLabel)',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final parsed = double.tryParse(valueCtrl.text.trim());
                  if (parsed == null || parsed <= 0) return;
                  final normalizedVal =
                      (recordType == 'Max Weight' && !isMetric)
                          ? parsed / 2.20462
                          : parsed;
                  final unit = recordType == 'Max Weight'
                      ? 'kg'
                      : (recordType == 'Max Reps' ? 'reps' : 'sec');
                  Navigator.of(ctx).pop(
                    PersonalRecord(
                      id: 'PR-${DateTime.now().millisecondsSinceEpoch}',
                      memberId: memberId,
                      exerciseId: selectedExercise.id,
                      exerciseName: selectedExercise.name,
                      recordType: recordType,
                      value: normalizedVal,
                      unit: unit,
                      achievedAt: DateTime.now(),
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    ),
                  );
                },
                child: const Text('Save Record'),
              ),
            ],
          );
        },
      ),
    );

    valueCtrl.dispose();
    notesCtrl.dispose();

    if (created == null || !context.mounted) return;
    await ref
        .read(trainingPlannerRepositoryProvider)
        .savePersonalRecord(created);
    ref.invalidate(personalRecordsProvider);
  }

  String _displayValue(PersonalRecord pr) {
    if (pr.unit == 'kg' && !isMetric) {
      return '${(pr.value * 2.20462).toStringAsFixed(1)} lb';
    }
    return pr.formattedValue;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(personalRecordsProvider);
    final records = List<PersonalRecord>.from(
      recordsAsync.value ?? const <PersonalRecord>[],
    )..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

    final visible = records.take(6).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.darkCharcoal,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'Personal Fitness Records',
                      style: AppTextStyles.h3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 8,
                      ),
                      side: const BorderSide(color: AppColors.borderSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Log PR',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _openQuickLogDialog(context, ref),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      GoRouter.maybeOf(context)?.go('/workouts/records');
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 15),
                    label: const Text('All PRs'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Top recorded lifts, rep milestones, and timed benchmarks.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (recordsAsync.isLoading && records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Loading personal records...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'No personal fitness records logged yet. Tap "Log PR" or complete a workout set.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 820
                    ? 3
                    : (constraints.maxWidth >= 520 ? 2 : 1);
                final rows = <Widget>[];
                for (var i = 0; i < visible.length; i += columns) {
                  final slice = visible.sublist(
                    i,
                    (i + columns).clamp(0, visible.length),
                  );
                  rows.add(
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i + columns < visible.length ? AppSpacing.sm : 0,
                      ),
                      child: Row(
                        children: [
                          for (var j = 0; j < columns; j++) ...[
                            if (j > 0) const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: j < slice.length
                                  ? _PrTile(
                                      record: slice[j],
                                      displayValue: _displayValue(slice[j]),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return Column(children: rows);
              },
            ),
        ],
      ),
    );
  }
}

class _PrTile extends StatelessWidget {
  final PersonalRecord record;
  final String displayValue;

  const _PrTile({
    required this.record,
    required this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.exerciseName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  record.recordType,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.limeAccentDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            displayValue,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Achieved ${AppFormatters.formatShortDate(record.achievedAt)}${record.isSampleData ? ' • Sample' : ''}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
