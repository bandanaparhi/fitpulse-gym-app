import 'package:material_ui/material_ui.dart';

/// Centralized color palette for the Gym Management Application.
///
/// Follows a modern, premium commercial fitness aesthetic:
/// - Dark brand surface (#121417)
/// - Clean, light neutral background (#F6F7F9)
/// - Vibrant lime-green accent (#84CC16) for fitness indicators and primary CTAs
/// - Accessible contrast and restrained status colors
class AppColors {
  AppColors._();

  // Primary Dark Palette (Sidebar, Header, Deep accents)
  static const Color darkCharcoal = Color(0xFF121417);
  static const Color darkSurface = Color(0xFF16191E);
  static const Color darkElevated = Color(0xFF1E2228);
  static const Color darkBorder = Color(0xFF2A2F37);

  // Lime-Green Accent (Fitness indicator, Active states, Primary CTAs)
  static const Color limeAccent = Color(0xFF84CC16); // Vibrant energetic lime #84CC16
  static const Color limeAccentLight = Color(0xFFE9F4D7); // Light green surface #E9F4D7
  static const Color limeAccentDark = Color(0xFF4D7C0F);
  static const Color limeAccentHover = Color(0xFF65A30D); // Primary hover #65A30D
  static const Color lightGreenSurface = Color(0xFFE9F4D7);

  // Light Neutral Backgrounds (Main content, Cards)
  static const Color scaffoldBackground = Color(0xFFF6F7F9);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardSubtleBg = Color(0xFFF9FAFB);

  // Neutral Borders & Dividers
  static const Color borderSubtle = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD1D5DB);

  // Typography Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnDark = Color(0xFFF9FAFB);
  static const Color textOnDarkMuted = Color(0xFF94A3B8);

  // Status & Feedback Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFDBEAFE);
}
