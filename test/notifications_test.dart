import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/notifications/presentation/notifications_screen.dart';
import 'package:app/app/providers.dart';
import 'package:app/data/models/notification_item.dart';

void main() {
  group('Notifications Feature Test Suite', () {
    testWidgets('NotificationsScreen renders notifications with title, description, timestamp, and related actions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotificationsScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Title & Subtitle
      expect(find.text('Notifications & Alerts'), findsOneWidget);
      expect(find.textContaining('Stay updated on your class bookings'), findsOneWidget);

      // Filters
      expect(find.text('All Notifications'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);

      // Notifications content
      expect(find.text('Class Booking Confirmed'), findsOneWidget);
      expect(find.textContaining('High-Octane Spin Revolution'), findsOneWidget);
      expect(find.text('View Reservation'), findsOneWidget);

      expect(find.text('Milestone Unlocked! 🎯'), findsOneWidget);
      expect(find.textContaining('18 visits this month'), findsOneWidget);
      expect(find.text('View Attendance'), findsOneWidget);

      expect(find.text('Coach Jordan Lee Session Check-in'), findsOneWidget);
      expect(find.text('View Session Details'), findsOneWidget);

      expect(find.text('Payment Receipt Available'), findsOneWidget);
      expect(find.textContaining('INV-2026-0042'), findsOneWidget);
      expect(find.text('View Tax Invoice'), findsOneWidget);

      expect(find.text('Membership Status: Active'), findsOneWidget);
      expect(find.text('View Membership'), findsOneWidget);

      expect(find.text('Lean Muscle Diet Protocol Assigned'), findsOneWidget);
      expect(find.text('View Diet Plan'), findsOneWidget);

      expect(find.text('Water Intake Reminder'), findsOneWidget);
      expect(find.text('Log Water Intake'), findsOneWidget);

      expect(find.text('Gym Announcement: Holiday Schedule & Maintenance'), findsOneWidget);
      expect(find.text('Read Notice'), findsOneWidget);

      expect(find.text('Membership Expiry & Renewal Reminder'), findsOneWidget);
      expect(find.text('Review Renewal'), findsOneWidget);

      expect(find.text('Active Reminder Channels'), findsOneWidget);
      expect(find.text('Water Intake: ON'), findsOneWidget);
      expect(find.text('Diet: ON'), findsOneWidget);

      // "Mark as Read" buttons are visible on unread notifications
      expect(find.text('Mark as Read'), findsWidgets);
      // Bulk "Mark All as Read" button
      expect(find.text('Mark All as Read'), findsOneWidget);
    });

    testWidgets('Filter chips toggle between All, Unread, and Read views', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotificationsScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap 'Unread' filter
      final unreadFilter = find.text('Unread');
      await tester.tap(unreadFilter);
      await tester.pumpAndSettle();

      // Unread notifications are visible
      expect(find.text('Class Booking Confirmed'), findsOneWidget);
      expect(find.text('Milestone Unlocked! 🎯'), findsOneWidget);
      expect(find.text('Coach Jordan Lee Session Check-in'), findsOneWidget);
      // Read notifications should not be in the list
      expect(find.text('Membership Status: Active'), findsNothing);
      expect(find.text('Lean Muscle Diet Protocol Assigned'), findsNothing);

      // Tap 'Read' filter
      final readFilter = find.text('Read');
      await tester.tap(readFilter);
      await tester.pumpAndSettle();

      // Read notifications are visible
      expect(find.text('Membership Status: Active'), findsOneWidget);
      expect(find.text('Lean Muscle Diet Protocol Assigned'), findsOneWidget);
      expect(find.text('Payment Receipt Available'), findsOneWidget);
      // Unread notifications are hidden
      expect(find.text('Class Booking Confirmed'), findsNothing);

      // Tap 'All Notifications' to reset
      final allFilter = find.text('All Notifications');
      await tester.tap(allFilter);
      await tester.pumpAndSettle();

      expect(find.text('Class Booking Confirmed'), findsOneWidget);
      expect(find.text('Membership Status: Active'), findsOneWidget);
    });

    testWidgets('Individual Mark as Read action updates notification read status', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotificationsScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Locate first "Mark as Read" button
      final markReadBtn = find.text('Mark as Read').first;
      expect(markReadBtn, findsOneWidget);
      await tester.tap(markReadBtn);
      await tester.pumpAndSettle();

      // Confirmation snackbar is shown
      expect(find.textContaining('Marked "Class Booking Confirmed" as read.'), findsOneWidget);
    });

    testWidgets('Bulk Mark All as Read updates all items and triggers feedback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotificationsScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap "Mark All as Read"
      final markAllBtn = find.text('Mark All as Read');
      expect(markAllBtn, findsOneWidget);
      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();

      // Feedback snackbar
      expect(find.text('All notifications marked as read.'), findsOneWidget);

      // Bulk button disappears because unreadCount is 0
      expect(find.text('Mark All as Read'), findsNothing);

      // Switch to Unread tab
      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();

      // All caught up empty state is displayed
      expect(find.text('All Caught Up! 🎉'), findsOneWidget);
      expect(find.textContaining('You have reviewed all your notifications'), findsOneWidget);
    });

    testWidgets('Displays empty state when no notifications exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith(() => _EmptyNotificationsNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationsScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Empty state
      expect(find.text('No Notifications Yet'), findsOneWidget);
      expect(find.textContaining('You currently have no notifications on file.'), findsOneWidget);
    });
  });
}

class _EmptyNotificationsNotifier extends NotificationsNotifier {
  @override
  List<NotificationItem> build() => const [];
}
