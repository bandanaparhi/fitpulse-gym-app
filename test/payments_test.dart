import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/payments/presentation/payment_history_screen.dart';
import 'package:app/features/payments/presentation/payment_details_screen.dart';
import 'package:app/app/providers.dart';

void main() {
  group('Payments Section Test Suite', () {
    testWidgets('PaymentHistoryScreen renders pending status, summary KPIs, actual payment records, and opens receipt modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentHistoryScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Title & Subtitle
      expect(find.text('Payments & Billing History'), findsOneWidget);
      expect(find.textContaining('View official invoices, payment receipts'), findsOneWidget);

      // Pending Status Banner (Alex Morgan has 0 pending dues)
      expect(find.textContaining('All Invoices Settled'), findsOneWidget);

      // Summary KPIs
      expect(find.text('Total Paid to Date'), findsOneWidget);
      expect(find.text('Invoices Paid'), findsOneWidget);
      expect(find.text('Current Outstanding Dues'), findsOneWidget);

      // Transaction Records
      expect(find.text('Transaction History (4)'), findsOneWidget);
      expect(find.text('Annual Premium Membership Subscription (12 Months)'), findsOneWidget);
      expect(find.textContaining('PAY-8921'), findsWidgets);
      expect(find.textContaining('INV-2026-0042'), findsWidgets);
      expect(find.textContaining('₹24,999'), findsWidgets);
      expect(find.textContaining('UPI (Google Pay)'), findsWidgets);
      expect(find.text('PAID'), findsWidgets);

      expect(find.text('Personal Training Coaching Block (10 Sessions with Coach Jordan Lee)'), findsOneWidget);
      expect(find.textContaining('PAY-7450'), findsWidgets);
      expect(find.textContaining('₹8,500'), findsWidgets);

      // Tap "View Receipt" on the first payment record
      final viewReceiptBtn = find.text('View Receipt').first;
      expect(viewReceiptBtn, findsOneWidget);
      await tester.tap(viewReceiptBtn);
      await tester.pumpAndSettle();

      // Official Receipt Modal is rendered
      expect(find.text('FITPULSE GYM & WELLNESS'), findsOneWidget);
      expect(find.text('Official Payment Receipt & Tax Invoice'), findsOneWidget);
      expect(find.text('Billed To'), findsOneWidget);
      expect(find.text('Alex Morgan'), findsWidgets);
      expect(find.textContaining('GM-1024'), findsWidgets);
      expect(find.text('Item Description & Cost'), findsOneWidget);
      expect(find.text('Download PDF'), findsOneWidget);
      expect(find.text('Print'), findsOneWidget);

      // Tap "Download PDF" in Receipt
      final downloadBtn = find.text('Download PDF');
      await tester.tap(downloadBtn);
      await tester.pumpAndSettle();

      // Verify download confirmation snackbar
      expect(find.textContaining('has been downloaded successfully.'), findsOneWidget);
    });

    testWidgets('PaymentDetailsScreen renders transaction ID, date, service, amount, method, status, and receipt actions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentDetailsScreen(paymentId: 'PAY-8921'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Page Title
      expect(find.text('Payment Details'), findsOneWidget);

      // Key details
      expect(find.text('Transaction ID'), findsOneWidget);
      expect(find.text('PAY-8921'), findsWidgets);
      expect(find.text('Official Invoice Number'), findsOneWidget);
      expect(find.text('INV-2026-0042'), findsWidgets);

      expect(find.text('Payment Date & Time'), findsOneWidget);
      expect(find.textContaining('January 1, 2026'), findsOneWidget);

      expect(find.text('Membership / Service'), findsOneWidget);
      expect(find.text('Premium Annual All-Access Membership'), findsOneWidget);

      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('UPI (Google Pay)'), findsOneWidget);

      expect(find.text('Payment Status'), findsOneWidget);
      expect(find.text('Paid'), findsWidgets);

      // Cost & Tax breakdown
      expect(find.text('Tax & Fee Breakdown'), findsOneWidget);
      expect(find.textContaining('Goods & Services Tax (GST 18%)'), findsOneWidget);
      expect(find.textContaining('₹24,999'), findsWidgets);

      // Action Buttons
      expect(find.text('View Official Receipt'), findsOneWidget);
      expect(find.text('Download Receipt (PDF)'), findsOneWidget);

      // Tap Download Receipt (PDF)
      final downloadBtn = find.text('Download Receipt (PDF)');
      await tester.tap(downloadBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('downloaded successfully.'), findsOneWidget);
    });

    testWidgets('Pending payment with unconfigured online gateway shows clear unavailable notice and avoids fake pay now button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override pending payment amount with 3500.0
            pendingPaymentAmountProvider.overrideWith((ref) => Future.value(3500.0)),
            // Gateway is NOT configured
            isPaymentGatewayConfiguredProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PaymentHistoryScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Shows pending amount
      expect(find.textContaining('Pending Payment Due: ₹3,500'), findsOneWidget);

      // Shows clear notice that online payment processing is unavailable
      expect(find.text('Online Payment Processing Unavailable'), findsOneWidget);
      expect(
        find.textContaining('Online payment gateway integration is not configured in this environment.'),
        findsOneWidget,
      );

      // Never shows Pay Now button when gateway is unconfigured
      expect(find.textContaining('Pay Now'), findsNothing);
    });
  });
}
