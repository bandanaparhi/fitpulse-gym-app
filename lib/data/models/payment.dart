/// Invoice or transaction record for gym membership/services.
class Payment {
  final String id;
  final String memberId;
  final double amount;
  final DateTime date;
  final String status; // 'Paid', 'Pending', 'Failed'
  final String paymentMethod; // 'UPI', 'Credit Card', 'Net Banking', 'Cash'
  final String invoiceNumber;
  final String description;
  final String serviceName;
  final double? subtotal;
  final double? taxAmount;

  const Payment({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.date,
    required this.status,
    required this.paymentMethod,
    required this.invoiceNumber,
    required this.description,
    this.serviceName = '',
    this.subtotal,
    this.taxAmount,
  });

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';

  String get effectiveServiceName =>
      serviceName.isNotEmpty ? serviceName : description;

  double get effectiveSubtotal =>
      subtotal ?? (amount / 1.18);

  double get effectiveTaxAmount =>
      taxAmount ?? (amount - effectiveSubtotal);

  Payment copyWith({
    String? id,
    String? memberId,
    double? amount,
    DateTime? date,
    String? status,
    String? paymentMethod,
    String? invoiceNumber,
    String? description,
    String? serviceName,
    double? subtotal,
    double? taxAmount,
  }) {
    return Payment(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      description: description ?? this.description,
      serviceName: serviceName ?? this.serviceName,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
    );
  }
}
