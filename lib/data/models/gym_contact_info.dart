/// Represents official gym contact details and facility support availability.
class GymContactInfo {
  final String gymName;
  final String? email;
  final String? phone;
  final String? address;
  final String? operatingHours;
  final String? assignedTrainerName;
  final String? assignedTrainerEmail;

  const GymContactInfo({
    required this.gymName,
    this.email,
    this.phone,
    this.address,
    this.operatingHours,
    this.assignedTrainerName,
    this.assignedTrainerEmail,
  });

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;
  bool get hasEmail => email != null && email!.trim().isNotEmpty;
  bool get hasAddress => address != null && address!.trim().isNotEmpty;
  bool get hasOperatingHours =>
      operatingHours != null && operatingHours!.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'gymName': gymName,
      'email': email,
      'phone': phone,
      'address': address,
      'operatingHours': operatingHours,
      'assignedTrainerName': assignedTrainerName,
      'assignedTrainerEmail': assignedTrainerEmail,
    };
  }

  factory GymContactInfo.fromMap(Map<String, dynamic> map) {
    return GymContactInfo(
      gymName: map['gymName'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      operatingHours: map['operatingHours'] as String?,
      assignedTrainerName: map['assignedTrainerName'] as String?,
      assignedTrainerEmail: map['assignedTrainerEmail'] as String?,
    );
  }
}
