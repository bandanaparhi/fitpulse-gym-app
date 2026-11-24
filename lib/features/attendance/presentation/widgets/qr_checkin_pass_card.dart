import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/member.dart';

/// Centered Member QR Check-In Pass for gym entry turnstile scanning.
class QrCheckinPassCard extends StatelessWidget {
  final Member member;

  const QrCheckinPassCard({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkCharcoal.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header Row: Centered title and Active Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.limeAccent.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 18,
                          color: AppColors.limeAccentDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Turnstile QR Pass',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ACTIVE',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Centered QR Code Scanner Container
            Center(
              child: Container(
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.darkCharcoal, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.limeAccent.withValues(alpha: 0.12),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Corner targeting brackets
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _buildCornerBracket(isTop: true, isLeft: true),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _buildCornerBracket(isTop: true, isLeft: false),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: _buildCornerBracket(isTop: false, isLeft: true),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _buildCornerBracket(isTop: false, isLeft: false),
                    ),

                    // Central QR Code Graphic Representation
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 96,
                          color: AppColors.darkCharcoal,
                        ),
                        Text(
                          member.id,
                          style: AppTextStyles.caption.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Centered Member ID and Scanning Instruction
            Text(
              '${member.name} • ${member.id}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'Hold this QR code over the turnstile scanner to check in',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket({required bool isTop, required bool isLeft}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppColors.limeAccentDark, width: 2.5)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppColors.limeAccentDark, width: 2.5)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppColors.limeAccentDark, width: 2.5)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppColors.limeAccentDark, width: 2.5)
              : BorderSide.none,
        ),
      ),
    );
  }
}
