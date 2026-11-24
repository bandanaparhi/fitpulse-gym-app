import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/primary_button.dart';

/// Temporary placeholder screen for future member features and child routes.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String routePath;
  final IconData icon;
  final String? parameterInfo;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.routePath,
    this.icon = Icons.construction_outlined,
    this.parameterInfo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: title,
            subtitle: 'Route: $routePath',
            showBackButton: context.canPop(),
            onBack: () => context.pop(),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: AppRadius.roundedLg,
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.limeAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: AppColors.limeAccentDark),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: AppRadius.roundedSm,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    routePath,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (parameterInfo != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    parameterInfo!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Text(
                    'This screen is registered in the application router and ready for feature implementation. '
                    'Individual member dashboards, forms, and workflows will be implemented in subsequent phases.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrimaryButton(
                      label: 'Back to Dashboard',
                      icon: Icons.dashboard_outlined,
                      onPressed: () => context.go('/dashboard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
