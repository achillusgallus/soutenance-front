class Flashcard {
  final int id;
  final String question;
  final String answer;
  final int courseId;
  final String courseName;
  final String? category;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.courseId,
    required this.courseName,
    this.category,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] ?? 0,
      question: json['question'] ?? json['titre'] ?? '',
      answer: json['answer'] ?? json['contenu'] ?? '',
      courseId: json['course_id'] ?? 0,
      courseName: json['course_name'] ?? '',
      category: json['category'],
    );
  }
}


