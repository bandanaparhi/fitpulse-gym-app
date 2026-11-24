/// Represents a member feedback or issue report submission.
class SupportFeedback {
  final String id;
  final String memberId;
  final String category;
  final String subject;
  final String message;
  final String type; // 'feedback' or 'issue'
  final DateTime createdAt;
  final String status; // 'Submitted', 'In Review', 'Resolved'

  const SupportFeedback({
    required this.id,
    required this.memberId,
    required this.category,
    required this.subject,
    required this.message,
    required this.type,
    required this.createdAt,
    this.status = 'Submitted',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'category': category,
      'subject': subject,
      'message': message,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory SupportFeedback.fromMap(Map<String, dynamic> map) {
    return SupportFeedback(
      id: map['id'] as String,
      memberId: map['memberId'] as String,
      category: map['category'] as String,
      subject: map['subject'] as String,
      message: map['message'] as String,
      type: map['type'] as String? ?? 'feedback',
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: map['status'] as String? ?? 'Submitted',
    );
  }
}
