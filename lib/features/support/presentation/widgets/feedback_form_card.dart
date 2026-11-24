import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/support_feedback.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';

/// Card providing form submission for "Submit Feedback" and "Report an Issue",
/// with category selection, subject, multiline message, field validation,
/// and confirmation display only upon successful submission.
class FeedbackFormCard extends ConsumerStatefulWidget {
  const FeedbackFormCard({super.key});

  @override
  ConsumerState<FeedbackFormCard> createState() => _FeedbackFormCardState();
}

class _FeedbackFormCardState extends ConsumerState<FeedbackFormCard> {
  final _formKey = GlobalKey<FormState>();

  String _submissionType = 'feedback'; // 'feedback' or 'issue'
  String? _selectedCategory;
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;
  SupportFeedback? _confirmedSubmission;

  static const List<String> _feedbackCategories = [
    'General Experience',
    'Facility & Equipment',
    'Classes & Group Training',
    'Staff & Personal Coaching',
    'Mobile App Suggestion',
  ];

  static const List<String> _issueCategories = [
    'Broken/Damaged Equipment',
    'Cleanliness & Maintenance',
    'Billing & Receipt Discrepancy',
    'Class Schedule Issue',
    'Mobile App Bug',
  ];

  List<String> get _currentCategories =>
      _submissionType == 'issue' ? _issueCategories : _feedbackCategories;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _switchType(String type) {
    if (_submissionType != type) {
      setState(() {
        _submissionType = type;
        _selectedCategory = null;
        _confirmedSubmission = null;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _confirmedSubmission = null;
      _selectedCategory = null;
      _subjectController.clear();
      _messageController.clear();
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(supportRepositoryProvider);
      final member = await ref.read(currentMemberProvider.future);

      final result = await repo.submitFeedback(
        memberId: member.id,
        category: _selectedCategory!,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        type: _submissionType,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _confirmedSubmission = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _submissionType == 'issue'
                  ? 'Issue report submitted successfully! Ticket #${result.id}'
                  : 'Feedback received! Thank you for helping us improve.',
            ),
            backgroundColor: AppColors.darkCharcoal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildConfirmationView(SupportFeedback submission) {
    final isIssue = submission.type == 'issue';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.successBg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isIssue
                ? 'Issue Report Submitted Successfully'
                : 'Thank You for Your Feedback!',
            style: AppTextStyles.h3.copyWith(color: AppColors.darkCharcoal),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'Reference ID: ${submission.id}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.limeAccent,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isIssue
                ? 'Your incident ticket has been assigned to the gym facility maintenance team. Urgent safety items are audited daily by facility leadership.'
                : 'Your suggestions have been recorded and forwarded to the club management team. Member feedback directly shapes our workout schedules and facility upgrades.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SecondaryButton(
            label: isIssue ? 'Report Another Issue' : 'Submit Another Feedback',
            icon: Icons.refresh_rounded,
            onPressed: _resetForm,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIssue = _submissionType == 'issue';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Description
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isIssue ? Icons.report_problem_outlined : Icons.rate_review_outlined,
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
                      isIssue ? 'Report an Issue' : 'Submit Member Feedback',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isIssue
                          ? 'Report broken gym equipment, cleanliness issues, or billing concerns.'
                          : 'Share your club ideas, trainer compliments, or service suggestions.',
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

          // Type Selector: Submit Feedback vs Report an Issue
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.cardSubtleBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () => _switchType('feedback'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isIssue
                            ? AppColors.darkCharcoal
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 16,
                            color: !isIssue
                                ? AppColors.limeAccent
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              'Submit Feedback',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: !isIssue
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () => _switchType('issue'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isIssue
                            ? AppColors.darkCharcoal
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.report_problem_outlined,
                            size: 16,
                            color: isIssue
                                ? AppColors.limeAccent
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              'Report an Issue',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isIssue
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Display Confirmation View if submitted, else Form
          if (_confirmedSubmission != null)
            _buildConfirmationView(_confirmedSubmission!)
          else
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Dropdown
                  Text(
                    'Category *',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String>(
                    key: ValueKey('category_${_submissionType}_$_selectedCategory'),
                    isExpanded: true,
                    initialValue: _selectedCategory,
                    hint: Text(
                      isIssue
                          ? 'Select issue category'
                          : 'Select feedback category',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    items: _currentCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(
                          cat,
                          style: AppTextStyles.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategory = val);
                    },
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cardSubtleBg,
                      prefixIcon: const Icon(Icons.category_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide:
                            const BorderSide(color: AppColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide:
                            const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(
                          color: AppColors.limeAccentDark,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Subject Field
                  Text(
                    'Subject *',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      hintText: isIssue
                          ? 'e.g. Broken cable on Cable Cross Station #2'
                          : 'e.g. Suggestion for Saturday morning Yoga class',
                      prefixIcon: const Icon(Icons.title_rounded, size: 20),
                      filled: true,
                      fillColor: AppColors.cardSubtleBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide:
                            const BorderSide(color: AppColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide:
                            const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(
                          color: AppColors.limeAccentDark,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Subject is required';
                      }
                      if (val.trim().length < 3) {
                        return 'Subject must be at least 3 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Message Field
                  Text(
                    'Message *',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: isIssue
                          ? 'Please describe the issue in detail, including equipment location or specific date/time...'
                          : 'Please share your experience, ideas, or appreciation for gym staff...',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: AppColors.cardSubtleBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide:
                            const BorderSide(color: AppColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide:
                            const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(
                          color: AppColors.limeAccentDark,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Message is required';
                      }
                      if (val.trim().length < 10) {
                        return 'Please provide a more detailed message (minimum 10 characters)';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Submit Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: PrimaryButton(
                      label: _isSubmitting
                          ? 'Submitting...'
                          : (isIssue
                              ? 'Submit Issue Report'
                              : 'Submit Feedback'),
                      icon: isIssue
                          ? Icons.send_rounded
                          : Icons.rate_review_outlined,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? () {} : _handleSubmit,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
