/// Membership plan and subscription details.
class Membership {
  final String id;
  final String planName;
  final String status; // 'Active', 'Expiring Soon', 'Expired'
  final DateTime startDate;
  final DateTime expiryDate;
  final double price;
  final String durationMonths;
  final List<String> benefits;

  const Membership({
    required this.id,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.expiryDate,
    required this.price,
    required this.durationMonths,
    required this.benefits,
  });

  bool get isActive => status.toLowerCase() == 'active';

  int get daysRemaining {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }
}
