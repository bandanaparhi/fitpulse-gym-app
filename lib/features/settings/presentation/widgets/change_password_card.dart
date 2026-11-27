import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Card providing self-service password update functionality:
/// - Current password
/// - New password
/// - Confirm new password
/// - Form validation, inline feedback, and error reporting.
class ChangePasswordCard extends ConsumerStatefulWidget {
  const ChangePasswordCard({super.key});

  @override
  ConsumerState<ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends ConsumerState<ChangePasswordCard> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordChange() async {
    // Clear previous banners
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    final result = await ref.read(authStateProvider.notifier).changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.isSuccess) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _formKey.currentState?.reset();

        setState(() {
          _successMessage = result.message ??
              'Password updated successfully! Your account credentials have been secured.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: AppColors.darkCharcoal,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result.message ??
              'Failed to update password. Please check your credentials and try again.';
        });
      }
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
              onPressed: onToggleObscure,
              tooltip: obscureText ? 'Show password' : 'Hide password',
            ),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: AppResponsive.cardPaddingLg(context),
      child: Form(
        key: _formKey,
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
                  child: const Icon(
                    Icons.security_outlined,
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
                        'Change Password',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Update your authentication credentials to protect your member account.',
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

            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_successMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.limeAccentDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Current Password
            _buildPasswordField(
              controller: _currentPasswordController,
              label: 'Current Password *',
              hintText: 'Enter your existing password',
              obscureText: _obscureCurrent,
              onToggleObscure: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Current password is required';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // New Password
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'New Password *',
              hintText: 'Enter a strong password (minimum 6 characters)',
              obscureText: _obscureNew,
              onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'New password is required';
                }
                if (value.trim().length < 6) {
                  return 'New password must be at least 6 characters long';
                }
                if (value == _currentPasswordController.text) {
                  return 'New password must be different from current password';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Confirm New Password
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password *',
              hintText: 'Re-enter your new password',
              obscureText: _obscureConfirm,
              onToggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please confirm your new password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Submit Button
            Align(
              alignment: Alignment.centerRight,
              child: PrimaryButton(
                label: _isLoading ? 'Updating Password...' : 'Update Password',
                icon: Icons.key_rounded,
                isLoading: _isLoading,
                onPressed: _isLoading ? () {} : _handlePasswordChange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
