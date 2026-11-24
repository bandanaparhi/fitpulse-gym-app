import '../models/payment.dart';
import 'mock_data.dart';

/// Contract for payment transactions, invoice history, and receipt retrieval.
abstract class PaymentRepository {
  Future<List<Payment>> getPaymentHistory(String memberId);
  Future<Payment?> getPaymentById(String paymentId);
  Future<double> getPendingBalance(String memberId);
  bool isOnlinePaymentConfigured();
}

/// Centralized mock implementation of PaymentRepository.
class MockPaymentRepository implements PaymentRepository {
  final List<Payment> _payments = List<Payment>.from(MockData.demoPayments);

  @override
  Future<List<Payment>> getPaymentHistory(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _payments.where((p) => p.memberId == memberId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<Payment?> getPaymentById(String paymentId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _payments.firstWhere((p) => p.id == paymentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<double> getPendingBalance(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Based strictly on member record
    return MockData.demoMember.pendingPaymentAmount;
  }

  @override
  bool isOnlinePaymentConfigured() {
    // Returns false because no real payment gateway (Stripe/Razorpay) is hooked up.
    // In accordance with: "Display pending payments and a Pay Now button only when
    // a real payment integration is configured."
    return false;
  }
}
