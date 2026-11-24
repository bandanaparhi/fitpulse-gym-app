import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/auth/presentation/login_screen.dart';
import 'package:app/features/auth/presentation/register_screen.dart';
import 'package:app/features/auth/presentation/forgot_password_screen.dart';

void main() {
  group('Authentication Screens Test Suite', () {
    testWidgets('LoginScreen renders all required elements and toggles password', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify header and fields exist
      expect(find.text('Member Portal Sign In'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Join Gym'), findsOneWidget);

      // Verify show/hide password toggle
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('RegisterScreen validates inputs and shows live password rules', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      expect(find.textContaining('Join'), findsWidgets);
      // Name, Email, Phone, Password, Confirm Password
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.text('PASSWORD REQUIREMENTS'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('At least one uppercase letter (A-Z)'), findsOneWidget);

      // Scroll to and tap submit with empty fields to trigger validation
      final createAccountBtn = find.text('Create Account');
      await tester.ensureVisible(createAccountBtn);
      await tester.pumpAndSettle();
      await tester.tap(createAccountBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your phone number'), findsOneWidget);
    });

    testWidgets('RegisterScreen displays confirmation view on successful submission', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Samantha Reed');
      await tester.enterText(textFields.at(1), 'samantha.reed@fitpulse.com');
      await tester.enterText(textFields.at(2), '9876543210');
      await tester.enterText(textFields.at(3), 'SecurePass@2026');
      await tester.enterText(textFields.at(4), 'SecurePass@2026');

      final createAccountBtn = find.text('Create Account');
      await tester.ensureVisible(createAccountBtn);
      await tester.pumpAndSettle();
      await tester.tap(createAccountBtn);

      // Advance simulated timer
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // Expect registration success view
      expect(find.text('Registration Complete!'), findsOneWidget);
      expect(find.textContaining('Samantha Reed'), findsWidgets);
      expect(find.text('YOUR ASSIGNED MEMBER ID'), findsOneWidget);
      expect(find.text('Go to Member Dashboard'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen submits and displays confirmation message', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Reset Password'), findsOneWidget);

      // Tap reset button
      await tester.tap(find.text('Reset Password'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Expect confirmation message
      expect(find.text('Reset Instructions Sent'), findsOneWidget);
      expect(find.text('Return to Sign In'), findsOneWidget);
      expect(find.text('Resend Email'), findsOneWidget);
    });
  });
}
