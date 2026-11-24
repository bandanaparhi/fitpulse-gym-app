import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/attendance/presentation/attendance_screen.dart';
import 'package:app/features/attendance/presentation/widgets/attendance_record_detail_modal.dart';

void main() {
  group('Attendance Screen Test Suite', () {
    testWidgets('AttendanceScreen renders summaries, calendar, and history records', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AttendanceScreen(),
            ),
          ),
        ),
      );

      // Settle async providers
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Page Title & Subtitle
      expect(find.text('Attendance & Visits'), findsOneWidget);

      // KPI Summaries calculated from actual records
      expect(find.text('18'), findsWidgets); // 18 visits in November / current month
      expect(find.textContaining('Visits in'), findsWidgets);
      expect(find.textContaining('Total Visits in'), findsWidgets);
      expect(find.text('Avg Visit Duration'), findsOneWidget);
      expect(find.text('Attendance Consistency'), findsOneWidget);

      // Calendar components
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.textContaining('Attended ('), findsOneWidget);
      expect(find.text('Rest Day'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);

      // Attendance history section
      expect(find.text('Attendance History'), findsOneWidget);
      expect(find.textContaining('Visits'), findsWidgets);
      expect(find.text('All Locations'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Downtown Main Floor'), findsWidgets);
    });

    testWidgets('Tapping an attendance record opens the read-only detail modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AttendanceScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Find the first attendance card and tap it
      final firstCard = find.text('Downtown Main Floor').first;
      await tester.ensureVisible(firstCard);
      await tester.tap(firstCard);
      await tester.pumpAndSettle();

      // Verify modal opened
      expect(find.byType(AttendanceRecordDetailModal), findsOneWidget);
      expect(find.text('Attendance Record'), findsOneWidget);
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.textContaining('GM-1024'), findsWidgets);
      expect(find.text('Check-In Time'), findsOneWidget);
      expect(find.text('Check-Out Time'), findsOneWidget);
      expect(find.text('Total Session Duration'), findsOneWidget);

      // Verify strictly read-only notice (no edit capabilities)
      expect(find.text('Official Gym Record — Read Only'), findsOneWidget);
      expect(
        find.textContaining('cannot be edited or modified by members'),
        findsOneWidget,
      );

      // Close modal
      final closeButton = find.text('Close');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceRecordDetailModal), findsNothing);
    });

    testWidgets('Changing month via calendar updates displayed records', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AttendanceScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap Previous Month chevron
      final prevMonthButton = find.byTooltip('Previous Month');
      expect(prevMonthButton, findsOneWidget);
      await tester.tap(prevMonthButton);
      await tester.pumpAndSettle();

      // Verify October or previous month records are shown
      expect(find.text('Attendance & Visits'), findsOneWidget);
      expect(find.text('Attendance History'), findsOneWidget);
    });

    testWidgets('Future dates are not marked as missed and empty state is handled', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AttendanceScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Navigate to a distant future month (e.g. Next Month 4 times to March 2027)
      final nextMonthButton = find.byTooltip('Next Month');
      for (int i = 0; i < 4; i++) {
        await tester.tap(nextMonthButton);
        await tester.pumpAndSettle();
      }

      // Check empty state
      expect(find.text('No Visits Found'), findsOneWidget);
      final jumpButton = find.text('Jump to Current Month');
      expect(jumpButton, findsOneWidget);

      // Scroll and tap Jump to Current Month
      await tester.ensureVisible(jumpButton);
      await tester.tap(jumpButton);
      await tester.pumpAndSettle();

      // Should be back to current month with records
      expect(find.text('18'), findsWidgets);
    });
  });
}
