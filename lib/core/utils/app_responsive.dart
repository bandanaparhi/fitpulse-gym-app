import 'package:material_ui/material_ui.dart';
import '../../app/theme/app_theme.dart';

/// Responsive sizing and spacing helpers for mobile, tablet, and desktop layouts.
class AppResponsive {
  AppResponsive._();

  static const double mobileBreakpoint = 768.0;
  static const double compactBreakpoint = 600.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  /// Outer scroll/page padding: comfortable 20px top on mobile, 24px on tablet/desktop.
  static EdgeInsets pagePadding(BuildContext context) =>
      isMobile(context)
          ? const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 20.0)
          : const EdgeInsets.all(AppSpacing.lg);

  /// Standard card padding: compact 14px on mobile, 24px on tablet/desktop.
  static EdgeInsets cardPadding(BuildContext context) =>
      EdgeInsets.all(isMobile(context) ? 14.0 : AppSpacing.lg);

  /// Hero/feature card padding: compact 16px on mobile, 32px on tablet/desktop.
  static EdgeInsets cardPaddingLg(BuildContext context) =>
      EdgeInsets.all(isMobile(context) ? 16.0 : AppSpacing.xl);

  /// Vertical gap between sections: 14px on mobile, 24px on tablet/desktop.
  static double sectionGap(BuildContext context) =>
      isMobile(context) ? 14.0 : AppSpacing.lg;

  /// Larger vertical gap between major sections: 18px on mobile, 32px on tablet/desktop.
  static double sectionGapLg(BuildContext context) =>
      isMobile(context) ? 18.0 : AppSpacing.xl;
}
