import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/app/app.dart';
import 'package:app/app/router.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Shell navigation uses smooth fade transitions without unmounting AppShell', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: GymApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate between top-level sidebar destinations mid-animation and settle.
    appRouter.go('/membership');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(ClipRect), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.textContaining('Membership'), findsWidgets);

    // Navigate to a nested sub-route and pop back cleanly.
    appRouter.go('/workouts/weekly-plan');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(SlideTransition), findsWidgets);
    await tester.pumpAndSettle();

    appRouter.go('/dashboard');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile navigation conforms to design direction with More tab opening drawer', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: GymApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Top bar shows FitPulse branding and avatar
    expect(find.text('FitPulse'), findsWidgets);
    expect(find.text('AM'), findsWidgets);

    // Bottom navigation shows 5 core tabs conforming to screenshot
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Workouts'), findsWidgets);
    expect(find.text('Check-in'), findsWidgets);
    expect(find.text('Classes'), findsWidgets);
    expect(find.text('More'), findsWidgets);

    // Tapping More opens the mobile navigation drawer
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Drawer displays navigation options including Fitness Progress
    expect(find.text('Fitness Progress'), findsWidgets);

    // Tapping Fitness Progress in drawer navigates cleanly
    await tester.tap(find.text('Fitness Progress').last);
    await tester.pumpAndSettle();
    expect(find.text('Fitness Progress & Analytics'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
