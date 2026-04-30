import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/qualification.dart';

class QualificationsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Qualification> _qualifications = [];
  List<Qualification> get qualifications => _qualifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<QuerySnapshot>? _qualificationsSubscription;

  void startListeningToQualifications() {
    fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      _qualificationsSubscription?.cancel(); // Cancel any existing subscription
      _qualificationsSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('qualifications')
          .snapshots()
          .listen(
            (snapshot) {
              _qualifications =
                  snapshot.docs
                      .map(
                        (doc) => Qualification.fromMap(
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

  void stopListeningToQualifications() {
    _qualificationsSubscription?.cancel();
    _qualificationsSubscription = null;
  }

  Future<void> loadQualifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot snapshot =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('qualifications')
                .get();
        _qualifications =
            snapshot.docs
                .map(
                  (doc) => Qualification.fromMap(
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

  Future<void> addQualification(
    String name,
    String institution,
    String date,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('qualifications')
            .add({
              'name': name,
              'institution': institution,
              'date': date,
              'createdAt': FieldValue.serverTimestamp(),
            });
        // No need to manually add to _qualifications as the listener will handle it
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateQualification(
    String id,
    String name,
    String institution,
    String date,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('qualifications')
            .doc(id)
            .update({'name': name, 'institution': institution, 'date': date});
        // No need to manually update _qualifications as the listener will handle it
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteQualification(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('qualifications')
            .doc(id)
            .delete();
        // No need to manually remove from _qualifications as the listener will handle it
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
