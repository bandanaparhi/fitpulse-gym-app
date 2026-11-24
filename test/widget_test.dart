import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/app/app.dart';
import 'package:app/core/constants/app_constants.dart';

void main() {
  testWidgets('Gym app loads and displays member dashboard smoke test', (WidgetTester tester) async {
    // Build the GymApp wrapped with ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: GymApp(),
      ),
    );

    // Allow initial async routing and providers to settle
    await tester.pumpAndSettle();

    // Verify application name and member name are displayed
    expect(find.textContaining('FitPulse'), findsWidgets);
    expect(find.textContaining(AppConstants.demoMemberName), findsWidgets);
  });
}
