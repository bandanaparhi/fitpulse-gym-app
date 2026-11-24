import 'package:material_ui/material_ui.dart';

/// Centralized color palette for the Gym Management Application.
///
/// Follows a modern, premium aesthetic:
/// - Dark charcoal / near-black navigation & accents
/// - Clean, light neutral background
/// - Vibrant lime-green accent for fitness indicators and primary actions
class AppColors {
  AppColors._();

  // Primary Dark Palette (Sidebar, Header, Deep accents)
  static const Color darkCharcoal = Color(0xFF111418);
  static const Color darkSurface = Color(0xFF16191E);
  static const Color darkElevated = Color(0xFF1E2228);
  static const Color darkBorder = Color(0xFF2A2F37);

  // Lime-Green Accent (Fitness indicator, Active states, Primary CTAs)
  static const Color limeAccent = Color(0xFF84CC16); // Vibrant energetic lime
  static const Color limeAccentLight = Color(0xFFECFDF5);
  static const Color limeAccentDark = Color(0xFF4D7C0F);
  static const Color limeAccentHover = Color(0xFF65A30D);

  // Light Neutral Backgrounds (Main content, Cards)
  static const Color scaffoldBackground = Color(0xFFF7F8FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardSubtleBg = Color(0xFFF9FAFB);

  // Neutral Borders & Dividers
  static const Color borderSubtle = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD1D5DB);

  // Typography Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFF9FAFB);
  static const Color textOnDarkMuted = Color(0xFF9CA3AF);

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFDBEAFE);
}
