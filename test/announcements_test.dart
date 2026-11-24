import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/announcements/presentation/announcement_listing_screen.dart';
import 'package:app/features/announcements/presentation/announcement_details_screen.dart';
import 'package:app/app/providers.dart';

void main() {
  group('Announcements Feature Test Suite', () {
    testWidgets('AnnouncementListingScreen renders published announcements with title, date, category, and short description', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnnouncementListingScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Page Title & Subtitle
      expect(find.text('Gym Announcements & Notices'), findsOneWidget);
      expect(find.textContaining('Official facility updates, equipment enhancements'), findsOneWidget);

      // Category Chips
      expect(find.text('All Notices'), findsOneWidget);
      expect(find.text('Facility Maintenance'), findsWidgets);
      expect(find.text('Equipment Upgrade'), findsWidgets);
      expect(find.text('Events & Competitions'), findsWidgets);

      // Published Announcements are rendered
      expect(find.text('Holiday Schedule & Facility Maintenance Notice'), findsOneWidget);
      expect(find.textContaining('Spa & recovery suite scheduled ozone purification'), findsOneWidget);
      expect(find.text('Gym Administration'), findsOneWidget);

      expect(find.text('New Rogue Olympic Lifting Platforms Installed'), findsOneWidget);
      expect(find.textContaining('Platforms 3 and 4 upgraded with competition bumper plates'), findsOneWidget);
      expect(find.text('Head Coach Jordan Lee'), findsOneWidget);
      expect(find.textContaining('attachment'), findsWidgets);

      expect(find.text('Spring Functional Fitness Challenge 2026'), findsOneWidget);
      expect(find.textContaining('Annual in-house fitness throwdown'), findsOneWidget);
      expect(find.text('Event Coordinator Sara Jenkins'), findsOneWidget);

      // Draft unpublished announcement must NOT be rendered
      expect(find.text('Draft: Upcoming Steam Room Tile Renovation'), findsNothing);
    });

    testWidgets('Category chips filter announcements correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnnouncementListingScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap 'Equipment Upgrade' filter chip
      final equipmentFilter = find.text('Equipment Upgrade').first;
      await tester.tap(equipmentFilter);
      await tester.pumpAndSettle();

      // Only Equipment Upgrade announcement should be displayed
      expect(find.text('New Rogue Olympic Lifting Platforms Installed'), findsOneWidget);
      expect(find.text('Holiday Schedule & Facility Maintenance Notice'), findsNothing);
      expect(find.text('Spring Functional Fitness Challenge 2026'), findsNothing);

      // Tap 'All Notices' chip to reset
      final allNoticesFilter = find.text('All Notices');
      await tester.tap(allNoticesFilter);
      await tester.pumpAndSettle();

      // All published announcements return
      expect(find.text('Holiday Schedule & Facility Maintenance Notice'), findsOneWidget);
      expect(find.text('New Rogue Olympic Lifting Platforms Installed'), findsOneWidget);
    });

    testWidgets('AnnouncementDetailsScreen renders full content, publication date, and valid attachments', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnnouncementDetailsScreen(announcementId: 'ANN-101'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Page Title & Back Row
      expect(find.text('Announcement Details'), findsOneWidget);

      // Announcement Header & Category
      expect(find.text('Holiday Schedule & Facility Maintenance Notice'), findsOneWidget);
      expect(find.text('FACILITY MAINTENANCE'), findsOneWidget);
      expect(find.text('IMPORTANT'), findsOneWidget);

      // Publication Date & Author
      expect(find.textContaining('Published on'), findsOneWidget);
      expect(find.text('By Gym Administration'), findsOneWidget);

      // Full Content
      expect(
        find.textContaining('hydrotherapy suite, Finnish sauna, and cold-plunge recovery zone'),
        findsOneWidget,
      );

      // Attachments Section
      expect(find.textContaining('Attachments & Documents (1)'), findsOneWidget);
      expect(find.text('Holiday_Operating_Hours_2026.pdf'), findsOneWidget);
      expect(find.textContaining('480 KB'), findsOneWidget);

      // Tap Download on attachment
      final downloadBtn = find.text('Download');
      expect(downloadBtn, findsOneWidget);
      await tester.tap(downloadBtn);
      await tester.pumpAndSettle();

      // Feedback snackbar is shown
      expect(find.textContaining('Opening attachment "Holiday_Operating_Hours_2026.pdf"'), findsOneWidget);
    });

    testWidgets('AnnouncementDetailsScreen handles unpublished drafts and non-existent IDs with empty state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Attempting to open unpublished draft 'ANN-DRAFT'
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnnouncementDetailsScreen(announcementId: 'ANN-DRAFT'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Empty State
      expect(find.text('Announcement Not Found'), findsOneWidget);
      expect(find.textContaining('does not exist or has been archived'), findsOneWidget);
      expect(find.text('Return to Announcements'), findsOneWidget);
    });

    testWidgets('Displays friendly empty state when no announcements exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            announcementsProvider.overrideWithValue(const []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AnnouncementListingScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Empty state
      expect(find.text('No Announcements'), findsOneWidget);
      expect(find.textContaining('There are currently no active announcements from gym administration'), findsOneWidget);
    });
  });
}
