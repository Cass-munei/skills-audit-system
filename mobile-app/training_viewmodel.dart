import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class Training {
  final String id;
  final String trainingName;
  final String provider;
  final String startDate;
  final String endDate;
  final String status;

  Training({
    required this.id,
    required this.trainingName,
    required this.provider,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Training.fromMap(Map<String, dynamic> data, String id) {
    return Training(
      id: id,
      trainingName: data['trainingName'] ?? data['TrainingName'] ?? '',
      provider: data['provider'] ?? data['Provider'] ?? '',
      startDate: data['startDate'] ?? data['StartDate'] ?? '',
      endDate: data['endDate'] ?? data['EndDate'] ?? '',
      status: data['status'] ?? data['Status'] ?? 'Planned',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'TrainingName': trainingName,
      'Provider': provider,
      'StartDate': startDate,
      'EndDate': endDate,
      'Status': status,
    };
  }
}

class TrainingViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Training> _trainings = [];
  List<Training> get trainings => _trainings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<QuerySnapshot>? _trainingsSubscription;

  void startListeningToTrainings() {
    fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      _trainingsSubscription?.cancel(); // Cancel any existing subscription
      _trainingsSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('trainings')
          .snapshots()
          .listen(
            (snapshot) {
              _trainings =
                  snapshot.docs
                      .map(
                        (doc) => Training.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ),
                      )
                      .toList();
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = error.toString();
              notifyListeners();
            },
          );
    }
  }

  void stopListeningToTrainings() {
    _trainingsSubscription?.cancel();
    _trainingsSubscription = null;
  }

  Future<void> loadTrainings() async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot snapshot =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('trainings')
                .get();
        _trainings =
            snapshot.docs
                .map(
                  (doc) => Training.fromMap(
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

  Future<void> addTraining(
    String trainingName,
    String provider,
    String startDate,
    String endDate,
    String status,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('trainings')
            .add({
              'TrainingName': trainingName,
              'Provider': provider,
              'StartDate': startDate,
              'EndDate': endDate,
              'Status': status,
              'createdAt': FieldValue.serverTimestamp(),
            });
        // No need to manually add to _trainings as the listener will handle it
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTraining(
    String id,
    String trainingName,
    String provider,
    String startDate,
    String endDate,
    String status,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('trainings')
            .doc(id)
            .update({
              'TrainingName': trainingName,
              'Provider': provider,
              'StartDate': startDate,
              'EndDate': endDate,
              'Status': status,
            });
        // No need to manually update _trainings as the listener will handle it
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTraining(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('trainings')
            .doc(id)
            .delete();
        // No need to manually remove from _trainings as the listener will handle it
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
