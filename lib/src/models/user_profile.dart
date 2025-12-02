import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String role; // 'admin' o 'user'
  final String subscription; // 'free' o 'premium'
  final int views; // número de visualizaciones de cápsulas
  final DateTime? createdAt;

  UserProfile({
    required this.uid,
    required this.role,
    required this.subscription,
    required this.views,
    this.createdAt,
  });

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      role: (d['role'] as String?) ?? 'user',
      subscription: (d['subscription'] as String?) ?? 'free',
      views: (d['views'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'role': role,
        'subscription': subscription,
        'views': views,
        'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      };

  UserProfile copyWith({String? role, String? subscription, int? views}) => UserProfile(
        uid: uid,
        role: role ?? this.role,
        subscription: subscription ?? this.subscription,
        views: views ?? this.views,
        createdAt: createdAt,
      );
}