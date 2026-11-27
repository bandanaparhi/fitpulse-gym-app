import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../data/models/workout.dart';
import '../../../../shared/widgets/empty_state.dart';

/// Card previewing today's scheduled workout regime matching both
/// Mobile and Desktop design direction screenshots.
class TodayWorkoutCard extends StatelessWidget {
  final Workout? workout;
  final bool isLoading;

  const TodayWorkoutCard({
    super.key,
    required this.workout,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);

    if (isLoading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: isMobile ? AppRadius.roundedLg : AppRadius.roundedLg,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (workout == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: isMobile ? AppRadius.roundedLg : AppRadius.roundedLg,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: EmptyState(
          icon: Icons.bedtime_outlined,
          title: 'Rest Day',
          message: 'No workouts scheduled for today. Focus on recovery and nutrition!',
          actionLabel: 'Browse Workouts',
          onAction: () => context.go('/workouts'),
        ),
      );
    }

    final item = workout!;

    if (isMobile) {
      return _buildMobileCard(context, item);
    }
    return _buildDesktopCard(context, item);
  }

  Widget _buildMobileCard(BuildContext context, Workout item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Expanded(
              child: Text(
                "Today's workout",
                style: AppTextStyles.h3.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            InkWell(
              onTap: () => context.go('/workouts/${item.id}'),
              child: Text(
                'View plan',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.limeAccentDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Workout Card Container
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: AppRadius.roundedXl,
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gym banner image / Graphic header
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF1E293B),
                        Color(0xFF111827),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Atmospheric lighting glow
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.limeAccent.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                      // Athletic silhouette / Dumbbells illustration
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 40,
                              color: AppColors.limeAccent.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FITPULSE TRAINING',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.limeAccent,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item.category.toUpperCase(),
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Title & details
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.level} · ${item.exercises.length} exercises · ${item.durationMinutes} min',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Primary Start Workout Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/workouts/${item.id}/start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.limeAccent,
                          foregroundColor: AppColors.darkCharcoal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                          textStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700),
                        ),
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                        label: const Text('Start Workout'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCard(BuildContext context, Workout item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            "Today's Workout",
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Workout Title
          Text(
            item.title,
            style: AppTextStyles.h3.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Meta Information
          Text(
            '${item.exercises.length} exercises · ${item.durationMinutes} minutes · ${item.level}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Start Workout Button
          ElevatedButton(
            onPressed: () => context.go('/workouts/${item.id}/start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.limeAccent,
              foregroundColor: AppColors.darkCharcoal,
              elevation: 0,
              minimumSize: const Size(140, 44),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
              textStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700),
            ),
            child: const Text('Start Workout'),
          ),
        ],
      ),
    );
  }
}
