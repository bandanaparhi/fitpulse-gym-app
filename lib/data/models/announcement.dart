/// Attachment file linked to an official gym announcement.
class AnnouncementAttachment {
  final String id;
  final String fileName;
  final String fileType; // 'pdf', 'image', 'document'
  final String fileSize; // e.g. '480 KB', '1.2 MB'
  final String url;

  const AnnouncementAttachment({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.url,
  });
}

/// Official facility announcement from gym management.
class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String author;
  final String priority; // 'Normal', 'Important', 'Urgent'
  final String category; // 'Facility Maintenance', 'Equipment Upgrade', 'Events & Competitions', etc.
  final String? shortDescription;
  final String? bannerImageUrl;
  final bool isPublished;
  final List<AnnouncementAttachment> attachments;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.author,
    this.priority = 'Normal',
    this.category = 'General Notice',
    this.shortDescription,
    this.bannerImageUrl,
    this.isPublished = true,
    this.attachments = const [],
  });

  bool get isUrgent => priority.toLowerCase() == 'urgent';
  bool get isImportant => priority.toLowerCase() == 'important';

  String get effectiveShortDescription {
    if (shortDescription != null && shortDescription!.isNotEmpty) {
      return shortDescription!;
    }
    if (content.length <= 120) return content;
    return '${content.substring(0, 117)}...';
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    String? author,
    String? priority,
    String? category,
    String? shortDescription,
    String? bannerImageUrl,
    bool? isPublished,
    List<AnnouncementAttachment>? attachments,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      author: author ?? this.author,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      shortDescription: shortDescription ?? this.shortDescription,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      isPublished: isPublished ?? this.isPublished,
      attachments: attachments ?? this.attachments,
    );
  }
}
