/// Gym trainer or personal coach profile.
class Trainer {
  final String id;
  final String name;
  final String specialty;
  final String bio;
  final String? photoUrl;
  final double rating;
  final int totalClients;
  final String phone;
  final String email;
  final List<String> qualifications;
  final List<String> specializations;

  const Trainer({
    required this.id,
    required this.name,
    required this.specialty,
    required this.bio,
    this.photoUrl,
    required this.rating,
    required this.totalClients,
    required this.phone,
    required this.email,
    this.qualifications = const [],
    this.specializations = const [],
  });

  Trainer copyWith({
    String? id,
    String? name,
    String? specialty,
    String? bio,
    String? photoUrl,
    double? rating,
    int? totalClients,
    String? phone,
    String? email,
    List<String>? qualifications,
    List<String>? specializations,
  }) {
    return Trainer(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      totalClients: totalClients ?? this.totalClients,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      qualifications: qualifications ?? this.qualifications,
      specializations: specializations ?? this.specializations,
    );
  }
}
