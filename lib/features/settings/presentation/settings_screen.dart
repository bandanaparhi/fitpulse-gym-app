import 'package:material_ui/material_ui.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_responsive.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/change_password_card.dart';
import 'widgets/logout_card.dart';
import 'widgets/notification_preferences_card.dart';
import 'widgets/privacy_information_card.dart';

/// Screen displayed at `/settings` allowing members to configure:
/// - Notification preferences (membership, payment, workout, class, announcements)
/// - Change password credentials
/// - Privacy information & data policy
/// - Logout with confirmation
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gap = AppResponsive.sectionGapLg(context);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            const PageHeader(
              title: 'Application Settings',
              subtitle:
                  'Manage your notification alerts, security credentials, data privacy, and active session.',
            ),

            // Notification Preferences
            const NotificationPreferencesCard(),

            SizedBox(height: gap),

            // Change Password
            const ChangePasswordCard(),

            SizedBox(height: gap),

            // Privacy Information
            const PrivacyInformationCard(),

            SizedBox(height: gap),

            // Logout
            const LogoutCard(),

            SizedBox(height: gap),
          ],
        ),
      ),
    );
  }
}
