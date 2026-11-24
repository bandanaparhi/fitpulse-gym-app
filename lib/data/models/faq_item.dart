/// Represents an official gym FAQ entry.
class FaqItem {
  final String id;
  final String question;
  final String answer;
  final String category;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
    };
  }

  factory FaqItem.fromMap(Map<String, dynamic> map) {
    return FaqItem(
      id: map['id'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
      category: map['category'] as String,
    );
  }
}
