class Advertisement {
  final int id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? linkUrl;
  final bool isActive;
  final int order;
  final String type;
  final DateTime? startDate;

  Advertisement({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.linkUrl,
    this.isActive = true,
    this.order = 0,
    this.type = 'general',
    this.startDate,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'] ?? '',
      linkUrl: json['link_url'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
      order: json['order'] ?? 0,
      type: json['type'] ?? 'general',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
    );
  }
}
