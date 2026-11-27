import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/classes/presentation/class_listing_screen.dart';
import 'package:app/features/classes/presentation/class_details_screen.dart';
import 'package:app/features/classes/presentation/my_bookings_screen.dart';

void main() {
  group('Classes Section Test Suite', () {
    testWidgets('ClassListingScreen renders classes, instructors, capacities, and filters', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClassListingScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Title & Header
      expect(find.text('Classes & Studio Schedules'), findsOneWidget);
      expect(find.textContaining('Browse group fitness classes'), findsOneWidget);

      // Classes
      expect(find.text('High-Octane Spin Revolution'), findsWidgets);
      expect(find.text('Power Vinyasa Flow Yoga'), findsWidgets);
      expect(find.text('CrossFit Metabolic Conditioning'), findsWidgets);
      expect(find.text('Boxing Conditioning & Heavy Bags'), findsWidgets);

      // Instructors
      expect(find.textContaining('Sara Jenkins'), findsWidgets);
      expect(find.textContaining('Maya Patel'), findsWidgets);
      expect(find.textContaining('Jordan Lee'), findsWidgets);

      // Booked status on already-reserved class
      expect(find.text('Reserved'), findsWidgets);

      // Capacity & Full indicator on CLS-03
      expect(find.text('Class Full'), findsOneWidget);

      // Filter by category: Tap 'All Categories' dropdown
      final categoryDropdown = find.text('All Categories');
      expect(categoryDropdown, findsOneWidget);
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();

      // Select 'Yoga' from the dropdown list
      final yogaItem = find.text('Yoga').last;
      await tester.tap(yogaItem);
      await tester.pumpAndSettle();

      // After filtering by Yoga, only Yoga classes remain
      expect(find.text('Power Vinyasa Flow Yoga'), findsWidgets);
      expect(find.text('Restorative Yin Yoga & Sound Bath'), findsWidgets);
      expect(find.text('CrossFit Metabolic Conditioning'), findsNothing);

      // Reset category to All Categories
      final currentCategory = find.text('Yoga');
      await tester.tap(currentCategory.first);
      await tester.pumpAndSettle();
      final allCategoriesItem = find.text('All Categories').last;
      await tester.tap(allCategoriesItem);
      await tester.pumpAndSettle();

      // Spin is back
      expect(find.text('High-Octane Spin Revolution'), findsWidgets);

      // Toggle 'Available Spots Only'
      final availableToggle = find.text('Available Spots Only');
      expect(availableToggle, findsOneWidget);
      await tester.tap(availableToggle);
      await tester.pumpAndSettle();

      // Full class (CrossFit Metabolic Conditioning) should now be hidden
      expect(find.text('CrossFit Metabolic Conditioning'), findsNothing);
      expect(find.text('Power Vinyasa Flow Yoga'), findsWidgets);
    });

    testWidgets('ClassDetailsScreen renders class information, instructor bio, and booking status', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClassDetailsScreen(classId: 'CLS-02'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Header Details
      expect(find.text('Power Vinyasa Flow Yoga'), findsWidgets);
      expect(find.text('YOGA'), findsWidgets);
      expect(find.text('Maya Patel'), findsWidgets);
      expect(find.text('Mind & Body Studio'), findsWidgets);

      // Description Card
      expect(find.text('Class Description & Experience'), findsOneWidget);
      expect(find.textContaining('Dynamic and breath-synchronized flow'), findsOneWidget);

      // Instructor Bio
      expect(find.text('Instructor Details'), findsOneWidget);
      expect(find.textContaining('RYT-500 certified yoga instructor'), findsOneWidget);

      // Reservation Action Button (CLS-02 is available to book)
      expect(find.text('Confirm & Reserve Spot'), findsOneWidget);
    });

    testWidgets('ClassDetailsScreen prevents duplicate booking when already reserved', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // CLS-01 is already booked in demoBookings (BKG-501)
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClassDetailsScreen(classId: 'CLS-01'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('High-Octane Spin Revolution'), findsWidgets);
      // Reservation banner and button show already booked status
      expect(find.text('RESERVED'), findsWidgets);
      expect(find.text('Already Booked — View Reservation Pass'), findsOneWidget);
    });

    testWidgets('MyBookingsScreen renders upcoming bookings and booking history tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MyBookingsScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Page Title
      expect(find.text('My Class Bookings'), findsOneWidget);
      expect(find.text('Upcoming Reservations'), findsWidgets);
      expect(find.text('Booking History'), findsWidgets);

      // KPI Summaries
      expect(find.text('Sessions Attended'), findsOneWidget);
      expect(find.text('Total Bookings Made'), findsOneWidget);

      // Upcoming reservation: High-Octane Spin Revolution
      expect(find.text('High-Octane Spin Revolution'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('Cancel Reservation'), findsOneWidget);

      // Switch to History tab
      final historyTab = find.text('Booking History');
      await tester.tap(historyTab);
      await tester.pumpAndSettle();

      // Past reservations
      expect(find.text('Power Vinyasa Flow Yoga'), findsOneWidget);
      expect(find.text('ATTENDED'), findsOneWidget);
      expect(find.text('CrossFit Metabolic Conditioning'), findsOneWidget);
      expect(find.text('CANCELLED'), findsOneWidget);
    });

    testWidgets('MyBookingsScreen cancels an upcoming booking with confirmation dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MyBookingsScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('High-Octane Spin Revolution'), findsOneWidget);

      // Click "Cancel Reservation"
      final cancelBtn = find.text('Cancel Reservation');
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Confirmation Dialog appears
      expect(find.text('Cancel Reservation'), findsWidgets);
      expect(find.textContaining('Are you sure you want to cancel your reservation'), findsOneWidget);

      // Confirm cancellation
      final confirmBtn = find.text('Yes, Cancel Reservation');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Upcoming booking is removed, empty state appears
      expect(find.text('No Upcoming Reservations'), findsOneWidget);
    });

    testWidgets('ClassListingScreen switches between Cards and Group Class Timetable views', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClassListingScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cards'), findsOneWidget);
      expect(find.text('Timetable'), findsOneWidget);

      await tester.tap(find.text('Timetable'));
      await tester.pumpAndSettle();

      expect(find.text('High-Octane Spin Revolution'), findsOneWidget);
      expect(find.text('Book'), findsWidgets);
    });
  });
}
