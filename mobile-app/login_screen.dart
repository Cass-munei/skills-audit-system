import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'forgot_password_screen.dart';
import 'registration_screen.dart';
import 'dashboard_screen.dart';
import 'employee_login_screen.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  late SharedPreferences _prefs;
  bool _obscureText = true;
  bool _rememberMe = false;
  String? _emailError, _passwordError, _authError;
  String? _profileImagePath;
  Uint8List? _logoBytes;
  bool _isLogoLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = _prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _employeeIdController.text = _prefs.getString('email') ?? '';
        _passwordController.text = _prefs.getString('password') ?? '';
      }
    });
  }

  Future<void> _loadProfileImage(String email) async {
    if (email.isEmpty || !email.contains('@') || !email.endsWith('treasury.gov.za')) {
      if (mounted) {
        setState(() {
          _profileImagePath = null;
        });
      }
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final isDisabled = await authViewModel.isUserDisabled(email);
    if (isDisabled) {
      if (mounted) {
        setState(() {
          _profileImagePath = null;
        });
      }
      return;
    }
    final base64Image = await authViewModel.getUserPhotoBase64(email);
    if (mounted) {
      setState(() {
        _profileImagePath = base64Image;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;
    final onPressed =
        isLoading
            ? null
            : () async {
              // Unfocus keyboard
              FocusScope.of(context).unfocus();

              setState(() {
                _emailError = null;
                _passwordError = null;
                _authError = null;
              });

              final email = _employeeIdController.text.trim();
              final password = _passwordController.text.trim();

              bool hasError = false;
              if (email.isEmpty) {
                _emailError = 'Please enter email';
                hasError = true;
              } else if (!email.contains('@')) {
                _emailError = 'Email must contain "@"';
                hasError = true;
              } else if (!email.endsWith('nt.org.za')) {
                _emailError =
                    'Email is not validated, please enter work email with extension nt.org.za';
                hasError = true;
              }
              if (password.isEmpty) {
                _passwordError = 'Please enter password';
                hasError = true;
              }
              if (hasError) {
                setState(() {});
                return;
              }

              final authViewModel = context.read<AuthViewModel>();
              await authViewModel.login(email: email, password: password);

              if (authViewModel.errorMessage != null) {
                setState(() {
                  _emailError = 'Invalid Employee Email or Password';
                });
              } else {
                if (_rememberMe) {
                  await _prefs.setString('email', email);
                  await _prefs.setString('password', password);
                  await _prefs.setBool('rememberMe', true);
                } else {
                  await _prefs.remove('email');
                  await _prefs.remove('password');
                  await _prefs.setBool('rememberMe', false);
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              }
            };
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 350,
              decoration: const BoxDecoration(color: Color(0xFF0F172A)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24,
                ),
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
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'WELCOME TO OUR PLATFORM',
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
                            ],
                          ),
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Login Form
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
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        _profileImagePath != null
                            ? MemoryImage(base64Decode(_profileImagePath!))
                            : null,
                    backgroundColor: Colors.grey,
                    child:
                        _profileImagePath == null
                            ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            )
                            : null,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _employeeIdController,
                    onChanged: (value) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                      _loadProfileImage(value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Enter Employee Email ',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.mail),
                      errorText: _emailError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    onChanged: (value) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Enter your password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      errorText: _passwordError,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text(
                            'Remember me',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: _rememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<AuthViewModel>(
                      builder: (context, authVM, child) {
                        final isLoading = authVM.isLoading;
                        final onPressed =
                            isLoading
                                ? null
                                : () async {
                                  // Unfocus keyboard
                                  FocusScope.of(context).unfocus();

                                  setState(() {
                                    _emailError = null;
                                    _passwordError = null;
                                    _authError = null;
                                  });

                                  final email =
                                      _employeeIdController.text.trim();
                                  final password =
                                      _passwordController.text.trim();

                                  bool hasError = false;
                                  if (email.isEmpty) {
                                    _emailError = 'Please enter email';
                                    hasError = true;
                                  } else if (!email.contains('@')) {
                                    _emailError = 'Email must contain "@"';
                                    hasError = true;
                                  } else if (!email.endsWith(
                                    'treasury.gov.za',
                                  )) {
                                    _emailError =
                                        'Email must end with "treasury.gov.za"';
                                    hasError = true;
                                  }
                                  if (password.isEmpty) {
                                    _passwordError = 'Please enter password';
                                    hasError = true;
                                  }
                                  if (hasError) {
                                    setState(() {});
                                    return;
                                  }

                                  final authViewModel =
                                      context.read<AuthViewModel>();
                                  await authViewModel.login(
                                    email: email,
                                    password: password,
                                  );

                                  if (authViewModel.errorMessage != null) {
                                    setState(() {
                                      _emailError = authViewModel.errorMessage;
                                    });
                                  } else {
                                    if (_rememberMe) {
                                      await _prefs.setString('email', email);
                                      await _prefs.setString(
                                        'password',
                                        password,
                                      );
                                      await _prefs.setBool('rememberMe', true);
                                    } else {
                                      await _prefs.remove('email');
                                      await _prefs.remove('password');
                                      await _prefs.setBool('rememberMe', false);
                                    }
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const DashboardScreen(),
                                      ),
                                    );
                                  }
                                };
                        return ElevatedButton(
                          onPressed: onPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'LOGIN',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmployeeLoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Sign in Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistrationScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'New to platform? Sign up',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        decoration: TextDecoration.underline,
                      ),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              title,
              style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void clearCredentials() {
    _employeeIdController.clear();
    _passwordController.clear();
  }
}
