import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/member.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';

/// Modal dialog allowing members to edit permitted profile information:
/// - Full name
/// - Phone number
/// - Profile photo
/// - Emergency contact
///
/// Explicitly locks Member ID, membership status, and payment records.
class EditProfileDialog extends StatefulWidget {
  final Member member;
  final Future<bool> Function({
    required String name,
    required String phone,
    String? photoUrl,
    String? emergencyContact,
  }) onSave;

  const EditProfileDialog({
    super.key,
    required this.member,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required Member member,
    required Future<bool> Function({
      required String name,
      required String phone,
      String? photoUrl,
      String? emergencyContact,
    }) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => EditProfileDialog(
        member: member,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _photoUrlController;
  late TextEditingController _emergencyContactController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _phoneController = TextEditingController(text: widget.member.phone);
    _photoUrlController =
        TextEditingController(text: widget.member.photoUrl ?? '');
    _emergencyContactController = TextEditingController(
      text: widget.member.emergencyContact ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _photoUrlController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final photoUrl = _photoUrlController.text.trim().isEmpty
        ? null
        : _photoUrlController.text.trim();
    final emergencyContact = _emergencyContactController.text.trim().isEmpty
        ? null
        : _emergencyContactController.text.trim();

    final success = await widget.onSave(
      name: name,
      phone: phone,
      photoUrl: photoUrl,
      emergencyContact: emergencyContact,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.darkCharcoal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              'Failed to update profile. Please verify your details and try again.';
        });
      }
    }
  }

  Widget _buildProtectedField({
    required String label,
    required String value,
    required String tooltip,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: tooltip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.darkCharcoal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Protected',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Member Profile',
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Update your personal contact and emergency details.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.borderSubtle, height: 1),

            // Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Editable Fields Section
                      Text(
                        'Editable Contact Information',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(height: AppSpacing.md),

                // Full Name Field
                Text(
                  'Full Name *',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.cardSubtleBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                        color: AppColors.limeAccentDark,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Phone Number Field
                Text(
                  'Phone Number *',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: 'e.g. +91 98765 43210',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    filled: true,
                    fillColor: AppColors.cardSubtleBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                        color: AppColors.limeAccentDark,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.trim().length < 8) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Profile Photo URL Field
                Text(
                  'Profile Photo URL (Optional)',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _photoUrlController,
                  decoration: InputDecoration(
                    hintText: 'https://example.com/photo.jpg',
                    prefixIcon: const Icon(Icons.image_outlined, size: 20),
                    filled: true,
                    fillColor: AppColors.cardSubtleBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                        color: AppColors.limeAccentDark,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Emergency Contact Field
                Text(
                  'Emergency Contact (Optional)',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _emergencyContactController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Sarah Morgan (+91 98765 99887) - Spouse',
                    prefixIcon: const Icon(Icons.contact_emergency_outlined, size: 20),
                    filled: true,
                    fillColor: AppColors.cardSubtleBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                        color: AppColors.limeAccentDark,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: AppSpacing.lg),

                // Protected Non-Editable Fields Section
                Text(
                  'System-Protected Identity & Membership',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Member ID, membership plan status, and financial billing records are system-governed and cannot be modified.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildProtectedField(
                  label: 'Member ID',
                  value: widget.member.id,
                  tooltip: 'Member ID is an immutable official gym identifier.',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildProtectedField(
                  label: 'Membership Tier & Status',
                  value: '${widget.member.membershipPlan} (${widget.member.membershipStatus})',
                  tooltip: 'Membership plan is governed by active gym contracts.',
                  icon: Icons.card_membership_outlined,
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildProtectedField(
                  label: 'Registered Email (Auth Identity)',
                  value: widget.member.email,
                  tooltip: 'Primary email is linked to account authentication.',
                  icon: Icons.email_outlined,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

      const Divider(color: AppColors.borderSubtle, height: 1),

      // Fixed Action Buttons Footer: Save Changes & Cancel
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.sm),
            PrimaryButton(
              label: _isSaving ? 'Saving...' : 'Save Changes',
              icon: Icons.save_outlined,
              isLoading: _isSaving,
              onPressed: _isSaving ? () {} : _handleSave,
            ),
          ],
        ),
      ),
    ],
  ),
),
);
  }
}
