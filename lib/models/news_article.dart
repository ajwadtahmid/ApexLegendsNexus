class NewsArticle {
  final String title;
  final String description;
  final String link;
  final String imageUrl;

  NewsArticle({
    required this.title,
    required this.description,
    required this.link,
    required this.imageUrl,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
      imageUrl: json['img'] ?? '',
    );
  }
}
