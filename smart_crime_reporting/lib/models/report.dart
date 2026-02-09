class CrimeReport {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category; // theft, harassment, violence, other...
  final String locationText; // simple text; later you can add GPS
  final bool anonymous;
  final bool isPublic;
  final String status; // submitted, under_review, resolved
  final List<String> evidenceUrls;
  final DateTime createdAt;

  CrimeReport({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.locationText,
    required this.anonymous,
    required this.isPublic,
    required this.status,
    required this.evidenceUrls,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'description': description,
        'category': category,
        'locationText': locationText,
        'anonymous': anonymous,
        'isPublic': isPublic,
        'status': status,
        'evidenceUrls': evidenceUrls,
        'createdAt': createdAt.toUtc(),
      };

  static CrimeReport fromMap(String id, Map<String, dynamic> map) {
    return CrimeReport(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'other',
      locationText: map['locationText'] ?? '',
      anonymous: map['anonymous'] ?? false,
      isPublic: map['isPublic'] ?? false,
      status: map['status'] ?? 'submitted',
      evidenceUrls: List<String>.from(map['evidenceUrls'] ?? const []),
      createdAt: (map['createdAt'] as dynamic).toDate(),
    );
  }
}
