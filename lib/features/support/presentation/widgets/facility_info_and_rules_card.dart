import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';

/// Displays Gym Facilities, Open & Closing Times, Holiday Schedule notices,
/// and Gym Rules & Etiquette Guidelines grounded in facility data.
class FacilityInfoAndRulesCard extends ConsumerWidget {
  const FacilityInfoAndRulesCard({super.key});

  static const List<({String name, String details, IconData icon})>
      _facilityZones = [
    (
      name: 'Main Strength Deck & Olympic Lifting',
      details: 'Platforms 1–4, calibrated bumper plates, barbells & dumbbells',
      icon: Icons.fitness_center_rounded,
    ),
    (
      name: 'Cardio Mezzanine',
      details: 'Concept2 Rowers, SkiErgs & endurance conditioning machines',
      icon: Icons.directions_run_rounded,
    ),
    (
      name: 'Studio A, Studio B & Mind-Body Studio',
      details: 'Cycle studio, dance cardio floor & yoga / sound bath rooms',
      icon: Icons.self_improvement_rounded,
    ),
    (
      name: 'CrossFit Arena & Boxing Studio',
      details: 'Functional conditioning floor, heavy bags & ringside zone',
      icon: Icons.sports_mma_rounded,
    ),
    (
      name: 'Recovery & Hydrotherapy Suite',
      details: 'Finnish sauna, hydrotherapy suite & cold-plunge recovery zone',
      icon: Icons.spa_outlined,
    ),
    (
      name: 'Locker Rooms & Towel Service',
      details: 'Private shower suites, changing lockers & fresh towel service',
      icon: Icons.checkroom_outlined,
    ),
  ];

  static const List<({String title, String rule})> _gymRules = [
    (
      title: 'Facility Check-In & Access',
      rule:
          'Present your Member ID (GM-1024) or Attendance QR Pass at the front desk scanner upon entry during staffed hours.',
    ),
    (
      title: 'Lifting Platforms & Equipment Hygiene',
      rule:
          'Use safety collars and bumper plates for overhead lifts, wipe down barbells and benches after chalk or use, and re-rack weights.',
    ),
    (
      title: 'Group Class Reservation Etiquette',
      rule:
          'Reserve your spot ahead of time on Classes & Studio Schedules and cancel via My Bookings if unable to attend so seats open for waitlisted members.',
    ),
    (
      title: 'Recovery Suite & Footwear Guidelines',
      rule:
          'Observe scheduled ozone purification and maintenance hours in the recovery zone, and wear clean indoor athletic footwear on studio and lifting floors.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(gymContactInfoProvider);
    final announcements = ref.watch(announcementsProvider);
    final contact = contactAsync.value;
    final operatingHoursText = contact?.operatingHours ??
        'Mon–Sat: 6:00 AM – 10:00 PM | Sun: 7:00 AM – 2:00 PM';

    final holidayNotices = announcements
        .where((a) =>
            a.title.toLowerCase().contains('holiday') ||
            a.category.toLowerCase().contains('maintenance'))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: AppResponsive.cardPaddingLg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  size: 20,
                  color: AppColors.limeAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gym Facilities, Hours & Guidelines',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Training zones, open & closing hours, holiday notices, and club etiquette.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.lg),

          // 1. Open & Closing Hours + Holiday Schedule
          LayoutBuilder(
            builder: (context, constraints) {
              final hoursCard = _InfoPanel(
                title: 'Gym Open & Closing Time',
                icon: Icons.schedule_rounded,
                accent: AppColors.limeAccentDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HoursRow(day: 'Monday – Saturday', time: '6:00 AM – 10:00 PM'),
                    const SizedBox(height: AppSpacing.xs),
                    _HoursRow(day: 'Sunday', time: '7:00 AM – 2:00 PM'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Configured schedule: $operatingHoursText. Access outside staffed hours is restricted for facility maintenance.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );

              final holidayCard = _InfoPanel(
                title: 'Holiday Schedule & Maintenance',
                icon: Icons.event_note_rounded,
                accent: AppColors.warning,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (holidayNotices.isNotEmpty) ...[
                      for (final notice in holidayNotices.take(2))
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notice.title,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notice.shortDescription ?? notice.content,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                    ] else
                      Text(
                        'Standard operating hours apply unless noted below.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Public holiday hours are announced via Official Notices and the Front Desk.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        GoRouter.maybeOf(context)?.go('/announcements');
                      },
                      icon: const Icon(Icons.campaign_outlined, size: 15),
                      label: const Text('View Holiday & Maintenance Notices'),
                    ),
                  ],
                ),
              );

              if (constraints.maxWidth >= 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: hoursCard),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: holidayCard),
                  ],
                );
              }
              return Column(
                children: [
                  hoursCard,
                  const SizedBox(height: AppSpacing.md),
                  holidayCard,
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // 2. Gym Facilities Showcase
          Text(
            'Gym Facilities & Zones',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 780
                  ? 3
                  : (constraints.maxWidth >= 500 ? 2 : 1);
              final rows = <Widget>[];
              for (var i = 0; i < _facilityZones.length; i += cols) {
                final slice = _facilityZones.sublist(
                  i,
                  (i + cols).clamp(0, _facilityZones.length),
                );
                rows.add(
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i + cols < _facilityZones.length
                          ? AppSpacing.sm
                          : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var j = 0; j < cols; j++) ...[
                          if (j > 0) const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: j < slice.length
                                ? _FacilityTile(zone: slice[j])
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

          const SizedBox(height: AppSpacing.lg),

          // 3. Gym Rules & Guidelines
          Text(
            'Gym Rules & Guidelines',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Column(
            children: List.generate(_gymRules.length, (idx) {
              final item = _gymRules[idx];
              return Container(
                margin: EdgeInsets.only(
                  bottom: idx < _gymRules.length - 1 ? AppSpacing.sm : 0,
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardSubtleBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.limeAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '${idx + 1}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.limeAccentDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.rule,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  const _InfoPanel({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              Icon(icon, size: 17, color: accent),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final String day;
  final String time;

  const _HoursRow({required this.day, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            day,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          time,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FacilityTile extends StatelessWidget {
  final ({String name, String details, IconData icon}) zone;

  const _FacilityTile({required this.zone});

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
              Icon(zone.icon, size: 17, color: AppColors.limeAccentDark),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  zone.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            zone.details,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
