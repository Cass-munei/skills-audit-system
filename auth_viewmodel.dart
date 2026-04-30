import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthViewModel extends ChangeNotifier {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  String? _profileImageBase64;
  String? get profileImageBase64 => _profileImageBase64;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _verificationId;
  String? get verificationId => _verificationId;

  bool _otpSent = false;
  bool get otpSent => _otpSent;

  void setVerificationId(String? id) {
    _verificationId = id;
    notifyListeners();
  }

  void setOtpSent(bool sent) {
    _otpSent = sent;
    notifyListeners();
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String employeeId,
    required String password,
    required String department,
    required String hod,
    required String contact,
    String? jobTitle,
  }) async {
    _setLoading(true);
    _setError(null);
    // Check if employeeId already exists
    QuerySnapshot query = await _firestore.collection('employee_ids').where('employeeId', isEqualTo: employeeId).get();
    if (query.docs.isNotEmpty) {
      _setError('Employee ID already exists');
      _setLoading(false);
      return;
    }
    try {
      fb_auth.UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      fb_auth.User? fbUser = credential.user;
      if (fbUser != null) {
        _user = User(
          uid: fbUser.uid,
          firstName: firstName,
          lastName: lastName,
          email: email,
          employeeId: employeeId,
          department: department,
          hod: hod,
          jobTitle: jobTitle,
        );
        await _firestore
            .collection('users')
            .doc(fbUser.uid)
            .set(_user!.toMap());
        await _firestore
            .collection('employee_ids')
            .doc(employeeId)
            .set({
              'employeeId': employeeId,
              'email': email,
              'contact': contact,
            });
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);
    try {
      fb_auth.UserCredential credential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      fb_auth.User? fbUser = credential.user;
      if (fbUser != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(fbUser.uid).get();
        _user = User.fromMap(doc.data() as Map<String, dynamic>, fbUser.uid);
        if (_user!.isDisabled) {
          _setError('The user account has been disabled by an administrator');
          await _auth.signOut();
          _user = null;
          _setLoading(false);
          return;
        }
        await _loadProfileImageBase64(_user!.email);
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<void> loginByEmployeeId({
    required String employeeId,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      // Query Firestore for user with matching employeeId
      QuerySnapshot query =
          await _firestore
              .collection('employee_ids')
              .where('employeeId', isEqualTo: employeeId)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        _setError('Employee ID not found');
        _setLoading(false);
        return;
      }

      String email = query.docs.first['email'];

      // Now login with the retrieved email
      fb_auth.UserCredential credential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      fb_auth.User? fbUser = credential.user;
      if (fbUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(fbUser.uid).get();
        _user = User.fromMap(userDoc.data() as Map<String, dynamic>, fbUser.uid);
        if (_user!.isDisabled) {
          _setError('The user account has been disabled by an administrator');
          await _auth.signOut();
          _user = null;
          _setLoading(false);
          return;
        }
        await _loadProfileImageBase64(_user!.email);
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      debugPrint("Starting signOut for user: ${_auth.currentUser?.uid}");
      await _auth.signOut().timeout(const Duration(seconds: 10));
      debugPrint("signOut completed successfully");
      _user = null;
      _profileImageBase64 = null;
      // Clear remember me data for security
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> updateUser(User updatedUser) async {
    _setLoading(true);
    _setError(null);
    debugPrint('AuthViewModel updateUser called with: ${updatedUser.toMap()}');
    try {
      await _firestore
          .collection('users')
          .doc(updatedUser.uid)
          .update(updatedUser.toMap());
      _user = updatedUser;
      debugPrint('AuthViewModel _user set to: ${_user?.toMap()}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error in updateUser: $e');
      _setError(e.toString());
    }
    _setLoading(false);
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> _loadProfileImageBase64(String? email) async {
    if (email != null) {
      final prefs = await SharedPreferences.getInstance();
      _profileImageBase64 = prefs.getString('profile_image_base64_$email');
      notifyListeners();
    }
  }

  void setProfileImageBase64(String? base64) {
    _profileImageBase64 = base64;
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final fb_auth.User? fbUser = _auth.currentUser;
      if (fbUser == null) {
        _setError('No user logged in');
        _setLoading(false);
        return;
      }

      // Reauthenticate with current password
      final fb_auth.AuthCredential credential = fb_auth.EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );
      await fbUser.reauthenticateWithCredential(credential);

      // Update password
      await fbUser.updatePassword(newPassword);
    } on fb_auth.FirebaseAuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<String?> getUserPhotoBase64(String email) async {
    try {
      QuerySnapshot query = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isNotEmpty) {
        Map<String, dynamic> data = query.docs.first.data() as Map<String, dynamic>;
        return data['photoBase64'];
      }
    } catch (e) {
      debugPrint('Error fetching user photo: $e');
    }
    return null;
  }

  Future<String?> getUserPhotoBase64ByEmployeeId(String employeeId) async {
    try {
      QuerySnapshot query = await _firestore.collection('employee_ids').where('employeeId', isEqualTo: employeeId).limit(1).get();
      if (query.docs.isNotEmpty) {
        String email = query.docs.first['email'];
        QuerySnapshot userQuery = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
        if (userQuery.docs.isNotEmpty) {
          Map<String, dynamic> data = userQuery.docs.first.data() as Map<String, dynamic>;
          return data['photoBase64'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching user photo: $e');
    }
    return null;
  }

  Future<bool> isUserDisabled(String email) async {
    try {
      QuerySnapshot query = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isNotEmpty) {
        Map<String, dynamic> data = query.docs.first.data() as Map<String, dynamic>;
        return data['isDisabled'] ?? false;
      }
    } catch (e) {
      debugPrint('Error checking if user is disabled: $e');
    }
    return false;
  }

  Future<bool> isUserDisabledByEmployeeId(String employeeId) async {
    try {
      QuerySnapshot query = await _firestore.collection('employee_ids').where('employeeId', isEqualTo: employeeId).limit(1).get();
      if (query.docs.isNotEmpty) {
        String email = query.docs.first['email'];
        return await isUserDisabled(email);
      }
    } catch (e) {
      debugPrint('Error checking if user is disabled by employee ID: $e');
    }
    return false;
  }

  Future<void> sendOtp(String phoneNumber) async {
    _setLoading(true);
    _setError(null);
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
        // Auto-verification completed
        await _auth.signInWithCredential(credential);
        setOtpSent(true);
        _setLoading(false);
      },
      verificationFailed: (fb_auth.FirebaseAuthException e) {
        _setError(e.message);
        _setLoading(false);
      },
      codeSent: (String verificationId, int? resendToken) {
        setVerificationId(verificationId);
        setOtpSent(true);
        _setLoading(false);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setVerificationId(verificationId);
        _setLoading(false);
      },
    );
  }

  Future<bool> verifyOtp(String smsCode) async {
    _setLoading(true);
    _setError(null);
    try {
      fb_auth.PhoneAuthCredential credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      _setLoading(false);
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}
