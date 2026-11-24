import 'package:material_ui/material_ui.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/contact_staff_card.dart';
import 'widgets/faq_section.dart';
import 'widgets/feedback_form_card.dart';

/// Screen displayed at `/support` providing:
/// - Official gym FAQs with search and category filtering
/// - Configured gym staff and front desk contact details
/// - In-app feedback submission
/// - Issue and equipment incident reporting
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            const PageHeader(
              title: 'Help Desk & Support',
              subtitle:
                  'Find answers in our gym FAQs, contact on-site staff, report an issue, or send us member feedback.',
            ),

            const SizedBox(height: AppSpacing.lg),

            // FAQs Section
            const FaqSection(),

            const SizedBox(height: AppSpacing.xl),

            // Contact Gym Staff Card
            const ContactStaffCard(),

            const SizedBox(height: AppSpacing.xl),

            // Submit Feedback & Report an Issue Form
            const FeedbackFormCard(),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
