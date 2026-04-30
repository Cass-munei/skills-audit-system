import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailError, _successMessage;
  Uint8List? _logoBytes;
  bool _isLogoLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Extended Header with Features on Dark Background
            Container(
              width: double.infinity,
              height: 350,
              decoration: const BoxDecoration(color: Color(0xFF0F172A)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _isLogoLoading
                          ? const CircularProgressIndicator()
                          : Image.memory(
                            _logoBytes!,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 12),
                      const Text(
                        'FORGOT PASSWORD?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '-National Treasury-',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(height: 1, width: 200, color: Colors.white54),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFeatureItem(
                              icon: Icons.manage_accounts,
                              title: 'Manage skills and training effectively',
                              isDark: true,
                            ),
                            _buildFeatureItem(
                              icon: Icons.search,
                              title:
                                  'Identify Strengths and areas for improvement',
                              isDark: true,
                            ),
                            _buildFeatureItem(
                              icon: Icons.trending_up,
                              title: 'Align skills with career goals',
                              isDark: true,
                            ),
                            _buildFeatureItem(
                              icon: Icons.upload_file,
                              title: 'Upload supporting documents',
                              isDark: true,
                            ),
                            _buildFeatureItem(
                              icon: Icons.notifications,
                              title: 'Get notifications to stay updated',
                              isDark: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Form
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'SKILLS AUDIT SYSTEM',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    onChanged: (value) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Enter your email address',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email),
                      errorText: _emailError,
                    ),
                  ),
                  if (_successMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendPasswordResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'SEND RESET EMAIL',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      '© 2025 Skills Audit System, All rights reserved',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    bool isDark = false,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final iconColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _sendPasswordResetEmail() async {
    setState(() {
      _emailError = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email');
      return;
    }

    if (!email.contains('@') || !email.endsWith('treasury.gov.za')) {
      setState(
        () =>
            _emailError =
                'Please enter a valid work email ending with treasury.gov.za',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await fb_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _successMessage =
            'Password reset email sent! Check your inbox and follow the instructions.';
        _isLoading = false;
      });
    } on fb_auth.FirebaseAuthException catch (e) {
      setState(() {
        _emailError = e.message ?? 'Failed to send reset email';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _emailError = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
