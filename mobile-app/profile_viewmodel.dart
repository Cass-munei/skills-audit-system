import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? fbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(fbUser.uid).get();
        if (doc.exists) {
          _user = User.fromMap(doc.data() as Map<String, dynamic>, fbUser.uid);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserProfile(
    String firstName,
    String lastName,
    String email,
    String department,
    String hod,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? fbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        _user = User(
          uid: fbUser.uid,
          firstName: firstName,
          lastName: lastName,
          email: email,
          employeeId: _user?.employeeId ?? '',
          department: department,
          hod: hod,
        );
        await _firestore
            .collection('users')
            .doc(fbUser.uid)
            .set(_user!.toMap());
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
