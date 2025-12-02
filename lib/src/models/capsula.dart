import 'package:cloud_firestore/cloud_firestore.dart';

class Capsula {
  final String id;
  final String title;
  final String category;
  final String description;
  final String? videoUrl;
  final List<String> attachments; // URLs o nombres
  final DateTime? createdAt;

  Capsula({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.videoUrl,
    this.attachments = const [],
    this.createdAt,
  });

  factory Capsula.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Capsula(
      id: doc.id,
      title: d['title'] ?? '',
      category: d['category'] ?? '',
      description: d['description'] ?? '',
      videoUrl: d['videoUrl'] as String?,
      attachments: (d['attachments'] as List?)?.cast<String>() ?? const [],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'description': description,
        'videoUrl': videoUrl,
        'attachments': attachments,
        'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      };
}
