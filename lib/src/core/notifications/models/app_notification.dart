import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final Timestamp createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      data: Map<String, dynamic>.from(d['data'] ?? {}),
      read: d['read'] as bool? ?? false,
      createdAt: d['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}