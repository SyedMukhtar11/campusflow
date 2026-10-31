class FeedbackEntry {
  final String? id;
  final String programId;
  final int rating; // 1-5
  final String category;
  final String email;
  final String comment;
  final DateTime submittedAt;

  const FeedbackEntry({
    this.id,
    required this.programId,
    required this.rating,
    required this.category,
    required this.email,
    required this.comment,
    required this.submittedAt,
  });

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) {
    return FeedbackEntry(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      programId: json['programId']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      category: json['category']?.toString() ?? 'Content',
      email: json['email']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      submittedAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'programId': programId,
      'rating': rating,
      'category': category,
      'email': email,
      'comment': comment,
    };
  }
}
