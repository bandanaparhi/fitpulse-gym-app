/// Member body-transformation photo record (`before` or `after` slot).
class ProgressPhoto {
  final String id;
  final String memberId;
  final String slot; // 'before' | 'after'
  final String fileName;
  final String? imageBase64;
  final String? storagePath;
  final String? signedUrl;
  final DateTime takenAt;
  final double? weightKg;
  final String? notes;

  const ProgressPhoto({
    required this.id,
    required this.memberId,
    required this.slot,
    required this.fileName,
    this.imageBase64,
    this.storagePath,
    this.signedUrl,
    required this.takenAt,
    this.weightKg,
    this.notes,
  });

  ProgressPhoto copyWith({
    String? id,
    String? memberId,
    String? slot,
    String? fileName,
    String? imageBase64,
    String? storagePath,
    String? signedUrl,
    DateTime? takenAt,
    double? weightKg,
    String? notes,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      slot: slot ?? this.slot,
      fileName: fileName ?? this.fileName,
      imageBase64: imageBase64 ?? this.imageBase64,
      storagePath: storagePath ?? this.storagePath,
      signedUrl: signedUrl ?? this.signedUrl,
      takenAt: takenAt ?? this.takenAt,
      weightKg: weightKg ?? this.weightKg,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'slot': slot,
        'fileName': fileName,
        'imageBase64': imageBase64,
        'storagePath': storagePath,
        'signedUrl': signedUrl,
        'takenAt': takenAt.toIso8601String(),
        'weightKg': weightKg,
        'notes': notes,
      };

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) => ProgressPhoto(
        id: json['id'] as String? ?? '',
        memberId: json['memberId'] as String? ?? 'GM-1024',
        slot: json['slot'] as String? ?? 'before',
        fileName: json['fileName'] as String? ?? 'photo.jpg',
        imageBase64: json['imageBase64'] as String?,
        storagePath: json['storagePath'] as String?,
        signedUrl: json['signedUrl'] as String?,
        takenAt: json['takenAt'] != null
            ? DateTime.tryParse(json['takenAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );
}
