import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_viewmodel.dart';

class DashboardViewModel extends ChangeNotifier {
  final AuthViewModel _authViewModel;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DashboardViewModel(this._authViewModel);

  // Overview data
  int _documentsUploaded = 0;
  int get documentsUploaded => _documentsUploaded;

  int _qualificationsAdded = 0;
  int get qualificationsAdded => _qualificationsAdded;

  int _trainingCompleted = 0;
  int get trainingCompleted => _trainingCompleted;

  // New fields as per TODO.md
  int _newNotifications = 0;
  int get newNotifications => _newNotifications;

  int _missingDocuments = 0;
  int get missingDocuments => _missingDocuments;

  int _skillsInDemand = 0;
  int get skillsInDemand => _skillsInDemand;

  // Progress tracker data
  double _ratingProgress = 0.0;
  double get ratingProgress => _ratingProgress;

  double _skillsProgress = 0.0;
  double get skillsProgress => _skillsProgress;

  double _documentsProgress = 0.0;
  double get documentsProgress => _documentsProgress;

  // Today's tasks list
  List<String> _todaysTasks = [];
  List<String> get todaysTasks => _todaysTasks;

  // Upcoming deadlines list
  List<Map<String, dynamic>> _upcomingDeadlines = [];
  List<Map<String, dynamic>> get upcomingDeadlines => _upcomingDeadlines;

  // Recent activities list
  List<String> _recentActivities = [];
  List<String> get recentActivities => _recentActivities;

  Future<void> loadDashboardData() async {
    final user = _authViewModel.user;
    if (user == null) {
      // No user logged in
      return;
    }
    final userId = user.uid;

    try {
      // Fetch counts from actual collections
      final trainingsQuery = await _firestore.collection('users').doc(userId).collection('trainings').get();
      _trainingCompleted = trainingsQuery.docs.length;

      final qualificationsQuery = await _firestore.collection('users').doc(userId).collection('qualifications').get();
      _qualificationsAdded = qualificationsQuery.docs.length;

      final documentsQuery = await _firestore.collection('users').doc(userId).collection('documents').get();
      _documentsUploaded = documentsQuery.docs.length;

      final skillsQuery = await _firestore.collection('users').doc(userId).collection('skills').get();
      _skillsInDemand = skillsQuery.docs.length; // Assuming skills in demand is count of user's skills

      // For notifications, assuming a notifications collection
      final notificationsQuery = await _firestore.collection('notifications').where('UserId', isEqualTo: userId).where('IsRead', isEqualTo: false).get();
      _newNotifications = notificationsQuery.docs.length;

      // Fetch upcoming deadlines from qualifications and trainings
      _upcomingDeadlines = [];
      final now = DateTime.now();
      final currentDate = DateTime(now.year, now.month, now.day);

      // Qualifications with future dates (assuming date is renewal or expiry)
      for (var doc in qualificationsQuery.docs) {
        final data = doc.data();
        final dateStr = data['date'] as String?;
        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            final date = DateTime.parse(dateStr);
            if (date.isAfter(currentDate)) {
              _upcomingDeadlines.add({
                'title': 'Qualification renewal: ${data['name'] ?? 'Unknown'}',
                'date': dateStr,
              });
            }
          } catch (e) {
            // Invalid date, skip
          }
        }
      }

      // Trainings with future end dates
      for (var doc in trainingsQuery.docs) {
        final data = doc.data();
        final endDateStr = data['endDate'] as String?;
        if (endDateStr != null && endDateStr.isNotEmpty) {
          try {
            final endDate = DateTime.parse(endDateStr);
            if (endDate.isAfter(currentDate)) {
              _upcomingDeadlines.add({
                'title': 'Training completion: ${data['trainingName'] ?? 'Unknown'}',
                'date': endDateStr,
              });
            }
          } catch (e) {
            // Invalid date, skip
          }
        }
      }

      // Sort upcoming deadlines by date
      _upcomingDeadlines.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      // Limit to top 5
      if (_upcomingDeadlines.length > 5) {
        _upcomingDeadlines = _upcomingDeadlines.sublist(0, 5);
      }

      // Fetch recent activities from skills, qualifications, trainings
      _recentActivities = [];
      final recentSkills = await _firestore.collection('users').doc(userId).collection('skills').orderBy('createdAt', descending: true).limit(3).get();
      for (var doc in recentSkills.docs) {
        final data = doc.data();
        _recentActivities.add('Added skill: ${data['name'] ?? 'Unknown'}');
      }

      final recentQualifications = await _firestore.collection('users').doc(userId).collection('qualifications').orderBy('createdAt', descending: true).limit(3).get();
      for (var doc in recentQualifications.docs) {
        final data = doc.data();
        _recentActivities.add('Added qualification: ${data['name'] ?? 'Unknown'}');
      }

      final recentTrainings = await _firestore.collection('users').doc(userId).collection('trainings').orderBy('createdAt', descending: true).limit(3).get();
      for (var doc in recentTrainings.docs) {
        final data = doc.data();
        _recentActivities.add('Enrolled in training: ${data['trainingName'] ?? 'Unknown'}');
      }

      // Sort recent activities by creation time if possible, but since orderBy is used, it's already sorted
      // Limit to top 5
      if (_recentActivities.length > 5) {
        _recentActivities = _recentActivities.sublist(0, 5);
      }

      // Calculate progress based on actual data
      _skillsProgress = _skillsInDemand > 0 ? 1.0 : 0.0;
      _documentsProgress = _documentsUploaded > 0 ? 1.0 : 0.0;
      _ratingProgress = (user.firstName?.isNotEmpty == true && user.lastName?.isNotEmpty == true && (user.photoUrl?.isNotEmpty == true || user.photoBase64?.isNotEmpty == true)) ? 1.0 : 0.0;

      // Fetch overview data from Firestore for other fields
      final overviewDoc = await _firestore.collection('dashboard_overview').doc(userId).get();
      if (overviewDoc.exists) {
        final data = overviewDoc.data()!;
        _missingDocuments = data['missingDocuments'] ?? 0;

        _todaysTasks = List<String>.from(data['todaysTasks'] ?? []);
      } else {
        // Handle empty data case by resetting fields
        _missingDocuments = 0;
        _todaysTasks = [
          'Upload documents',
          'Add acquired skills',
          'Add planned training',
          'Add qualification',
        ];
      }
      notifyListeners();
    } catch (e) {
      // Handle errors gracefully
      debugPrint('Error loading dashboard data: $e');
    }
  }

  Future<void> signOut() async {
    await _authViewModel.logout();
  }
}
