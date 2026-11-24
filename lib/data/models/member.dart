/// Member entity representing a gym member.
class Member {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String membershipId;
  final String membershipPlan;
  final String membershipStatus;
  final DateTime membershipExpiry;
  final int attendanceCountThisMonth;
  final double pendingPaymentAmount;
  final String assignedTrainer;
  final DateTime joinedDate;
  final DateTime? dateOfBirth;
  final String? emergencyContact;

  const Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.membershipId,
    required this.membershipPlan,
    required this.membershipStatus,
    required this.membershipExpiry,
    required this.attendanceCountThisMonth,
    required this.pendingPaymentAmount,
    required this.assignedTrainer,
    required this.joinedDate,
    this.dateOfBirth,
    this.emergencyContact,
  });

  Member copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? membershipId,
    String? membershipPlan,
    String? membershipStatus,
    DateTime? membershipExpiry,
    int? attendanceCountThisMonth,
    double? pendingPaymentAmount,
    String? assignedTrainer,
    DateTime? joinedDate,
    DateTime? dateOfBirth,
    String? emergencyContact,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      membershipId: membershipId ?? this.membershipId,
      membershipPlan: membershipPlan ?? this.membershipPlan,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      membershipExpiry: membershipExpiry ?? this.membershipExpiry,
      attendanceCountThisMonth:
          attendanceCountThisMonth ?? this.attendanceCountThisMonth,
      pendingPaymentAmount: pendingPaymentAmount ?? this.pendingPaymentAmount,
      assignedTrainer: assignedTrainer ?? this.assignedTrainer,
      joinedDate: joinedDate ?? this.joinedDate,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'membershipId': membershipId,
      'membershipPlan': membershipPlan,
      'membershipStatus': membershipStatus,
      'membershipExpiry': membershipExpiry.toIso8601String(),
      'attendanceCountThisMonth': attendanceCountThisMonth,
      'pendingPaymentAmount': pendingPaymentAmount,
      'assignedTrainer': assignedTrainer,
      'joinedDate': joinedDate.toIso8601String(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'emergencyContact': emergencyContact,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      photoUrl: map['photoUrl'] as String?,
      membershipId: map['membershipId'] as String,
      membershipPlan: map['membershipPlan'] as String,
      membershipStatus: map['membershipStatus'] as String,
      membershipExpiry: DateTime.parse(map['membershipExpiry'] as String),
      attendanceCountThisMonth: map['attendanceCountThisMonth'] as int,
      pendingPaymentAmount: (map['pendingPaymentAmount'] as num).toDouble(),
      assignedTrainer: map['assignedTrainer'] as String,
      joinedDate: DateTime.parse(map['joinedDate'] as String),
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      emergencyContact: map['emergencyContact'] as String?,
    );
  }
}
