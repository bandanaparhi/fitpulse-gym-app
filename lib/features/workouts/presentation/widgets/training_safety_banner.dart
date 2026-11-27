import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';

/// Standard general fitness & safety guidance banner displayed across
/// personalized workout planner screens.
class TrainingSafetyBanner extends StatelessWidget {
  final bool hasMedicalConcern;
  final bool isSampleData;

  const TrainingSafetyBanner({
    super.key,
    this.hasMedicalConcern = false,
    this.isSampleData = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasMedicalConcern ? AppColors.warningBg : AppColors.infoBg,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(
          color: (hasMedicalConcern ? AppColors.warning : AppColors.info)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasMedicalConcern
                ? Icons.health_and_safety_outlined
                : Icons.info_outline_rounded,
            size: 20,
            color: hasMedicalConcern ? AppColors.warning : AppColors.info,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      hasMedicalConcern
                          ? 'Professional Guidance Recommended'
                          : 'General Fitness Guidance Notice',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isSampleData)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: AppRadius.roundedSm,
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          'SAMPLE DATA',
                          style: AppTextStyles.badge.copyWith(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  hasMedicalConcern
                      ? 'You noted an injury, limitation, or health concern. These workout plans are general fitness guidance and not medical treatment or rehabilitation. Please seek clearance from a qualified healthcare professional before strenuous exercise, and stop immediately if you feel sharp pain.'
                      : 'Workout plans provide general fitness guidance and are not medical treatment. Listen to your body, prioritize proper form, and consult a healthcare professional before strenuous training if you have injuries, medical conditions, or are pregnant.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick navigation strip connecting all Workout & Training Planner sub-screens.
class PlannerNavStrip extends StatelessWidget {
  final String currentPath;

  const PlannerNavStrip({super.key, required this.currentPath});

  static const _items = <({String label, String route, IconData icon})>[
    (label: 'Today\'s Workout', route: '/workouts/today', icon: Icons.today_rounded),
    (label: 'My Weekly Plan', route: '/workouts/weekly-plan', icon: Icons.calendar_view_week_rounded),
    (label: 'Fitness Profile', route: '/workouts/profile', icon: Icons.tune_rounded),
    (label: 'Workout History', route: '/workouts/history', icon: Icons.history_rounded),
    (label: 'Personal Records', route: '/workouts/records', icon: Icons.emoji_events_outlined),
    (label: 'Progress & Load', route: '/workouts/training-progress', icon: Icons.trending_up_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _items.map((item) {
        final selected = currentPath == item.route;
        return ActionChip(
          avatar: Icon(
            item.icon,
            size: 16,
            color: selected ? AppColors.darkCharcoal : AppColors.textSecondary,
          ),
          label: Text(
            item.label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.darkCharcoal : AppColors.textPrimary,
            ),
          ),
          backgroundColor: selected
              ? AppColors.limeAccent
              : AppColors.cardBackground,
          side: BorderSide(
            color: selected ? AppColors.limeAccentDark : AppColors.borderSubtle,
          ),
          onPressed: () {
            if (!selected) {
              context.go(item.route);
            }
          },
        );
      }).toList(),
    );
  }
}

/// Interactive Rest Timer dialog accessible from Overview, Today's Workout,
/// and Dashboard.
class RestTimerDialog extends StatefulWidget {
  final int initialSeconds;

  const RestTimerDialog({super.key, this.initialSeconds = 90});

  static Future<void> show(BuildContext context, {int initialSeconds = 90}) {
    return showDialog<void>(
      context: context,
      builder: (_) => RestTimerDialog(initialSeconds: initialSeconds),
    );
  }

  @override
  State<RestTimerDialog> createState() => _RestTimerDialogState();
}

class _RestTimerDialogState extends State<RestTimerDialog> {
  Timer? _timer;
  late int _selectedPreset;
  late int _remaining;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialSeconds;
    _remaining = widget.initialSeconds;
    _startTicker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _timer?.cancel();
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _togglePause() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      if (_remaining == 0) _remaining = _selectedPreset;
      _startTicker();
      setState(() {});
    }
  }

  void _setPreset(int seconds) {
    _selectedPreset = seconds;
    _remaining = seconds;
    _startTicker();
    setState(() {});
  }

  String _format(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.limeAccent.withValues(alpha: 0.2),
              borderRadius: AppRadius.roundedSm,
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: AppColors.limeAccentDark,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text('Rest Timer', style: AppTextStyles.h3),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.darkCharcoal,
                borderRadius: AppRadius.roundedMd,
              ),
              child: Column(
                children: [
                  Text(
                    _remaining == 0 ? 'REST COMPLETE' : 'REST REMAINING',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.limeAccent,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _format(_remaining),
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.textOnDark,
                      fontSize: 40,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.center,
              children: [45, 60, 90, 120, 150].map((sec) {
                final active = _selectedPreset == sec;
                return ChoiceChip(
                  label: Text('${sec}s'),
                  selected: active,
                  selectedColor: AppColors.limeAccent.withValues(alpha: 0.25),
                  onSelected: (_) => _setPreset(sec),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _remaining += 15);
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('+15s'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.limeAccent,
                      foregroundColor: AppColors.darkCharcoal,
                    ),
                    onPressed: _togglePause,
                    icon: Icon(
                      _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    label: Text(_running ? 'Pause' : 'Start'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
