import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class EmployeeLoginScreen extends StatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  String? _employeeIdError, _passwordError;
  String? _profileImagePath;

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
                _employeeIdError = null;
                _passwordError = null;
              });

              final employeeId = _employeeIdController.text.trim();
              final password = _passwordController.text.trim();

              bool hasError = false;
              if (employeeId.isEmpty) {
                _employeeIdError = 'Please enter Employee ID';
                hasError = true;
              } else if (employeeId.length != 10) {
                _employeeIdError = 'Employee ID must be 10 characters';
                hasError = true;
              } else if (!employeeId.startsWith('EMP-00')) {
                _employeeIdError = 'Employee ID must start with EMP-00';
                hasError = true;
              } else {
                final lastFour = employeeId.substring(6);
                if (!RegExp(r'^\d{4}$').hasMatch(lastFour)) {
                  _employeeIdError = 'Last four characters must be digits';
                  hasError = true;
                }
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
              await authViewModel.loginByEmployeeId(
                employeeId: employeeId,
                password: password,
              );

              if (authViewModel.errorMessage != null) {
                setState(() {
                  _employeeIdError = authViewModel.errorMessage;
                });
              } else {
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Employee Login',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
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
                      onChanged: (value) async {
                        if (_employeeIdError != null) {
                          setState(() => _employeeIdError = null);
                        }
                        await _loadProfileImage(value);
                      },
                      decoration: InputDecoration(
                        labelText: 'Enter Employee ID',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.badge),
                        errorText: _employeeIdError,
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
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: const Center(
              child: Text(
                '© 2025 Skills Audit System, All rights reserved',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProfileImage(String employeeId) async {
    if (employeeId.isEmpty || employeeId.length != 10 || !employeeId.startsWith('EMP-00')) {
      setState(() {
        _profileImagePath = null;
      });
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final isDisabled = await authViewModel.isUserDisabledByEmployeeId(employeeId);
    if (isDisabled) {
      setState(() {
        _profileImagePath = null;
      });
      return;
    }
    final base64Image = await authViewModel.getUserPhotoBase64ByEmployeeId(employeeId);
    setState(() {
      _profileImagePath = base64Image;
    });
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
