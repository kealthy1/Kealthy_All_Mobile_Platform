class SubscriptionPlan {
  final String title;
  final String description;
  final double baseRate;
  final int durationDays;
  final String caption;
  final String imageUrl;
  final String name;

  SubscriptionPlan({
    required this.title,
    required this.description,
    required this.baseRate,
    required this.durationDays,
    required this.caption,
    required this.imageUrl,
    required this.name,
  });

  factory SubscriptionPlan.fromFirestore(Map<String, dynamic> json) {
    return SubscriptionPlan(
      title: json['title'],
      description: json['description'],
      baseRate: (json['baseRate'] as num).toDouble(),
      durationDays: json['durationDays'],
      caption: json['caption'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
