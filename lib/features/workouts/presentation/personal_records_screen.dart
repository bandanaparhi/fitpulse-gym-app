import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/personal_record.dart';
import '../../../data/models/workout_session.dart';
import '../../../data/repositories/workout_planner_engine.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import 'widgets/training_safety_banner.dart';

/// Filter options for [PersonalRecordsScreen].
enum _RecordTypeFilter {
  all('All'),
  maxWeight('Max Weight'),
  maxReps('Max Reps'),
  bestTime('Best Time');

  final String label;
  const _RecordTypeFilter(this.label);
}

/// Personal Records & Exercise Bests screen at `/workouts/records`.
class PersonalRecordsScreen extends ConsumerStatefulWidget {
  const PersonalRecordsScreen({super.key});

  @override
  ConsumerState<PersonalRecordsScreen> createState() =>
      _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState extends ConsumerState<PersonalRecordsScreen> {
  _RecordTypeFilter _selectedFilter = _RecordTypeFilter.all;

  Future<void> _openLogRecordDialog(String memberId) async {
    final exercises = WorkoutPlannerEngine.allExercises;
    if (exercises.isEmpty) return;

    final created = await showDialog<PersonalRecord>(
      context: context,
      builder: (ctx) => _LogPersonalRecordDialog(
        memberId: memberId,
        exercises: exercises,
      ),
    );

    if (created == null || !mounted) return;

    await ref.read(trainingPlannerRepositoryProvider).savePersonalRecord(created);
    ref.invalidate(personalRecordsProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved ${created.exerciseName} PR: ${created.formattedValue}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(personalRecordsProvider);
    final memberAsync = ref.watch(currentMemberProvider);
    final profileAsync = ref.watch(fitnessProfileProvider);

    final memberId = memberAsync.value?.id ?? 'GM-1024';
    final hasMedicalConcern =
        profileAsync.value?.hasMedicalClearanceNotice ?? false;

    return recordsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Loading personal records...'),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Load Personal Records',
          message: err.toString(),
          onRetry: () => ref.invalidate(personalRecordsProvider),
        ),
      ),
      data: (records) {
        final sortedRecords = List<PersonalRecord>.from(records)
          ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

        final filteredRecords = sortedRecords.where((pr) {
          if (_selectedFilter == _RecordTypeFilter.all) return true;
          return pr.recordType == _selectedFilter.label;
        }).toList();

        final hasSampleData = sortedRecords.any((r) => r.isSampleData);

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 600;
                    if (isWide) {
                      return PageHeader(
                        title: 'Personal Records',
                        subtitle:
                            'Track your top lifts, rep milestones, and timed holds across every exercise.',
                        trailing: PrimaryButton(
                          label: '+ Log Personal Record',
                          height: 44,
                          onPressed: () => _openLogRecordDialog(memberId),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PageHeader(
                          title: 'Personal Records',
                          subtitle:
                              'Track your top lifts, rep milestones, and timed holds across every exercise.',
                        ),
                        PrimaryButton(
                          label: '+ Log Personal Record',
                          height: 44,
                          isFullWidth: true,
                          onPressed: () => _openLogRecordDialog(memberId),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    );
                  },
                ),

                const PlannerNavStrip(currentPath: '/workouts/records'),
                const SizedBox(height: AppSpacing.lg),

                // Record Type Filter Chips
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _RecordTypeFilter.values.map((filter) {
                    final selected = _selectedFilter == filter;
                    return ChoiceChip(
                      label: Text(
                        filter.label,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.darkCharcoal
                              : AppColors.textPrimary,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppColors.limeAccent,
                      backgroundColor: AppColors.cardBackground,
                      side: BorderSide(
                        color: selected
                            ? AppColors.limeAccentDark
                            : AppColors.borderSubtle,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedFilter = filter);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                if (filteredRecords.isEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: AppRadius.roundedLg,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: EmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: sortedRecords.isEmpty
                          ? 'No Personal Records Yet'
                          : 'No Matching Records',
                      message: sortedRecords.isEmpty
                          ? 'Log your first personal best or complete a workout session to start building your records.'
                          : 'No records found under "${_selectedFilter.label}".',
                      actionLabel: sortedRecords.isEmpty
                          ? '+ Log Personal Record'
                          : 'Show All Records',
                      onAction: () {
                        if (sortedRecords.isEmpty) {
                          _openLogRecordDialog(memberId);
                        } else {
                          setState(
                              () => _selectedFilter = _RecordTypeFilter.all);
                        }
                      },
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isTwoCol = constraints.maxWidth >= 760;
                      if (!isTwoCol) {
                        return Column(
                          children: filteredRecords
                              .map(
                                (pr) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.md),
                                  child: _PersonalRecordCard(
                                    record: pr,
                                    onTap: () => context.go(
                                      '/workouts/exercise/${pr.exerciseId}',
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }

                      final rows = <Widget>[];
                      for (int i = 0; i < filteredRecords.length; i += 2) {
                        final left = filteredRecords[i];
                        final right = (i + 1 < filteredRecords.length)
                            ? filteredRecords[i + 1]
                            : null;
                        rows.add(
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _PersonalRecordCard(
                                    record: left,
                                    onTap: () => context.go(
                                      '/workouts/exercise/${left.exerciseId}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: right != null
                                      ? _PersonalRecordCard(
                                          record: right,
                                          onTap: () => context.go(
                                            '/workouts/exercise/${right.exerciseId}',
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(children: rows);
                    },
                  ),

                const SizedBox(height: AppSpacing.md),
                TrainingSafetyBanner(
                  hasMedicalConcern: hasMedicalConcern,
                  isSampleData: hasSampleData,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PersonalRecordCard extends StatelessWidget {
  final PersonalRecord record;
  final VoidCallback onTap;

  const _PersonalRecordCard({
    required this.record,
    required this.onTap,
  });

  ({Color bg, Color fg, IconData icon}) _styleForType(String type) {
    switch (type) {
      case 'Max Weight':
        return (
          bg: AppColors.limeAccent.withValues(alpha: 0.22),
          fg: AppColors.limeAccentDark,
          icon: Icons.fitness_center_rounded,
        );
      case 'Max Reps':
        return (
          bg: AppColors.infoBg,
          fg: AppColors.info,
          icon: Icons.repeat_rounded,
        );
      case 'Best Time':
        return (
          bg: AppColors.warningBg,
          fg: AppColors.warning,
          icon: Icons.timer_outlined,
        );
      default:
        return (
          bg: AppColors.cardSubtleBg,
          fg: AppColors.textSecondary,
          icon: Icons.emoji_events_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleForType(record.recordType);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.roundedLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: style.bg,
                        borderRadius: AppRadius.roundedMd,
                      ),
                      child: Icon(style.icon, size: 20, color: style.fg),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.exerciseName,
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              _RecordBadge(
                                label: record.recordType,
                                bgColor: style.bg,
                                textColor: style.fg,
                              ),
                              if (record.isSampleData)
                                const _RecordBadge(
                                  label: 'SAMPLE',
                                  bgColor: AppColors.cardSubtleBg,
                                  textColor: AppColors.textSecondary,
                                  borderColor: AppColors.borderSubtle,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2,
                        vertical: AppSpacing.xs + 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkCharcoal,
                        borderRadius: AppRadius.roundedMd,
                      ),
                      child: Text(
                        record.formattedValue,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.limeAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (record.notes != null && record.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    record.notes!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Achieved ${AppFormatters.formatShortDate(record.achievedAt)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      'Exercise Details',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.limeAccentDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.limeAccentDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;

  const _RecordBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.roundedFull,
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(
        label,
        style: AppTextStyles.badge.copyWith(
          color: textColor,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _LogPersonalRecordDialog extends StatefulWidget {
  final String memberId;
  final List<ExerciseDetail> exercises;

  const _LogPersonalRecordDialog({
    required this.memberId,
    required this.exercises,
  });

  @override
  State<_LogPersonalRecordDialog> createState() =>
      _LogPersonalRecordDialogState();
}

class _LogPersonalRecordDialogState extends State<_LogPersonalRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();

  late String _selectedExerciseId;
  String _selectedRecordType = 'Max Weight';

  static const _recordTypes = <String>[
    'Max Weight',
    'Max Reps',
    'Best Time',
  ];

  @override
  void initState() {
    super.initState();
    _selectedExerciseId = widget.exercises.first.id;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _unitForType(String type) {
    switch (type) {
      case 'Max Weight':
        return 'kg';
      case 'Max Reps':
        return 'reps';
      case 'Best Time':
        return 'sec';
      default:
        return 'kg';
    }
  }

  String _hintForType(String type) {
    switch (type) {
      case 'Max Weight':
        return 'e.g. 85';
      case 'Max Reps':
        return 'e.g. 12';
      case 'Best Time':
        return 'e.g. 75';
      default:
        return 'Enter value';
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final exercise = widget.exercises.firstWhere(
      (e) => e.id == _selectedExerciseId,
      orElse: () => widget.exercises.first,
    );
    final parsedValue = double.parse(_valueController.text.trim());
    final noteText = _noteController.text.trim();

    final record = PersonalRecord(
      id: 'PR-${DateTime.now().millisecondsSinceEpoch}',
      memberId: widget.memberId,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      recordType: _selectedRecordType,
      value: parsedValue,
      unit: _unitForType(_selectedRecordType),
      achievedAt: DateTime.now(),
      notes: noteText.isEmpty ? null : noteText,
      isSampleData: false,
    );

    Navigator.of(context).pop(record);
  }

  @override
  Widget build(BuildContext context) {
    final unit = _unitForType(_selectedRecordType);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.limeAccent.withValues(alpha: 0.2),
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        size: 20,
                        color: AppColors.limeAccentDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text('Log Personal Record', style: AppTextStyles.h3),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Exercise',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedExerciseId,
                  items: widget.exercises.map((ex) {
                    return DropdownMenuItem<String>(
                      value: ex.id,
                      child: Text(
                        ex.name,
                        style: AppTextStyles.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedExerciseId = val);
                    }
                  },
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Select an exercise' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Record Type',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedRecordType,
                  items: _recordTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: AppTextStyles.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRecordType = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Value ($unit)',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _valueController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: _hintForType(_selectedRecordType),
                    suffixText: unit,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a numeric value';
                    }
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid number greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Notes (Optional)',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Clean form, 5 reps with pause',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    SecondaryButton(
                      label: 'Cancel',
                      height: 40,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    PrimaryButton(
                      label: 'Save Record',
                      height: 40,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
