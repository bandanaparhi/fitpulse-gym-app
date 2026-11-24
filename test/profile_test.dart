import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/profile/presentation/profile_screen.dart';
import 'package:app/data/repositories/member_repository.dart';
import 'package:app/app/providers.dart';

void main() {
  group('My Profile Feature Test Suite', () {
    testWidgets('ProfileScreen renders member details: name, member ID, email, phone, DOB, emergency contact', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Page Title & Subtitle
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.textContaining('Manage your membership identity, contact information'), findsOneWidget);

      // Identity & Contact Info
      expect(find.text('Alex Morgan'), findsWidgets);
      expect(find.textContaining('Member ID: GM-1024'), findsOneWidget);
      expect(find.text('PREMIUM • ACTIVE'), findsOneWidget);
      expect(find.text('alex.morgan@fitpulse.com'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('June 15, 1994'), findsOneWidget);
      expect(find.text('Sarah Morgan (+91 98765 99887) - Spouse'), findsOneWidget);

      // "Edit Profile" button is present
      expect(find.text('Edit Profile'), findsOneWidget);

      // Protected Membership Records card
      expect(find.text('Membership Status & Protected Records'), findsOneWidget);
      expect(find.textContaining('Member ID, active subscription plan, and payment histories are system-governed'), findsOneWidget);
      expect(find.text('Active Plan'), findsOneWidget);
      expect(find.text('Payment Ledger'), findsOneWidget);
      expect(find.text('Attendance Consistency'), findsOneWidget);
    });

    testWidgets('Tapping Edit Profile opens EditProfileDialog with prepopulated values and protected badges', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Edit Profile"
      final editBtn = find.text('Edit Profile');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Verify Dialog opens
      expect(find.text('Edit Member Profile'), findsOneWidget);
      expect(find.text('Update your personal contact and emergency details.'), findsOneWidget);

      // Verify form fields contain current values
      expect(find.widgetWithText(TextFormField, 'Alex Morgan'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '+91 98765 43210'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Sarah Morgan (+91 98765 99887) - Spouse'), findsOneWidget);

      // Verify Protected Non-Editable Badges in Dialog
      expect(find.text('System-Protected Identity & Membership'), findsOneWidget);
      expect(find.text('GM-1024'), findsOneWidget);
      expect(find.text('Premium (Active)'), findsOneWidget);
      expect(find.text('alex.morgan@fitpulse.com'), findsWidgets);
      expect(find.text('Protected'), findsNWidgets(3));

      // Action buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('EditProfileDialog validates required full name and phone number', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      // Clear full name and phone
      final nameField = find.byType(TextFormField).at(0);
      final phoneField = find.byType(TextFormField).at(1);

      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      await tester.enterText(phoneField, '');
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Validation errors must be displayed
      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);

      // Enter short name (<2 chars)
      await tester.enterText(nameField, 'A');
      // Enter invalid phone
      await tester.enterText(phoneField, '123');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
      expect(find.text('Please enter a valid phone number'), findsOneWidget);
    });

    testWidgets('Cancel button dismisses dialog without updating profile', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      // Change name to something else
      final nameField = find.widgetWithText(TextFormField, 'Alex Morgan');
      await tester.enterText(nameField, 'Changed Name But Cancelled');
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Edit Member Profile'), findsNothing);

      // Name remains unchanged
      expect(find.text('Alex Morgan'), findsWidgets);
      expect(find.text('Changed Name But Cancelled'), findsNothing);
    });

    testWidgets('Saving changes updates profile data layer and UI reactively', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Use a custom MockMemberRepository to test persistence
      final testRepo = MockMemberRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memberRepositoryProvider.overrideWithValue(testRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      // Modify Name and Emergency Contact
      final nameField = find.widgetWithText(TextFormField, 'Alex Morgan');
      await tester.enterText(nameField, 'Alexander Morgan');
      await tester.pumpAndSettle();

      final phoneField = find.widgetWithText(TextFormField, '+91 98765 43210');
      await tester.enterText(phoneField, '+91 91234 56789');
      await tester.pumpAndSettle();

      final emergencyField = find.widgetWithText(TextFormField, 'Sarah Morgan (+91 98765 99887) - Spouse');
      await tester.enterText(emergencyField, 'David Morgan (+91 98111 22233) - Brother');
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Edit Member Profile'), findsNothing);

      // SnackBar success message
      expect(find.text('Profile updated successfully!'), findsOneWidget);

      // UI reflects updated values
      expect(find.text('Alexander Morgan'), findsWidgets);
      expect(find.text('+91 91234 56789'), findsOneWidget);
      expect(find.text('David Morgan (+91 98111 22233) - Brother'), findsOneWidget);

      // Protected fields still remain exact
      expect(find.textContaining('Member ID: GM-1024'), findsOneWidget);
      expect(find.text('alex.morgan@fitpulse.com'), findsOneWidget);
    });
  });
}
