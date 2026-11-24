import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/settings/presentation/settings_screen.dart';
import 'package:app/features/settings/presentation/widgets/notification_preferences_card.dart';
import 'package:app/features/settings/presentation/widgets/change_password_card.dart';
import 'package:app/features/settings/presentation/widgets/privacy_information_card.dart';
import 'package:app/features/settings/presentation/widgets/logout_card.dart';
import 'package:app/data/repositories/settings_repository.dart';
import 'package:app/data/repositories/auth_repository.dart';
import 'package:app/app/providers.dart';

void main() {
  group('Settings Feature Test Suite', () {
    testWidgets('SettingsScreen renders all sections: notification preferences, change password, privacy info, and logout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SettingsScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Page Title & Subtitle
      expect(find.text('Application Settings'), findsOneWidget);
      expect(find.textContaining('Manage your notification alerts, security credentials'), findsOneWidget);

      // Section 1: Notification Preferences
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Membership Reminders'), findsOneWidget);
      expect(find.text('Payment Reminders'), findsOneWidget);
      expect(find.text('Workout Reminders'), findsOneWidget);
      expect(find.text('Class Reminders'), findsOneWidget);
      expect(find.text('Gym Announcements'), findsOneWidget);
      expect(find.text('Save Preferences'), findsOneWidget);

      // Section 2: Change Password
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Current Password *'), findsOneWidget);
      expect(find.text('New Password *'), findsOneWidget);
      expect(find.text('Confirm New Password *'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);

      // Section 3: Privacy Information
      expect(find.text('Privacy Information'), findsOneWidget);
      expect(find.text('End-to-End Credential Encryption'), findsOneWidget);
      expect(find.text('Confidential Fitness & Health Metrics'), findsOneWidget);
      expect(find.text('No Third-Party Advertising Sale'), findsOneWidget);
      expect(find.text('View Privacy Policy'), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);

      // Section 4: Logout
      expect(find.text('Account Session'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('Notification preferences can be toggled and saved', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testSettingsRepo = MockSettingsRepository(latency: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(testSettingsRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationPreferencesCard(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Verify all 5 switches are present
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(5));

      // Toggle first switch (Membership Reminders)
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Tap "Save Preferences"
      await tester.tap(find.text('Save Preferences'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Success SnackBar is displayed
      expect(find.text('Notification preferences saved successfully!'), findsOneWidget);

      // Verify repository updated
      expect(testSettingsRepo.preferences.membershipReminders, isFalse);
      expect(testSettingsRepo.preferences.paymentReminders, isTrue);
    });

    testWidgets('ChangePasswordCard validates empty, short, and mismatching passwords', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChangePasswordCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Submit empty form
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      // Check validation error messages
      expect(find.text('Current password is required'), findsOneWidget);
      expect(find.text('New password is required'), findsOneWidget);
      expect(find.text('Please confirm your new password'), findsOneWidget);

      // Enter short password (<6 chars) and mismatching confirm
      final currentField = find.byType(TextFormField).at(0);
      final newField = find.byType(TextFormField).at(1);
      final confirmField = find.byType(TextFormField).at(2);

      await tester.enterText(currentField, 'Password@123');
      await tester.enterText(newField, '123');
      await tester.enterText(confirmField, '456');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('New password must be at least 6 characters long'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('ChangePasswordCard displays error on wrong current password, and updates on valid credentials', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testAuthRepo = HybridAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(testAuthRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ChangePasswordCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final currentField = find.byType(TextFormField).at(0);
      final newField = find.byType(TextFormField).at(1);
      final confirmField = find.byType(TextFormField).at(2);

      // Test incorrect current password
      await tester.enterText(currentField, 'WrongCurrentPass!');
      await tester.enterText(newField, 'ValidNewPass123!');
      await tester.enterText(confirmField, 'ValidNewPass123!');
      await tester.tap(find.text('Update Password'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.textContaining('Current password is incorrect'), findsOneWidget);

      // Test correct current password and update
      await tester.enterText(currentField, 'Password@123');
      await tester.enterText(newField, 'ValidNewPass123!');
      await tester.enterText(confirmField, 'ValidNewPass123!');
      await tester.tap(find.text('Update Password'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.textContaining('Password changed successfully!'), findsWidgets);
    });

    testWidgets('PrivacyInformationCard opens and closes the policy modal dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PrivacyInformationCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Privacy Policy
      await tester.tap(find.text('View Privacy Policy'));
      await tester.pumpAndSettle();

      // Modal content
      expect(find.text('Member Privacy Policy'), findsOneWidget);
      expect(find.text('1. Data Collection & Purpose'), findsOneWidget);
      expect(find.text('2. Zero Advertising & Data Selling'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('1. Data Collection & Purpose'), findsNothing);
    });

    testWidgets('LogoutCard prompts confirmation dialog and can cancel or proceed with logout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testAuthRepo = HybridAuthRepository();

      final testRouter = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(body: LogoutCard()),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: Text('Login Screen View')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(testAuthRepo),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Log Out"
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      // Confirmation dialog should be displayed
      expect(find.text('Confirm Logout'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to log out'), findsOneWidget);

      // Tap "Cancel"
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog is dismissed and auth repository still authenticated
      expect(find.text('Confirm Logout'), findsNothing);
      expect(testAuthRepo.isAuthenticated, isTrue);

      // Tap "Log Out" again and confirm
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      // Tap "Log Out" inside confirmation dialog
      final confirmLogoutBtn = find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Log Out'),
      );
      await tester.tap(confirmLogoutBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Authenticated session cleared and redirected to login screen
      expect(testAuthRepo.isAuthenticated, isFalse);
      expect(testAuthRepo.currentMemberId, isNull);
      expect(find.text('Login Screen View'), findsOneWidget);
    });
  });
}
