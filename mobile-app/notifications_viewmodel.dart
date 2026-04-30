import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentName;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.attachmentUrl,
    this.attachmentName,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> data, String id) {
    return NotificationItem(
      id: id,
      title: data['Title'] ?? '',
      message: data['Message'] ?? '',
      timestamp: (data['Timestamp'] as Timestamp).toDate(),
      isRead: data['IsRead'] ?? false,
      attachmentUrl: data['AttachmentUrl'],
      attachmentName: data['AttachmentName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
    };
  }
}

class NotificationsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NotificationItem> _notifications = [];
  List<NotificationItem> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot snapshot =
            await _firestore
                .collection('notifications')
                .where('UserId', isEqualTo: user.uid)
                .orderBy('Timestamp', descending: true)
                .get();
        _notifications =
            snapshot.docs
                .map(
                  (doc) => NotificationItem.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('notifications')
            .doc(id)
            .update({'IsRead': true});
        int index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = NotificationItem(
            id: _notifications[index].id,
            title: _notifications[index].title,
            message: _notifications[index].message,
            timestamp: _notifications[index].timestamp,
            isRead: true,
            attachmentUrl: _notifications[index].attachmentUrl,
            attachmentName: _notifications[index].attachmentName,
          );
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('notifications')
            .doc(id)
            .delete();
        _notifications.removeWhere((n) => n.id == id);
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    notifyListeners();
  }
}
