class ForumModel {
  final int id;
  final String title;
  final String? content;
  final int authorId;

  ForumModel({
    required this.id,
    required this.title,
    this.content,
    required this.authorId,
  });

  factory ForumModel.fromJson(Map<String, dynamic> json) => ForumModel(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        content: json['content'],
        authorId: json['author_id'] ?? json['authorId'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'author_id': authorId,
      };
}


