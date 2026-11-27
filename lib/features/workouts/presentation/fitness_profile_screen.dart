import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/fitness_profile.dart';
import '../../../data/repositories/workout_planner_engine.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/primary_button.dart';
import 'widgets/training_safety_banner.dart';

/// Fitness & Training Profile screen at `/workouts/profile`.
///
/// Collects physical stats, training level, goal, experience, weekly schedule,
/// location, equipment, exercise preferences, and optional injury/health notes
/// to generate a personalized 7-day workout plan.
class FitnessProfileScreen extends ConsumerStatefulWidget {
  const FitnessProfileScreen({super.key});

  @override
  ConsumerState<FitnessProfileScreen> createState() =>
      _FitnessProfileScreenState();
}

class _FitnessProfileScreenState extends ConsumerState<FitnessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _targetWeightController;
  late final TextEditingController _injuriesController;

  bool _initialized = false;
  bool _isSaving = false;

  String _fitnessLevel = 'Beginner';
  String _primaryGoal = 'General Fitness';
  String _trainingExperience = '6–18 months';
  int _trainingDaysPerWeek = 3;
  int _workoutDurationMinutes = 45;
  String _workoutLocation = 'Gym';
  List<String> _availableEquipment = ['Bodyweight'];
  List<String> _preferredExercises = [];
  List<String> _avoidExercises = [];
  bool _hasMedicalClearanceNotice = false;

  static const _fitnessLevels = <String>[
    'Beginner',
    'Advanced',
    'High-Performance',
  ];

  static const _primaryGoals = <String>[
    'Muscle Gain',
    'Fat Loss',
    'Strength',
    'Endurance',
    'General Fitness',
  ];

  static const _experienceOptions = <String>[
    'New / Returning',
    '< 6 months',
    '6–18 months',
    '1.5–3 years',
    '3+ years',
  ];

  static const _dayOptions = <int>[2, 3, 4, 5, 6];
  static const _durationOptions = <int>[30, 45, 60, 75, 90];
  static const _locationOptions = <String>['Gym', 'Home'];

  static const _equipmentOptions = <String>[
    'Bodyweight',
    'Dumbbells',
    'Barbell & Rack',
    'Machines',
    'Cables',
    'Resistance Bands',
    'Kettlebells',
    'Pull-up Bar',
    'Cardio Machines',
  ];

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _targetWeightController = TextEditingController();
    _injuriesController = TextEditingController();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _injuriesController.dispose();
    super.dispose();
  }

  void _syncFromProfile(FitnessProfile profile) {
    if (_initialized) return;
    _ageController.text = profile.age.toString();
    _heightController.text = _formatNumber(profile.heightCm);
    _weightController.text = _formatNumber(profile.weightKg);
    _targetWeightController.text = profile.targetWeightKg != null
        ? _formatNumber(profile.targetWeightKg!)
        : '';
    _injuriesController.text = profile.injuriesOrConcerns ?? '';

    _fitnessLevel = _fitnessLevels.contains(profile.fitnessLevel)
        ? profile.fitnessLevel
        : 'Beginner';
    _primaryGoal = _primaryGoals.contains(profile.primaryGoal)
        ? profile.primaryGoal
        : 'General Fitness';
    _trainingExperience = _experienceOptions.contains(profile.trainingExperience)
        ? profile.trainingExperience
        : '6–18 months';
    _trainingDaysPerWeek = _dayOptions.contains(profile.trainingDaysPerWeek)
        ? profile.trainingDaysPerWeek
        : 3;
    _workoutDurationMinutes =
        _durationOptions.contains(profile.workoutDurationMinutes)
            ? profile.workoutDurationMinutes
            : 45;
    _workoutLocation = _locationOptions.contains(profile.workoutLocation)
        ? profile.workoutLocation
        : 'Gym';
    _availableEquipment = List<String>.from(profile.availableEquipment);
    if (_availableEquipment.isEmpty) {
      _availableEquipment.add('Bodyweight');
    }
    _preferredExercises = List<String>.from(profile.preferredExercises);
    _avoidExercises = List<String>.from(profile.avoidExercises);
    _hasMedicalClearanceNotice = profile.hasMedicalClearanceNotice;
    _initialized = true;
  }

  String _formatNumber(double val) {
    return val == val.roundToDouble()
        ? val.toInt().toString()
        : val.toStringAsFixed(1);
  }

  List<String> get _selectableExerciseNames {
    return WorkoutPlannerEngine.allExercises
        .where((e) => !e.id.startsWith('wu_') && !e.id.startsWith('cd_'))
        .map((e) => e.name)
        .toList();
  }

  Future<void> _saveAndGenerate(FitnessProfile current) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the highlighted profile fields before saving.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final age = int.parse(_ageController.text.trim());
    final heightCm = double.parse(_heightController.text.trim());
    final weightKg = double.parse(_weightController.text.trim());
    final targetText = _targetWeightController.text.trim();
    final targetWeightKg =
        targetText.isEmpty ? null : double.parse(targetText);
    final injuriesText = _injuriesController.text.trim();
    final equipment = _availableEquipment.isEmpty
        ? ['Bodyweight']
        : List<String>.from(_availableEquipment);

    final updated = current.copyWith(
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      targetWeightKg: targetWeightKg,
      clearTargetWeight: targetWeightKg == null,
      fitnessLevel: _fitnessLevel,
      primaryGoal: _primaryGoal,
      trainingExperience: _trainingExperience,
      trainingDaysPerWeek: _trainingDaysPerWeek,
      workoutDurationMinutes: _workoutDurationMinutes,
      workoutLocation: _workoutLocation,
      availableEquipment: equipment,
      preferredExercises: List<String>.from(_preferredExercises),
      avoidExercises: List<String>.from(_avoidExercises),
      injuriesOrConcerns: injuriesText.isEmpty ? null : injuriesText,
      clearInjuries: injuriesText.isEmpty,
      hasMedicalClearanceNotice: _hasMedicalClearanceNotice,
      disclaimerAccepted: true,
      updatedAt: DateTime.now(),
      isSampleData: false,
    );

    try {
      await ref
          .read(fitnessProfileProvider.notifier)
          .saveProfileAndRegenerate(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fitness profile saved and personalized weekly plan generated!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      if (GoRouter.maybeOf(context) != null) {
        context.go('/workouts/weekly-plan');
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save profile: $err'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(fitnessProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: profileAsync.when(
        loading: () => const LoadingIndicator(
          message: 'Loading your fitness profile...',
        ),
        error: (err, _) => ErrorState(
          title: 'Unable to Load Fitness Profile',
          message: err.toString(),
          onRetry: () => ref.invalidate(fitnessProfileProvider),
        ),
        data: (profile) {
          _syncFromProfile(profile);

          final showMedicalWarning = _hasMedicalClearanceNotice ||
              _injuriesController.text.trim().isNotEmpty;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              final pagePadding = isCompact ? AppSpacing.md : AppSpacing.lg;

              return SingleChildScrollView(
                padding: EdgeInsets.all(pagePadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeader(
                        title: 'Fitness & Training Profile',
                        subtitle:
                            'Customize your stats, training experience, schedule, and equipment to tailor your weekly plan.',
                        trailing: profile.isSampleData
                            ? _SampleBadge()
                            : null,
                      ),
                      const PlannerNavStrip(currentPath: '/workouts/profile'),
                      const SizedBox(height: AppSpacing.lg),

                      TrainingSafetyBanner(
                        hasMedicalConcern: showMedicalWarning,
                        isSampleData: profile.isSampleData,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 1. Body Metrics & Stats
                      InfoCard(
                        title: 'Body Metrics & Targets',
                        subtitle:
                            'Used to calibrate training guidance and track baseline goals.',
                        icon: Icons.monitor_weight_outlined,
                        child: _buildMetricsGrid(constraints.maxWidth),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 2. Level, Goal & Experience
                      InfoCard(
                        title: 'Training Level, Goal & Experience',
                        subtitle:
                            'Determines your weekly split structure, exercise complexity, and rest intervals.',
                        icon: Icons.flag_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Fitness Level'),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: _fitnessLevels.map((lvl) {
                                final selected = _fitnessLevel == lvl;
                                return ChoiceChip(
                                  label: Text(lvl),
                                  selected: selected,
                                  selectedColor: AppColors.limeAccent
                                      .withValues(alpha: 0.25),
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.limeAccentDark
                                        : AppColors.borderSubtle,
                                  ),
                                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _fitnessLevel = lvl),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            _SectionLabel('Primary Goal'),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: _primaryGoals.map((goal) {
                                final selected = _primaryGoal == goal;
                                return ChoiceChip(
                                  label: Text(goal),
                                  selected: selected,
                                  selectedColor: AppColors.limeAccent
                                      .withValues(alpha: 0.25),
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.limeAccentDark
                                        : AppColors.borderSubtle,
                                  ),
                                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _primaryGoal = goal),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            _SectionLabel('Training Experience'),
                            const SizedBox(height: AppSpacing.xs),
                            DropdownButtonFormField<String>(
                              key: ValueKey('exp_$_trainingExperience'),
                              isExpanded: true,
                              initialValue: _trainingExperience,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.timeline_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              items: _experienceOptions.map((exp) {
                                return DropdownMenuItem<String>(
                                  value: exp,
                                  child: Text(
                                    exp,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _trainingExperience = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 3. Weekly Schedule & Session Duration
                      InfoCard(
                        title: 'Weekly Schedule & Session Duration',
                        subtitle:
                            'Balances training volume with rest days based on your availability.',
                        icon: Icons.calendar_month_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Training Days per Week'),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: _dayOptions.map((days) {
                                final selected = _trainingDaysPerWeek == days;
                                return ChoiceChip(
                                  label: Text('$days days'),
                                  selected: selected,
                                  selectedColor: AppColors.limeAccent
                                      .withValues(alpha: 0.25),
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.limeAccentDark
                                        : AppColors.borderSubtle,
                                  ),
                                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  onSelected: (_) => setState(
                                    () => _trainingDaysPerWeek = days,
                                  ),
                                );
                              }).toList(),
                            ),
                            if (_fitnessLevel == 'Beginner' &&
                                _trainingDaysPerWeek > 3) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Note: Beginner plans safely cap full-body lifting at 3 days/week to prioritize recovery and form mastery.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),

                            _SectionLabel('Preferred Workout Duration'),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: _durationOptions.map((mins) {
                                final selected =
                                    _workoutDurationMinutes == mins;
                                return ChoiceChip(
                                  label: Text('$mins min'),
                                  selected: selected,
                                  selectedColor: AppColors.limeAccent
                                      .withValues(alpha: 0.25),
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.limeAccentDark
                                        : AppColors.borderSubtle,
                                  ),
                                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  onSelected: (_) => setState(
                                    () => _workoutDurationMinutes = mins,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 4. Location & Equipment
                      InfoCard(
                        title: 'Workout Location & Equipment',
                        subtitle:
                            'Exercises automatically adapt to the equipment available where you train.',
                        icon: Icons.fitness_center_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Primary Training Location'),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: _locationOptions.map((loc) {
                                final selected = _workoutLocation == loc;
                                return ChoiceChip(
                                  avatar: Icon(
                                    loc == 'Gym'
                                        ? Icons.apartment_rounded
                                        : Icons.home_outlined,
                                    size: 16,
                                    color: selected
                                        ? AppColors.darkCharcoal
                                        : AppColors.textSecondary,
                                  ),
                                  label: Text(loc),
                                  selected: selected,
                                  selectedColor: AppColors.limeAccent
                                      .withValues(alpha: 0.25),
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.limeAccentDark
                                        : AppColors.borderSubtle,
                                  ),
                                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _workoutLocation = loc),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            _SectionLabel('Available Equipment'),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: _equipmentOptions.map((eq) {
                                final selected =
                                    _availableEquipment.contains(eq);
                                return FilterChip(
                                  label: Text(eq),
                                  selected: selected,
                                  selectedColor: AppColors.limeAccent
                                      .withValues(alpha: 0.25),
                                  checkmarkColor: AppColors.darkCharcoal,
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.limeAccentDark
                                        : AppColors.borderSubtle,
                                  ),
                                  labelStyle: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                  onSelected: (val) {
                                    setState(() {
                                      if (val) {
                                        if (!_availableEquipment.contains(eq)) {
                                          _availableEquipment.add(eq);
                                        }
                                      } else {
                                        _availableEquipment.remove(eq);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 5. Preferred Exercises & Exercises to Avoid
                      InfoCard(
                        title: 'Exercise Preferences (Optional)',
                        subtitle:
                            'Highlight exercises you enjoy or avoid movements that feel uncomfortable.',
                        icon: Icons.tune_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _SectionLabel('Preferred Exercises'),
                                ),
                                Text(
                                  '${_preferredExercises.length} selected',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.limeAccentDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: _selectableExerciseNames.map((name) {
                                final selected =
                                    _preferredExercises.contains(name);
                                return FilterChip(
                                  label: Text(name),
                                  selected: selected,
                                  selectedColor: AppColors.limeAccent
                                      .withValues(alpha: 0.25),
                                  checkmarkColor: AppColors.darkCharcoal,
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.limeAccentDark
                                        : AppColors.borderSubtle,
                                  ),
                                  labelStyle: AppTextStyles.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                  onSelected: (val) {
                                    setState(() {
                                      if (val) {
                                        if (!_preferredExercises
                                            .contains(name)) {
                                          _preferredExercises.add(name);
                                        }
                                        _avoidExercises.remove(name);
                                      } else {
                                        _preferredExercises.remove(name);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            Row(
                              children: [
                                Expanded(
                                  child: _SectionLabel('Exercises to Avoid'),
                                ),
                                Text(
                                  '${_avoidExercises.length} avoided',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: _selectableExerciseNames.map((name) {
                                final selected = _avoidExercises.contains(name);
                                return FilterChip(
                                  label: Text(name),
                                  selected: selected,
                                  selectedColor: AppColors.warningBg,
                                  checkmarkColor: AppColors.warning,
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.warning
                                        : AppColors.borderSubtle,
                                  ),
                                  labelStyle: AppTextStyles.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                  onSelected: (val) {
                                    setState(() {
                                      if (val) {
                                        if (!_avoidExercises.contains(name)) {
                                          _avoidExercises.add(name);
                                        }
                                        _preferredExercises.remove(name);
                                      } else {
                                        _avoidExercises.remove(name);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 6. Optional Injuries, Limitations & Health Considerations
                      InfoCard(
                        title: 'Injuries, Limitations & Health Notes',
                        subtitle:
                            'Optional — you may skip this section if you have no concerns.',
                        icon: Icons.health_and_safety_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _injuriesController,
                              maxLines: 3,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText:
                                    'Injuries, limitations, or health concerns (Optional — you may skip)',
                                hintText:
                                    'e.g., sensitive lower back, recovering knee, or leave blank to skip',
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.roundedMd,
                                border: Border.all(
                                  color: _hasMedicalClearanceNotice
                                      ? AppColors.warning.withValues(alpha: 0.45)
                                      : AppColors.borderSubtle,
                                ),
                              ),
                              child: Material(
                                color: _hasMedicalClearanceNotice
                                    ? AppColors.warningBg
                                    : AppColors.cardSubtleBg,
                                borderRadius: AppRadius.roundedMd,
                                clipBehavior: Clip.antiAlias,
                                child: SwitchListTile(
                                  value: _hasMedicalClearanceNotice,
                                  activeThumbColor: AppColors.darkCharcoal,
                                  activeTrackColor: AppColors.limeAccent,
                                  title: Text(
                                    'Display professional guidance notice for health conditions',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Enable if you have an injury, chronic condition, or medical limitation. Advises consulting a qualified healthcare professional before strenuous exercise.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  onChanged: (val) => setState(
                                    () => _hasMedicalClearanceNotice = val,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      TrainingSafetyBanner(
                        hasMedicalConcern: showMedicalWarning,
                        isSampleData: profile.isSampleData,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Save & Generate CTA
                      PrimaryButton(
                        label: 'Save Profile & Generate Weekly Plan',
                        icon: Icons.auto_awesome_rounded,
                        isFullWidth: true,
                        isLoading: _isSaving,
                        onPressed: () => _saveAndGenerate(profile),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetricsGrid(double maxWidth) {
    final fields = <Widget>[
      TextFormField(
        controller: _ageController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Age (years)',
          hintText: '14–95',
          prefixIcon: Icon(Icons.cake_outlined, size: 18),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return 'Age is required';
          final age = int.tryParse(text);
          if (age == null || age < 14 || age > 95) {
            return 'Enter age 14–95';
          }
          return null;
        },
      ),
      TextFormField(
        controller: _heightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Height (cm)',
          hintText: '100–250',
          prefixIcon: Icon(Icons.height_rounded, size: 18),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return 'Height is required';
          final height = double.tryParse(text);
          if (height == null || height < 100 || height > 250) {
            return 'Enter 100–250 cm';
          }
          return null;
        },
      ),
      TextFormField(
        controller: _weightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Current Weight (kg)',
          hintText: '30–250',
          prefixIcon: Icon(Icons.monitor_weight_outlined, size: 18),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return 'Weight is required';
          final weight = double.tryParse(text);
          if (weight == null || weight < 30 || weight > 250) {
            return 'Enter 30–250 kg';
          }
          return null;
        },
      ),
      TextFormField(
        controller: _targetWeightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Target Weight (kg, Optional)',
          hintText: 'Optional (30–250)',
          prefixIcon: Icon(Icons.track_changes_outlined, size: 18),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return null;
          final weight = double.tryParse(text);
          if (weight == null || weight < 30 || weight > 250) {
            return 'Enter 30–250 kg or leave blank';
          }
          return null;
        },
      ),
    ];

    if (maxWidth >= 900) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            Expanded(child: fields[i]),
            if (i < fields.length - 1) const SizedBox(width: AppSpacing.md),
          ],
        ],
      );
    }

    if (maxWidth >= 560) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: fields[0]),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: fields[1]),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: fields[2]),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: fields[3]),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        for (int i = 0; i < fields.length; i++) ...[
          fields[i],
          if (i < fields.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.titleMedium.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SampleBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Text(
        'SAMPLE DATA',
        style: AppTextStyles.badge.copyWith(color: AppColors.warning),
      ),
    );
  }
}
