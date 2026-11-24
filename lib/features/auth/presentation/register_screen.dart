import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/primary_button.dart';

/// Member Registration Screen with field validation, live password requirements,
/// and post-registration confirmation view.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Registration outcome state
  bool _registrationSuccessful = false;
  String? _registeredMemberId;
  String? _registeredMemberName;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {}); // Rebuild to update live password requirements checklist
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rules = AppValidators.checkPasswordRules(_passwordController.text);
    if (!rules.isFullyCompliant) {
      setState(() {
        _errorMessage = 'Please ensure your password fulfills all security requirements below.';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.register(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        ref.read(authStateProvider.notifier).setAuthenticated(true, result.member?.id);
        setState(() {
          _registrationSuccessful = true;
          _registeredMemberId = result.member?.id ?? 'GM-1025';
          _registeredMemberName = _nameController.text.trim();
        });
      } else {
        setState(() {
          _errorMessage = result.message ?? 'Registration failed. Please check your details.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _registrationSuccessful ? _buildSuccessView() : _buildRegistrationForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    final passwordText = _passwordController.text;
    final confirmPasswordText = _confirmPasswordController.text;
    final passwordRules = AppValidators.checkPasswordRules(passwordText);
    final passwordsMatch = passwordText.isNotEmpty && passwordText == confirmPasswordText;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Branding header
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.limeAccent,
                  borderRadius: AppRadius.roundedMd,
                ),
                child: const Icon(Icons.fitness_center_rounded, color: AppColors.darkCharcoal, size: 30),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Join ${AppConstants.appName}',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Create your member profile to start training',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Error Banner if present
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Full Name Field
            Text('Full Name', style: AppTextStyles.titleMedium.copyWith(fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: AppValidators.validateName,
              decoration: const InputDecoration(
                hintText: 'e.g. Alex Morgan',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Email Address Field
            Text('Email Address', style: AppTextStyles.titleMedium.copyWith(fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: AppValidators.validateEmail,
              decoration: const InputDecoration(
                hintText: 'alex.morgan@fitpulse.com',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Phone Number Field
            Text('Phone Number', style: AppTextStyles.titleMedium.copyWith(fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: AppValidators.validatePhone,
              decoration: const InputDecoration(
                hintText: '+91 98765 43210',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Password Field
            Text('Password', style: AppTextStyles.titleMedium.copyWith(fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: AppValidators.validatePassword,
              decoration: InputDecoration(
                hintText: 'Create a strong password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Confirm Password Field
            Text('Confirm Password', style: AppTextStyles.titleMedium.copyWith(fontSize: 13)),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleRegister(),
              validator: (val) => AppValidators.validateConfirmPassword(val, _passwordController.text),
              decoration: InputDecoration(
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Password Requirements Checklist Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PASSWORD REQUIREMENTS',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildRequirementRow('At least 8 characters', passwordRules.hasMinLength),
                  _buildRequirementRow('At least one uppercase letter (A-Z)', passwordRules.hasUppercase),
                  _buildRequirementRow('At least one numeric digit (0-9)', passwordRules.hasNumber),
                  _buildRequirementRow('At least one special symbol (!@#\$%^&*)', passwordRules.hasSpecialChar),
                  _buildRequirementRow('Passwords match', passwordsMatch),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Submit Button
            PrimaryButton(
              label: 'Create Account',
              icon: Icons.person_add_rounded,
              isLoading: _isLoading,
              isFullWidth: true,
              onPressed: _handleRegister,
            ),
            const SizedBox(height: AppSpacing.md),

            // Back to Login Link
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Already have an account?', style: AppTextStyles.bodyMedium),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Sign In',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String label, bool isSatisfied) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: isSatisfied ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSatisfied ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.limeAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 44),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Registration Complete!',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Welcome to ${AppConstants.appName}, $_registeredMemberName',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Member ID badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Text('YOUR ASSIGNED MEMBER ID', style: AppTextStyles.caption.copyWith(letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(
                  _registeredMemberId ?? 'GM-1025',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.limeAccentDark,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Your member account is active and you have been granted standard access to facility schedules, workouts, and attendance tracking.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          PrimaryButton(
            label: 'Go to Member Dashboard',
            icon: Icons.dashboard_rounded,
            isFullWidth: true,
            onPressed: () => context.go('/dashboard'),
          ),
          const SizedBox(height: AppSpacing.sm),

          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Return to Sign In Screen'),
          ),
        ],
      ),
    );
  }
}
