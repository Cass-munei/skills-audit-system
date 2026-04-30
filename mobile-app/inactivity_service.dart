import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class InactivityService {
  static const Duration inactivityDuration = Duration(seconds: 120); // 2 minutes
  static const Duration dialogTimeout = Duration(seconds: 30);

  Timer? _inactivityTimer;
  Timer? _dialogTimer;
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _isDialogShowing = false;

  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    // Only start timer on mobile platforms, not web, and only if user is logged in
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final context = _navigatorKey?.currentContext;
      if (context != null) {
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
        if (authViewModel.user != null) {
          _startInactivityTimer();
        }
      }
    }
  }

  void resetTimer() {
    if (_isDialogShowing) return; // Don't reset if dialog is showing
    // Only reset timer on mobile platforms and only if user is logged in
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && _navigatorKey != null) {
      final context = _navigatorKey!.currentContext;
      if (context != null) {
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
        if (authViewModel.user != null) {
          _cancelTimers();
          _startInactivityTimer();
        }
      }
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer = Timer(inactivityDuration, _showInactivityDialog);
  }

  void _showInactivityDialog() {
    if (_navigatorKey == null || _isDialogShowing) return;

    _isDialogShowing = true;

    showDialog(
      context: _navigatorKey!.currentContext!,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Are you still using the platform?'),
          content: const Text('You have been inactive for a while. Please confirm if you are still using the app.'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _logout();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _dismissDialog();
              },
            ),
          ],
        );
      },
    );

    // Start dialog timeout timer
    _dialogTimer = Timer(dialogTimeout, () {
      if (_isDialogShowing) {
        Navigator.of(_navigatorKey!.currentContext!).pop(); // Close dialog
        _logout();
      }
    });
  }

  void _dismissDialog() {
    _isDialogShowing = false;
    _cancelDialogTimer();
    _startInactivityTimer(); // Restart the inactivity timer
  }

  void _logout() {
    _isDialogShowing = false;
    _cancelTimers();
    if (_navigatorKey != null) {
      final context = _navigatorKey!.currentContext;
      if (context != null) {
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
        authViewModel.logout();
        // Navigate to login screen after logout
        _navigatorKey!.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  void _cancelTimers() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _cancelDialogTimer() {
    _dialogTimer?.cancel();
    _dialogTimer = null;
  }

  void dispose() {
    _cancelTimers();
    _cancelDialogTimer();
    _navigatorKey = null;
  }
}
