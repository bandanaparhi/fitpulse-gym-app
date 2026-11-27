import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/attendance_record.dart';
import '../../../../data/models/member.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Interactive Member QR Check-In / Check-Out Pass for gym entry & exit scanning.
class QrCheckinPassCard extends ConsumerStatefulWidget {
  final Member member;

  const QrCheckinPassCard({
    super.key,
    required this.member,
  });

  @override
  ConsumerState<QrCheckinPassCard> createState() => _QrCheckinPassCardState();
}

class _QrCheckinPassCardState extends ConsumerState<QrCheckinPassCard> {
  static const List<String> _zones = [
    'Downtown Main Floor',
    'Cardio & Conditioning Zone',
    'Functional & Mobility Studio',
  ];

  String _selectedZone = _zones.first;
  bool _isSubmitting = false;

  AttendanceRecord? _findActiveSession(List<AttendanceRecord> records) {
    for (final r in records) {
      if (r.checkOut == null) return r;
    }
    return null;
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isSubmitting = true);
    try {
      final created = await ref
          .read(attendanceHistoryProvider.notifier)
          .checkInWithQr(location: _selectedZone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'QR Check-In recorded at ${AppFormatters.formatTime(created.checkIn)} (${created.location}).',
          ),
          backgroundColor: AppColors.darkCharcoal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Check-In failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleCheckOut(AttendanceRecord active) async {
    setState(() => _isSubmitting = true);
    try {
      final updated = await ref
          .read(attendanceHistoryProvider.notifier)
          .checkOutWithQr(active.id);
      if (!mounted) return;
      final outTime = updated?.checkOut ?? DateTime.now();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'QR Check-Out recorded at ${AppFormatters.formatTime(outTime)}.',
          ),
          backgroundColor: AppColors.darkCharcoal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Check-Out failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);
    final records = ref.watch(attendanceHistoryProvider).value ?? const [];
    final activeSession = _findActiveSession(records);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkCharcoal.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: AppResponsive.cardPadding(context),
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
                    color: activeSession != null
                        ? AppColors.limeAccent.withValues(alpha: 0.25)
                        : AppColors.successBg,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: activeSession != null
                              ? AppColors.limeAccentDark
                              : AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activeSession != null ? 'CHECKED IN' : 'ACTIVE',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: activeSession != null
                              ? AppColors.limeAccentDark
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Centered QR Code Scanner Container
            Center(
              child: Container(
                width: isMobile ? 140 : 160,
                height: isMobile ? 140 : 160,
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
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: isMobile ? 82 : 96,
                          color: AppColors.darkCharcoal,
                        ),
                        Text(
                          widget.member.id,
                          style: AppTextStyles.caption.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Member Identity & Instruction
            Text(
              '${widget.member.name} • ${widget.member.id}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              activeSession != null
                  ? 'Checked in at ${AppFormatters.formatTime(activeSession.checkIn)} • ${activeSession.location}'
                  : 'Scan QR at turnstile or tap Check In via QR below',
              style: AppTextStyles.caption.copyWith(
                color: activeSession != null
                    ? AppColors.limeAccentDark
                    : AppColors.textSecondary,
                fontWeight: activeSession != null ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.md),

            if (activeSession == null) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedZone,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'Gym Zone',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                ),
                items: _zones
                    .map(
                      (z) => DropdownMenuItem(
                        value: z,
                        child: Text(z, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (val) {
                        if (val != null) setState(() => _selectedZone = val);
                      },
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              PrimaryButton(
                label: 'Check In via QR',
                icon: Icons.login_rounded,
                isFullWidth: true,
                isLoading: _isSubmitting,
                onPressed: _handleCheckIn,
              ),
            ] else ...[
              PrimaryButton(
                label: 'Check Out via QR',
                icon: Icons.logout_rounded,
                isFullWidth: true,
                isLoading: _isSubmitting,
                onPressed: () => _handleCheckOut(activeSession),
              ),
            ],
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
