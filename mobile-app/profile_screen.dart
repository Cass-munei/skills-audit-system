import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:skills_audit_system/screens/terms_of_use_screen.dart';
import 'package:skills_audit_system/screens/terms_privacy_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'login_screen.dart'; 
import 'skills_screen.dart';
import 'dashboard_screen.dart';
import 'qualifications_screen.dart';
import 'training_screen.dart';
import 'documents_screen.dart';
import 'notifications_screen.dart';
import '../viewmodels/auth_viewmodel.dart';

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

  // Controllers for Personal Information
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController contactController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController idController;

  // Controllers for Password Reset
  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  // Controllers for Employment Information
  late TextEditingController empIdController;
  late TextEditingController jobTitleController;
  late TextEditingController departmentController;
  late TextEditingController headController;

  // Controller for Additional info
  late TextEditingController additionalInfoController;

  bool _isInitialized = false;
  late AuthViewModel _authViewModel;
  String? _profileImagePath;
  Uint8List? _profileImageBytes;

  // New fields for enhanced inputs
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedCountryCode = '+27';

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    contactController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();
    idController = TextEditingController();
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    empIdController = TextEditingController();
    jobTitleController = TextEditingController();
    departmentController = TextEditingController();
    headController = TextEditingController();
    additionalInfoController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authViewModel = Provider.of<AuthViewModel>(context, listen: true);
    final user = _authViewModel.user;

    if (user != null && !_isEditing) {
      firstNameController.text = user.firstName ?? '';
      lastNameController.text = user.lastName ?? '';
      _selectedDate =
          user.dateOfBirth != null
              ? DateTime.tryParse(user.dateOfBirth!)
              : null;
      _selectedGender = user.gender;
      contactController.text = user.contact ?? '';
      emailController.text = user.email ?? '';
      addressController.text = user.address ?? '';
      idController.text = user.idNumber ?? '';

      empIdController.text = user.employeeId ?? '';
      jobTitleController.text = user.jobTitle ?? '';
      departmentController.text = user.department ?? '';
      headController.text = user.hod ?? '';

      additionalInfoController.text = user.additionalInfo ?? '';
    }

    _loadProfileImage();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    contactController.dispose();
    emailController.dispose();
    addressController.dispose();
    idController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    empIdController.dispose();
    jobTitleController.dispose();
    departmentController.dispose();
    headController.dispose();
    additionalInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            color: Colors.white,
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),

      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.6,
        backgroundColor: const Color(0xFF0F172A),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'SKILLS AUDIT SYSTEM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white, thickness: 2),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    Icons.dashboard,
                    'Dashboard',
                    false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/dashboard');
                    },
                  ),
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      final user = authViewModel.user;
                      final profileTitle =
                          user != null
                              ? '${user.firstName} ${user.lastName}'
                              : 'My Profile';
                      return _buildDrawerItem(
                        context,
                        Icons.person,
                        profileTitle,
                        true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/profile');
                        },
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.star,
                    'Skills',
                    false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/skills');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.school,
                    'Qualifications',
                    false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/qualifications');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.book,
                    'Training',
                    false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/training');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.folder,
                    'Documents',
                    false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/documents');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.notifications,
                    'Notifications',
                    false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.logout,
                    'Sign Out',
                    false,
                    onTap: () async {
                      final screenContext = context;
                      bool? confirmed = await showDialog<bool>(
                        context: screenContext,
                        builder:
                            (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              title: const Text('Sign Out'),
                              content: const Text(
                                'Are you sure you want to sign out?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(screenContext, false),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(screenContext, true),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                      );
                      if (confirmed == true) {
                        showDialog(
                          context: screenContext,
                          barrierDismissible: false,
                          builder:
                              (context) => const AlertDialog(
                                content: Row(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 20),
                                    Text('Signing out...'),
                                  ],
                                ),
                              ),
                        );
                        await context.read<AuthViewModel>().logout();
                        Navigator.pop(screenContext);
                        Navigator.pushAndRemoveUntil(
                          screenContext,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
                ),
                const Divider(color: Colors.white, thickness: 1),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.description, color: Colors.white),
                        title: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TermsOfUseScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Terms of Use',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip, color: Colors.white),
                        title: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const TermsPrivacyScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.gavel, color: Colors.white),
                        title: GestureDetector(
                          onTap: () async {
                            final Uri url = Uri.parse(
                              'https://www.treasury.gov.za/POPIA/',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: const Text(
                            'POPIA',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isEditing ? _buildEditableForm() : _buildReadOnlyProfile(),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    TextEditingController? controller,
    String? initialValue,
    bool readOnly = false,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: readOnly ? null : controller,
          initialValue: readOnly ? initialValue : null,
          readOnly: readOnly,
          obscureText: obscureText,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            filled: readOnly,
            fillColor: readOnly ? Colors.grey.shade200 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyProfile() {
    final user = Provider.of<AuthViewModel>(context, listen: true).user;

    ImageProvider? profileImageProvider;
    if (_profileImageBytes != null && _profileImageBytes!.isNotEmpty) {
      profileImageProvider = MemoryImage(_profileImageBytes!);
    } else if (_profileImagePath != null) {
      final file = File(_profileImagePath!);
      if (file.existsSync()) {
        profileImageProvider = FileImage(file);
      }
    } else if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(user.photoUrl!);
    } else if (user?.photoBase64 != null && user!.photoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(user.photoBase64!);
        if (bytes.isNotEmpty) {
          profileImageProvider = MemoryImage(bytes);
        }
      } catch (e) {
        // Invalid base64, ignore and show icon
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap:
                profileImageProvider != null
                    ? () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => Dialog(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.9,
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.8,
                                ),
                                child: Image(image: profileImageProvider!),
                              ),
                            ),
                      );
                    }
                    : null,
            child: CircleAvatar(
              key: ValueKey('${user?.photoUrl ?? ''}${user?.photoBase64 ?? ''}${_profileImagePath ?? ''}${_profileImageBytes?.length ?? 0}'),
              radius: 50,
              backgroundImage: profileImageProvider,
              backgroundColor: Colors.grey,
              child:
                  profileImageProvider == null
                      ? Icon(Icons.person, size: 40, color: const Color.fromARGB(255, 255, 255, 255))
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Personal Information'),
        _buildInfoTable([
          _InfoRow(
            icon: Icons.cake,
            label: 'Date of Birth',
            value: user?.dateOfBirth ?? '',
          ),
          _InfoRow(
            icon: Icons.person,
            label: 'Gender',
            value: user?.gender ?? '',
          ),
          _InfoRow(
            icon: Icons.phone,
            label: 'Contact Number',
            value: user?.contact ?? '',
          ),
          _InfoRow(
            icon: Icons.email,
            label: 'Email',
            value: user?.email ?? '',
            isLink: true,
          ),
          _InfoRow(
            icon: Icons.home,
            label: 'Address',
            value: user?.address ?? '',
          ),
          _InfoRow(
            icon: Icons.badge,
            label: 'ID/PASSPORT',
            value: user?.idNumber ?? '',
          ),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader('Employment Information'),
        _buildInfoTable([
          _InfoRow(
            icon: Icons.badge,
            label: 'Employee ID',
            value: user?.employeeId ?? '',
          ),
          _InfoRow(
            icon: Icons.work,
            label: 'Job Title/Role',
            value: user?.jobTitle ?? '',
          ),
          _InfoRow(
            icon: Icons.apartment,
            label: 'Department/Unit',
            value: user?.department ?? '',
          ),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Head Of Department',
            value: user?.hod ?? '',
          ),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader('Additional Information'),
        _buildInfoTable([
          _InfoRow(
            icon: Icons.star,
            label: 'Additional Information',
            value: user?.additionalInfo ?? '',
          ),
        ]),
      ],
    );
  }

  Widget _buildEditableForm() {
    final user = Provider.of<AuthViewModel>(context, listen: true).user;

    Widget sectionHeader(String title) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        color: const Color(0xFF0B1B3F),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }

    Widget sectionSpacing() => const SizedBox(height: 24);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                Builder(
                  builder: (context) {
                    ImageProvider? backgroundImage;
                    if (_profileImageBytes != null && _profileImageBytes!.isNotEmpty) {
                      backgroundImage = MemoryImage(_profileImageBytes!);
                    } else if (_profileImagePath != null) {
                      final file = File(_profileImagePath!);
                      if (file.existsSync()) {
                        backgroundImage = FileImage(file);
                      }
                    } else if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
                      backgroundImage = NetworkImage(user.photoUrl!);
                    } else if (user?.photoBase64 != null && user!.photoBase64!.isNotEmpty) {
                      try {
                        final bytes = base64Decode(user.photoBase64!);
                        if (bytes.isNotEmpty) {
                          backgroundImage = MemoryImage(bytes);
                        }
                      } catch (e) {
                        // Invalid base64, ignore
                      }
                    }
                    return GestureDetector(
                      onTap: backgroundImage != null
                          ? () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => Dialog(
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(
                                              context,
                                            ).size.width *
                                            0.9,
                                        maxHeight:
                                            MediaQuery.of(
                                              context,
                                            ).size.height *
                                            0.8,
                                      ),
                                      child: Image(image: backgroundImage!),
                                    ),
                                  ),
                            );
                          }
                          : null,
                      child: CircleAvatar(
                        key: ValueKey('${user?.photoUrl ?? ''}${user?.photoBase64 ?? ''}${_profileImagePath ?? ''}${_profileImageBytes?.length ?? 0}'),
                        radius: 50,
                        backgroundImage: backgroundImage,
                        backgroundColor: Colors.grey,
                        child: backgroundImage == null
                            ? Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickProfilePhoto,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                if (user?.photoUrl != null ||
                    user?.photoBase64 != null ||
                    _profileImagePath != null ||
                    _profileImageBytes != null)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _deleteProfilePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          sectionSpacing(),
          sectionHeader('Personal Information'),
          _buildTextField('First Name', controller: firstNameController),
          const SizedBox(height: 16),
          _buildTextField('Surname', controller: lastNameController),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date of Birth',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      hintText:
                          _selectedDate != null
                              ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                              : 'Select Date',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gender',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items:
                    ['Male', 'Female', 'Other'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Contact Number', controller: contactController),
          const SizedBox(height: 16),
          _buildTextField(
            'Email address',
            initialValue: emailController.text,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildTextField('Address', controller: addressController),
          const SizedBox(height: 16),
          _buildTextField('ID/PASSPORT', controller: idController),
          sectionSpacing(),
          sectionHeader('Password Reset'),
          _buildTextField(
            'Current Password',
            controller: currentPasswordController,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'New Password',
            controller: newPasswordController,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Confirm New Password',
            controller: confirmPasswordController,
            obscureText: true,
          ),
          sectionSpacing(),
          sectionHeader('Employment Information'),
          _buildTextField(
            'Employee ID',
            initialValue: empIdController.text,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Job Title/Role',
            initialValue: jobTitleController.text,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Department/Unit',
            initialValue: departmentController.text,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Head Of Department',
            initialValue: headController.text,
            readOnly: true,
          ),
          sectionSpacing(),
          sectionHeader('Additional Information'),
          _buildTextField(
            'Additional Information',
            controller: additionalInfoController,
          ),
          sectionSpacing(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => const AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text('Saving changes...'),
                            ],
                          ),
                        ),
                  );

                  bool hasErrors = false;
                  String errorMessage = '';

                  // Handle password change if fields are filled
                  if (currentPasswordController.text.isNotEmpty ||
                      newPasswordController.text.isNotEmpty ||
                      confirmPasswordController.text.isNotEmpty) {
                    if (currentPasswordController.text.isEmpty) {
                      hasErrors = true;
                      errorMessage =
                          'Current password is required for password change';
                    } else if (newPasswordController.text.isEmpty) {
                      hasErrors = true;
                      errorMessage = 'New password is required';
                    } else if (confirmPasswordController.text.isEmpty) {
                      hasErrors = true;
                      errorMessage = 'Please confirm your new password';
                    } else if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      hasErrors = true;
                      errorMessage = 'New passwords do not match';
                    } else {
                      // Attempt password change
                      await _authViewModel.changePassword(
                        currentPassword: currentPasswordController.text,
                        newPassword: newPasswordController.text,
                      );
                      if (_authViewModel.errorMessage != null) {
                        hasErrors = true;
                        errorMessage = _authViewModel.errorMessage!;
                      } else {
                        // Clear password fields on success
                        currentPasswordController.clear();
                        newPasswordController.clear();
                        confirmPasswordController.clear();
                      }
                    }
                  }

                  // Save profile changes if no password errors
                  if (!hasErrors) {
                    final updatedUser = _authViewModel.user;
                    if (updatedUser != null) {
                      debugPrint(
                        'Current user before copyWith: ${updatedUser.toMap()}',
                      );
                      final newUser = updatedUser.copyWith(
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                        dateOfBirth:
                            _selectedDate != null
                                ? DateFormat(
                                  'yyyy-MM-dd',
                                ).format(_selectedDate!)
                                : null,
                        gender: _selectedGender,
                        contact: contactController.text,
                        email: emailController.text,
                        address: addressController.text,
                        idNumber: idController.text,
                        employeeId: empIdController.text,
                        jobTitle: jobTitleController.text,
                        department: departmentController.text,
                        hod: headController.text,
                        additionalInfo: additionalInfoController.text,
                        photoUrl: updatedUser.photoUrl,
                        photoBase64: updatedUser.photoBase64,
                      );
                      debugPrint('New user after copyWith: ${newUser.toMap()}');
                      debugPrint(
                        'Updating user with new data: ${newUser.toMap()}',
                      );
                      await _authViewModel.updateUser(newUser);
                      debugPrint(
                        'Update completed. Error: ${_authViewModel.errorMessage}',
                      );
                      if (_authViewModel.errorMessage != null) {
                        hasErrors = true;
                        errorMessage = _authViewModel.errorMessage!;
                      }
                    }
                  }

                  // Close loading dialog
                  Navigator.pop(context);

                  // Check for errors and show feedback
                  if (hasErrors) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to save changes: $errorMessage'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully'),
                      ),
                    );
                  }

                  setState(() {
                    _isEditing = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pickProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera),
                title: Text('Take Photo'),
                onTap: () async {
                  try {
                    Navigator.pop(context);
                    final status = await Permission.camera.request();
                    if (status.isGranted) {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() {
                          _profileImageBytes = bytes;
                        });
                        await _uploadProfilePhoto(bytes);
                      }
                    } else {
                      print('Camera permission denied');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Camera permission denied')),
                      );
                    }
                  } catch (e, stack) {
                    print('Error picking image from camera: $e');
                    print(stack);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () async {
                  try {
                    print('Gallery option selected');
                    Navigator.pop(context);
                    if (kIsWeb) {
                      print('Web mode: picking image from gallery');
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        print('Image picked from web gallery');
                        final bytes = await image.readAsBytes();
                        print('Bytes read from image: ${bytes.length}');
                        setState(() {
                          _profileImageBytes = bytes;
                        });
                        print('About to call _uploadProfilePhoto');
                        await _uploadProfilePhoto(bytes);
                      } else {
                        print('No image picked from web gallery');
                      }
                    } else {
                      if (Platform.isAndroid) {
                        // Request permission for Android
                        print('Android: requesting permission');
                        final status = await Permission.photos.request();
                        print('Permission status: $status');
                        if (status.isGranted) {
                          print('Permission granted, picking image');
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            print('Image picked from Android gallery');
                            final bytes = await image.readAsBytes();
                            print('Bytes read from image: ${bytes.length}');
                            setState(() {
                              _profileImageBytes = bytes;
                            });
                            await _uploadProfilePhoto(bytes);
                          } else {
                            print('No image picked from Android gallery');
                          }
                        } else {
                          print('Gallery permission denied');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gallery permission denied'),
                            ),
                          );
                        }
                      } else {
                        // iOS
                        print('iOS: requesting permission');
                        final status = await Permission.photos.request();
                        print('Permission status: $status');
                        if (status.isGranted) {
                          print('Permission granted, picking image');
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            print('Image picked from iOS gallery');
                            final bytes = await image.readAsBytes();
                            print('Bytes read from image: ${bytes.length}');
                            setState(() {
                              _profileImageBytes = bytes;
                            });
                            await _uploadProfilePhoto(bytes);
                          } else {
                            print('No image picked from iOS gallery');
                          }
                        } else {
                          print('Gallery permission denied');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gallery permission denied'),
                            ),
                          );
                        }
                      }
                    }
                  } catch (e, stack) {
                    print('Error picking image from gallery: $e');
                    print('Stack trace: $stack');
                  }
                },
              ),
              if (_authViewModel.user?.photoBase64 != null ||
                  _profileImagePath != null ||
                  _profileImageBytes != null)
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _deleteProfilePhoto();
                  },
                ),
            ],
          ),
    );
  }

  Future<void> _loadProfileImage() async {
    final user = _authViewModel.user;
    if (user?.email != null) {
      final prefs = await SharedPreferences.getInstance();
      if (kIsWeb) {
        final base64 = prefs.getString('profile_image_base64_${user!.email}');
        if (base64 != null) {
          final bytes = base64Decode(base64);
          setState(() {
            _profileImageBytes = bytes;
          });
        } else if (user.photoBase64 != null && user.photoBase64!.isNotEmpty) {
          // If no local prefs, decode from user.photoBase64
          final bytes = base64Decode(user.photoBase64!);
          setState(() {
            _profileImageBytes = bytes;
          });
        } else {
          // No image data available, clear state
          setState(() {
            _profileImageBytes = null;
            _profileImagePath = null;
          });
        }
      } else {
        final imagePath = prefs.getString('profile_image_path_${user!.email}');
        if (imagePath != null) {
          final file = File(imagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            setState(() {
              _profileImagePath = imagePath;
              _profileImageBytes = bytes;
            });
          } else {
            // Remove invalid path from prefs
            await prefs.remove('profile_image_path_${user.email}');
            setState(() {
              _profileImagePath = null;
              _profileImageBytes = null;
            });
          }
        } else if (user.photoBase64 != null) {
          // If no local prefs, decode from user.photoBase64
          final bytes = base64Decode(user.photoBase64!);
          setState(() {
            _profileImageBytes = bytes;
          });
        } else {
          // No image data available, clear state
          setState(() {
            _profileImagePath = null;
            _profileImageBytes = null;
          });
        }
      }
    } else {
      // No user, clear state
      setState(() {
        _profileImagePath = null;
        _profileImageBytes = null;
      });
    }
  }

  Future<void> _deleteProfilePhoto() async {
    final user = _authViewModel.user;
    if (user == null) return;

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Do you confirm to remove the profile photo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      // Update user model to clear photo fields
      final updatedUser = user.copyWith(photoBase64: null, photoUrl: null);
      await _authViewModel.updateUser(updatedUser);

      if (_authViewModel.errorMessage != null) {
        // Update failed, show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete profile photo: ${_authViewModel.errorMessage}')),
          );
        }
        return;
      }

      // Remove local file cache
      if (user.email != null) {
        final prefs = await SharedPreferences.getInstance();
        if (kIsWeb) {
          await prefs.remove('profile_image_base64_${user.email}');
        } else {
          final imagePath = prefs.getString('profile_image_path_${user.email}');
          if (imagePath != null) {
            final file = File(imagePath);
            if (await file.exists()) {
              await file.delete();
            }
            await prefs.remove('profile_image_path_${user.email}');
          }
        }
      }

      // Clear local state
      setState(() {
        _profileImagePath = null;
        _profileImageBytes = null;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting profile photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete profile photo: $e')),
        );
      }
    }
  }

  Future<void> _uploadProfilePhoto(Uint8List bytes) async {
    print('_uploadProfilePhoto called with bytes length: ${bytes.length}');
    final user = _authViewModel.user;
    if (user == null) {
      print('Error: User is null');
      return;
    }

    try {
      print('Starting upload for user: ${user.uid}');

      // Encode bytes to base64
      final base64String = base64Encode(bytes);

      // Update Firestore user document with photoBase64 (skip photoUrl since Storage is not enabled)
      print('Updating Firestore...');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'photoBase64': base64String},
      );
      print('Firestore updated');

      // Update local user model
      print('Updating local user model...');
      final updatedUser = user.copyWith(photoBase64: base64String);
      _authViewModel.setUser(updatedUser);
      print('User model updated with photoBase64');

      // Save image bytes to local file and store path in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (kIsWeb) {
        await prefs.setString(
          'profile_image_base64_${user.email}',
          base64String,
        );
        setState(() {
          _profileImageBytes = bytes;
        });
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/profile_image_${user.email}.jpg';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        await prefs.setString('profile_image_path_${user.email}', filePath);
        setState(() {
          _profileImagePath = filePath;
          _profileImageBytes = null;
        });
      }

      print('Upload completed successfully');
    } catch (e, stack) {
      print('Error uploading profile photo: $e');
      print('Stack trace: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile photo: $e')),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: const Color(0xFF0B1B3F),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildInfoTable(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(5)},
        border: TableBorder(
          verticalInside: BorderSide(color: Colors.grey.shade300),
          horizontalInside: BorderSide(color: Colors.grey.shade300),
        ),
        children:
            rows.map((row) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          row.icon,
                          size: 20,
                          color: const Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            row.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:
                        row.isLink
                            ? GestureDetector(
                              onTap: () {
                                final Uri emailLaunchUri = Uri(
                                  scheme: 'mailto',
                                  path: row.value,
                                );
                                launchUrl(emailLaunchUri);
                              },
                              child: Text(
                                row.value,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontSize: 16,
                                ),
                              ),
                            )
                            : Text(
                              row.value,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    final isSelectedColor = isSelected ? Colors.grey.shade700 : Colors.transparent;
    return Container(
      color: isSelectedColor,
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        onTap:
            onTap ??
            () {
              Navigator.pop(context); // Close drawer
            },
      ),
    );
  }
}
