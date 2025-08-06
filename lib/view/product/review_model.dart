// review_model.dart
class ReviewModel {
  final String customerName;
  final int starCount;
  final String feedback;
  final String? id;
  final DateTime? createdAt;

  ReviewModel({
    required this.customerName,
    required this.starCount,
    required this.feedback,
    this.id,
    this.createdAt,
  });

  // A helper to parse from JSON
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      customerName: json['customerName'] ?? '',
      starCount: json['starCount'] is int
          ? json['starCount']
          : int.tryParse(json['starCount']?.toString() ?? '0') ?? 0,
      feedback: json['feedback'] ?? '',
      id: json['_id'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}