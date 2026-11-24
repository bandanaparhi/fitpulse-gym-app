import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/training_session.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/assigned_workout_card.dart';
import 'widgets/session_card.dart';
import 'widgets/trainer_profile_card.dart';

/// Screen displaying the member's assigned personal trainer, upcoming 1-on-1
/// coaching sessions, and customized workout plans at `/trainer`.
class TrainerScreen extends ConsumerWidget {
  const TrainerScreen({super.key});

  Future<void> _handleCancelSession(
    BuildContext context,
    WidgetRef ref,
    TrainingSession session,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref
        .read(trainingSessionsProvider.notifier)
        .cancelSession(session.id);

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Session "${session.sessionTitle}" has been cancelled.',
          ),
          backgroundColor: AppColors.darkCharcoal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel session. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainerAsync = ref.watch(assignedTrainerProvider);
    final sessionsAsync = ref.watch(trainingSessionsProvider);
    final workoutsAsync = ref.watch(trainerAssignedWorkoutsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: trainerAsync.when(
        loading: () => const Center(
          child: LoadingIndicator(
            message: 'Loading your coach profile & training schedule...',
          ),
        ),
        error: (err, stack) => Center(
          child: ErrorState(
            title: 'Failed to load trainer details',
            message: err.toString(),
            onRetry: () => ref.invalidate(assignedTrainerProvider),
          ),
        ),
        data: (trainer) {
          // If no trainer is assigned, display empty state
          if (trainer == null) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeader(
                    title: 'My Trainer',
                    subtitle:
                        'Connect with your personal coach and follow dedicated training regimes.',
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  EmptyState(
                    icon: Icons.sports_outlined,
                    title: 'No Trainer Assigned',
                    message:
                        'You currently do not have a dedicated personal trainer assigned to your account. Please speak with gym administration or front desk staff to be paired with a certified coach suited to your fitness goals.',
                    actionLabel: 'Contact Gym Staff',
                    onAction: () => context.go('/support'),
                  ),
                ],
              ),
            );
          }

          final allSessions = sessionsAsync.value ?? [];
          final upcomingSessions =
              allSessions.where((s) => s.isUpcoming).toList()
                ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
          final previousSessions =
              allSessions.where((s) => !s.isUpcoming).toList()
                ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

          final assignedWorkouts = workoutsAsync.value ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: PageHeader(
                        title: 'My Trainer & Coaching',
                        subtitle:
                            'Connect with your assigned fitness coach, track upcoming personal training sessions, and follow customized workout regimes.',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        side: const BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: const Icon(
                        Icons.fitness_center_rounded,
                        size: 18,
                        color: AppColors.darkCharcoal,
                      ),
                      label: const Text('View Workouts'),
                      onPressed: () => context.go('/workouts'),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Responsive Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 900;

                    final profileWidget = TrainerProfileCard(
                      trainer: trainer,
                      onSendMessage: (msg) => ref
                          .read(trainingSessionsProvider.notifier)
                          .sendMessage(msg),
                    );

                    final coachingAndWorkoutsWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Upcoming 1-on-1 Sessions
                        Row(
                          children: [
                            const Icon(
                              Icons.event_available_rounded,
                              size: 20,
                              color: AppColors.darkCharcoal,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Upcoming Coaching Sessions (${upcomingSessions.length})',
                                style: AppTextStyles.h3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (upcomingSessions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border:
                                  Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Center(
                              child: Text(
                                'No upcoming personal training sessions scheduled. Tap "Contact Coach" to book your next session.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: upcomingSessions.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final session = upcomingSessions[index];
                              return SessionCard(
                                session: session,
                                onCancel: () => _handleCancelSession(
                                  context,
                                  ref,
                                  session,
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: AppSpacing.xl),

                        // Section 2: Assigned Workout Plans
                        Row(
                          children: [
                            const Icon(
                              Icons.assignment_outlined,
                              size: 20,
                              color: AppColors.darkCharcoal,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Assigned Workout Plans (${assignedWorkouts.length})',
                                style: AppTextStyles.h3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Custom workout regimes tailored by Coach ${trainer.name.split(' ').first} for progressive overload and muscle building.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        if (assignedWorkouts.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border:
                                  Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Center(
                              child: Text(
                                'No workout plans assigned yet. Reach out to your coach to build your program.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: assignedWorkouts.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final workout = assignedWorkouts[index];
                              return AssignedWorkoutCard(workout: workout);
                            },
                          ),

                        // Section 3: Previous Coaching History (if any)
                        if (previousSessions.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Row(
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                size: 20,
                                color: AppColors.darkCharcoal,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Past Coaching Sessions (${previousSessions.length})',
                                  style: AppTextStyles.h3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: previousSessions.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final session = previousSessions[index];
                              return SessionCard(session: session);
                            },
                          ),
                        ],
                      ],
                    );

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: profileWidget,
                          ),
                          const SizedBox(width: AppSpacing.xl),
                          Expanded(
                            flex: 6,
                            child: coachingAndWorkoutsWidget,
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profileWidget,
                        const SizedBox(height: AppSpacing.xl),
                        coachingAndWorkoutsWidget,
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
