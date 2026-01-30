class Advertisement {
  final int id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? linkUrl;

  Advertisement({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.linkUrl,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'] ?? '',
      linkUrl: json['link_url'],
    );
  }
}
