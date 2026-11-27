import 'package:material_ui/material_ui.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/app_responsive.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/contact_staff_card.dart';
import 'widgets/facility_info_and_rules_card.dart';
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
              title: 'Help Desk & Support',
              subtitle:
                  'Find answers in our gym FAQs, contact on-site staff, report an issue, or send us member feedback.',
            ),

            // FAQs Section
            const FaqSection(),

            SizedBox(height: gap),

            // Contact Gym Staff Card
            const ContactStaffCard(),

            SizedBox(height: gap),

            // Gym Facilities, Operating Hours, Holiday Schedule & Gym Rules
            const FacilityInfoAndRulesCard(),

            SizedBox(height: gap),

            // Submit Feedback & Report an Issue Form
            const FeedbackFormCard(),

            SizedBox(height: gap),
          ],
        ),
      ),
    );
  }
}
