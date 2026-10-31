class StreamModel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final int viewerCount;

  StreamModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.viewerCount,
  });

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    return StreamModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Live sem título',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      viewerCount: json['viewer_count'] ?? 0,
    );
  }
}

