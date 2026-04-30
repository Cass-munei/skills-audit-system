import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'terms_of_use_screen.dart';
import 'terms_privacy_screen.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _employeeEmailController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  String? _selectedDepartment;
  String? _selectedHod;
  String? _selectedJobTitle;
  String? _firstNameError,
      _lastNameError,
      _emailError,
      _employeeIdError,
      _contactError,
      _departmentError,
      _hodError,
      _jobTitleError,
      _passwordError,
      _confirmPasswordError,
      _termsError,
      _authError;

  final List<String> _departments = [
    'Office of the Director-General',
    'Intergovernmental Relations',
    'Office of the General Counsel',
    'Budget Preparation / Budget Office',
    'Economic Policy and International Cooperation',
    'Office of the Accountant-General',
    'Tax & Financial Sector Policy',
    'Assets & Liability Management',
    'Public Finance / Expenditure Control',
    'Corporate / Support Services (HR, ICT, Facilities, Legal, Security, etc.)',
    'Chief Procurement Office',
  ];

  final Map<String, List<String>> _hodMap = {
    'Office of the Director-General': ['Tlotlo Mokaleng'],
    'Intergovernmental Relations': ['Kamohelo Mkhatshwa'],
    'Office of the General Counsel': ['Lethabo Rabothata'],
    'Budget Preparation / Budget Office': ['Noncedo Ngcobo'],
    'Economic Policy and International Cooperation': ['Noxolo Mabunda'],
    'Office of the Accountant-General': ['Cassandra Munyai'],
    'Tax & Financial Sector Policy': ['Fana Mokhotu'],
    'Assets & Liability Management': ['Muzi Mkhize'],
    'Public Finance / Expenditure Control': ['Tumelo Legodi'],
    'Corporate / Support Services (HR, ICT, Facilities, Legal, Security, etc.)':
        ['Dikatlego Kgopane'],
    'Chief Procurement Office': ['Wesley Magata'],
  };

  final Map<String, List<String>> _jobTitleMap = {
    'Budget Preparation / Budget Office': [
      'Expenditure Planning',
      'Public Finance Statistics',
      'International Development Co-operation',
      'Fiscal Policy',
      'Public Sector Remuneration Unit',
      'Infrastructure Regulation and Assessment Unit',
    ],
    'Chief Procurement Office': [
      'Transversal Contracting',
      'SCM Policy, Norms & Standards',
      'Strategic Procurement',
      'SCM Client Support',
      'SCM Information, Communication & Technology',
      'SCM Governance, Monitoring & Compliance',
    ],
    'Corporate / Support Services (HR, ICT, Facilities, Legal, Security, etc.)': [
      'Strategic Projects & Support',
      'Human Resources Management',
      'Information & Communications Technology',
      'Facilities Management',
      'Security Management',
      'Media Liaison & Communications',
    ],
    'Intergovernmental Relations': [
      'Local Government Budget Analysis',
      'Intergovernmental Policy & Planning',
      'Provincial & Local Government Infrastructure',
      'Provincial Budget Analysis',
      'Neighbourhood Development Unit',
    ],
    'Assets & Liability Management': [
      'Sectoral Oversight',
      'Liability Management',
      'Financial Operations',
      'Strategy & Risk Management',
      'Governance & Financial Analysis',
    ],
    'Public Finance / Expenditure Control': [
      'Justice & Protection Services',
      'Economic Services',
      'Administrative Services',
      'Education & Related Departments & Labour',
      'Health & Social Development',
      'Urban Development & Infrastructure',
    ],
    'Tax & Financial Sector Policy': [
      'Financial Sector Development',
      'Financial Services',
      'Financial Stability',
      'Economic Tax Analysis',
      'Legal Tax Design',
    ],
    'Office of the General Counsel': [
      'Legal Services',
      'Legislation',
      'Public Entities Governance Unit (PEGU)',
    ],
    'Economic Policy and International Cooperation': [
      'Modelling & Forecasting',
      'Microeconomic Policy',
      'Macroeconomic Policy',
      'African Economic Integration',
      'Multilateral Development Banks & Concessional Finance',
      'Global and Emerging Markets',
    ],
    'Office of the Accountant-General': [
      'Capacity Building',
      'MFMA Implementation',
      'Accounting Support & Integration',
      'Internal Audit Support',
      'Risk Management',
      'Technical Support Services',
      'Governance Monitoring & Compliance',
      'Specialised Audit Services',
      'Financial Systems',
      'Integrated Financial Management Systems (IFMS)',
    ],
    'Office of the Director-General': [
      'Financial Management (including Supply Chain Management)',
      'Data Analytics',
      'Strategic Management & Oversight',
      'Enterprise Risk Management',
      'Internal Audit',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
         backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Employee Registration',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Extended Header with Features on Dark Background
            // Removed for cleaner UI as per user feedback
            const SizedBox(height: 20),
            // Registration Form
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
                    controller: _firstNameController,
                    onChanged: (value) {
                      if (_firstNameError != null) {
                        setState(() => _firstNameError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                      errorText: _firstNameError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lastNameController,
                    onChanged: (value) {
                      if (_lastNameError != null) {
                        setState(() => _lastNameError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                      errorText: _lastNameError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _employeeEmailController,
                    onChanged: (value) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Employee Email',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email),
                      errorText: _emailError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _employeeIdController,
                    onChanged: (value) {
                      if (_employeeIdError != null) {
                        setState(() => _employeeIdError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Employee Id',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.badge),
                      errorText: _employeeIdError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contactController,
                    onChanged: (value) {
                      if (_contactError != null) {
                        setState(() => _contactError = null);
                      }
                    },
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contact Number',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone),
                      errorText: _contactError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value;
                        _selectedHod =
                            null; // Reset HOD when department changes
                        _selectedJobTitle =
                            null; // Reset Job Title when department changes
                        if (_departmentError != null) {
                          _departmentError = null;
                        }
                        if (_jobTitleError != null) {
                          _jobTitleError = null;
                        }
                      });
                    },
                    items:
                        _departments.map((department) {
                          return DropdownMenuItem<String>(
                            value: department,
                            child: Text(department),
                          );
                        }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Department',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.account_tree),
                      errorText: _departmentError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedHod,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _selectedHod = value;
                        if (_hodError != null) {
                          _hodError = null;
                        }
                      });
                    },
                    items:
                        _selectedDepartment != null &&
                                _hodMap.containsKey(_selectedDepartment)
                            ? _hodMap[_selectedDepartment]!.map((hod) {
                              return DropdownMenuItem<String>(
                                value: hod,
                                child: Text(hod),
                              );
                            }).toList()
                            : [],
                    decoration: InputDecoration(
                      labelText: 'Head of Department (HOD)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_outline),
                      errorText: _hodError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedJobTitle,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _selectedJobTitle = value;
                        if (_jobTitleError != null) {
                          _jobTitleError = null;
                        }
                      });
                    },
                    items: _selectedDepartment != null &&
                            _jobTitleMap.containsKey(_selectedDepartment)
                        ? _jobTitleMap[_selectedDepartment]!.map((jobTitle) {
                            return DropdownMenuItem<String>(
                              value: jobTitle,
                              child: Text(jobTitle),
                            );
                          }).toList()
                        : [],
                    decoration: InputDecoration(
                      labelText: 'Role / Job Title',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.work),
                      errorText: _jobTitleError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    onChanged: (value) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    onChanged: (value) {
                      if (_confirmPasswordError != null) {
                        setState(() => _confirmPasswordError = null);
                      }
                    },
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      errorText: _confirmPasswordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: RichText(
                      text: TextSpan(
                        text: 'I agree to the ',
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Terms of Use',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const TermsOfUseScreen(),
                                      ),
                                    );
                                  },
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const TermsPrivacyScreen(),
                                      ),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ),
                    value: _termsAccepted,
                    onChanged: (bool? value) {
                      setState(() {
                        _termsAccepted = value ?? false;
                        if (_termsError != null) {
                          _termsError = null;
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_termsError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                      child: Text(
                        _termsError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (_authError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _authError!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<AuthViewModel>(
                      builder: (context, authViewModel, child) {
                        return ElevatedButton(
                          onPressed:
                              authViewModel.isLoading
                                  ? null
                                  : () async {
                                    setState(() {
                                      _authError = null;
                                    });

                                    final firstName =
                                        _firstNameController.text.trim();
                                    final lastName =
                                        _lastNameController.text.trim();
                                    final email =
                                        _employeeEmailController.text.trim();
                                    final employeeId =
                                        _employeeIdController.text.trim();
                                    final contact =
                                        _contactController.text.trim();
                                    final department =
                                        _selectedDepartment ?? '';
                                    final hod = _selectedHod ?? '';
                                    final jobTitle = _selectedJobTitle ?? '';
                                    final password =
                                        _passwordController.text.trim();
                                    final confirmPassword =
                                        _confirmPasswordController.text.trim();

                                    setState(() {
                                      _firstNameError =
                                          firstName.isEmpty
                                              ? 'First name is required'
                                              : null;
                                      _lastNameError =
                                          lastName.isEmpty
                                              ? 'Last name is required'
                                              : null;
                                      _emailError =
                                          email.isEmpty
                                              ? 'Email is required'
                                              : null;
                                      _employeeIdError =
                                          employeeId.isEmpty
                                              ? 'Employee ID is required'
                                              : (!RegExp(r'^EMP-00\d{4}$').hasMatch(employeeId)
                                                  ? 'Employee ID must be in the format EMP-00####'
                                                  : null);
                                      _contactError =
                                          contact.isEmpty
                                              ? 'Contact number is required'
                                              : (contact.length != 10 ||
                                                      !RegExp(r'^[0-9]+$').hasMatch(contact) ||
                                                      !contact.startsWith('0'))
                                                  ? 'Contact number must be 10 digits starting with 0'
                                                  : null;
                                      _departmentError =
                                          _selectedDepartment == null ||
                                                  _selectedDepartment!.isEmpty
                                              ? 'Department is required'
                                              : null;
                                      _hodError =
                                          _selectedHod == null ||
                                                  _selectedHod!.isEmpty
                                              ? 'Head of Department is required'
                                              : null;
                                      _jobTitleError =
                                          _selectedJobTitle == null ||
                                                  _selectedJobTitle!.isEmpty
                                              ? 'Role / Job Title is required'
                                              : null;
                                      _passwordError =
                                          password.isEmpty
                                              ? 'Password is required'
                                              : (!_isValidPassword(password)
                                                  ? r'Password must contain special characters such as "0-9/\ @#$" with both lower and upper cases and the password must be at least 8 characters long'
                                                  : null);
                                      _confirmPasswordError =
                                          confirmPassword.isEmpty
                                              ? 'Confirm password is required'
                                              : null;
                                    });

                                    if (firstName.isEmpty ||
                                        lastName.isEmpty ||
                                        email.isEmpty ||
                                        employeeId.isEmpty ||
                                        contact.isEmpty ||
                                        department.isEmpty ||
                                        hod.isEmpty ||
                                        jobTitle.isEmpty ||
                                        password.isEmpty ||
                                        confirmPassword.isEmpty) {
                                      return;
                                    }

                                    if (!email.contains('@')) {
                                      setState(() {
                                        _emailError = 'Email must contain "@"';
                                      });
                                      return;
                                    }

                                    if (!email.endsWith('treasury.gov.za')) {
                                      setState(() {
                                        _emailError =
                                            'Email must end with "treasury.gov.za"';
                                      });
                                      return;
                                    }

                                    if (password != confirmPassword) {
                                      setState(() {
                                        _confirmPasswordError =
                                            'Passwords do not match';
                                      });
                                      return;
                                    }

                                    if (!_termsAccepted) {
                                      setState(() {
                                        _termsError =
                                            'You must accept the Terms of Service and Privacy Policy';
                                      });
                                      // Do not throw exception to avoid freezing UI
                                      return;
                                    }

                                    try {
                                      // Send OTP first
                                      await authViewModel.sendOtp('+27$contact');
                                      if (authViewModel.errorMessage != null) {
                                        setState(() {
                                          _authError = authViewModel.errorMessage;
                                        });
                                        return;
                                      }
                                      // Show OTP dialog and wait for verification
                                      final bool verified = await _showOtpDialog(context, authViewModel);
                                      if (verified) {
                                        // Proceed with registration
                                        await authViewModel.register(
                                          firstName: firstName,
                                          lastName: lastName,
                                          email: email,
                                          employeeId: employeeId,
                                          password: password,
                                          department: department,
                                          hod: hod,
                                          contact: contact,
                                          jobTitle: jobTitle,
                                        );
                                        if (authViewModel.errorMessage != null) {
                                          setState(() {
                                            _authError = authViewModel.errorMessage;
                                          });
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Registration Successful. Navigating to Login...')),
                                            );
                                            // Delay navigation to allow SnackBar to show
                                            Future.delayed(const Duration(seconds: 2), () {
                                              if (mounted) {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => const LoginScreen(),
                                                  ),
                                                );
                                              }
                                            });
                                          }
                                        }
                                      }
                                    } catch (e) {
                                      setState(() {
                                        _authError = 'Registration failed: $e';
                                      });
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              authViewModel.isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'REGISTER',
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

  Future<bool> _showOtpDialog(BuildContext context, AuthViewModel authViewModel) async {
    final TextEditingController otpController = TextEditingController();
    bool verified = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter OTP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('An OTP has been sent to your phone number. Please enter it below.'),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final otp = otpController.text.trim();
                if (otp.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter the OTP')),
                  );
                  return;
                }
                verified = await authViewModel.verifyOtp(otp);
                if (verified) {
                  Navigator.of(context).pop(); // Close dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authViewModel.errorMessage ?? 'Invalid OTP')),
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
    return verified;
  }

  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9/\\ @#$]'))) return false;
    return true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _employeeEmailController.dispose();
    _employeeIdController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
