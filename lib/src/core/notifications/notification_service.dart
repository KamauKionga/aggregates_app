import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/notification_preferences.dart';
import 'models/app_notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  NotificationService(this._firestore);

  Stream<List<AppNotification>> listenUserNotifications(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppNotification.fromDoc(d)).toList());
  }

  Future<NotificationPreferences> getPreferences(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).collection('preferences').doc('notifications').get();
    return NotificationPreferences.fromMap(snap.data());
  }

  Future<void> setPreferences(String uid, NotificationPreferences prefs) async {
    await _firestore.collection('users').doc(uid).collection('preferences').doc('notifications').set(prefs.toMap(), SetOptions(merge: true));
  }

  Future<void> markAsRead(String uid, String notificationId) async {
    await _firestore.collection('users').doc(uid).collection('notifications').doc(notificationId).update({'read': true});
  }
}