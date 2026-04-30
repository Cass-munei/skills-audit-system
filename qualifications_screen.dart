import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skills_audit_system/screens/terms_of_use_screen.dart';
import 'package:skills_audit_system/screens/terms_privacy_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'skills_screen.dart';
import 'training_screen.dart';
import 'documents_screen.dart';
import 'notifications_screen.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/qualifications_viewmodel.dart';
import '../models/qualification.dart';
import '../models/user.dart';

class QualificationsScreen extends StatefulWidget {
  const QualificationsScreen({super.key});

  @override
  _QualificationsScreenState createState() => _QualificationsScreenState();
}

class _QualificationsScreenState extends State<QualificationsScreen> {
  String? _profileImagePath;
  Uint8List? _profileImageBytes;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController institutionController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final qualificationsViewModel = Provider.of<QualificationsViewModel>(
        context,
        listen: false,
      );
      final user = authViewModel.user;
      _loadProfileImage(user?.email, user);
      if (user != null) {
        qualificationsViewModel.startListeningToQualifications();
      }
    });
  }

  Future<void> _loadProfileImage(String? email, User? user) async {
    if (email != null) {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('profile_image_path_$email');
      if (path != null && File(path).existsSync()) {
        setState(() {
          _profileImagePath = path;
          _profileImageBytes = null;
        });
      } else if (user?.photoBase64 != null) {
        final bytes = base64Decode(user!.photoBase64!);
        setState(() {
          _profileImagePath = null;
          _profileImageBytes = bytes;
        });
      } else {
        setState(() {
          _profileImagePath = null;
          _profileImageBytes = null;
        });
      }
    }
  }

  void _addQualification() {
    nameController.clear();
    institutionController.clear();
    yearController.clear();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Qualification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Qualification Name',
                  ),
                ),
                TextField(
                  controller: institutionController,
                  decoration: const InputDecoration(labelText: 'Institution'),
                ),
                TextField(
                  controller: yearController,
                  decoration: InputDecoration(
                    labelText: 'Year Obtained',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          initialDatePickerMode: DatePickerMode.year,
                        );
                        if (picked != null) {
                          yearController.text = picked.year.toString();
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      institutionController.text.isNotEmpty &&
                      yearController.text.isNotEmpty) {
                    final viewModel = Provider.of<QualificationsViewModel>(
                      context,
                      listen: false,
                    );
                    await viewModel.addQualification(
                      nameController.text,
                      institutionController.text,
                      yearController.text,
                    );
                    if (viewModel.errorMessage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Qualification added successfully'),
                        ),
                      );
                      await viewModel
                          .loadQualifications(); // Reload to ensure consistency
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to add qualification: ${viewModel.errorMessage}',
                          ),
                        ),
                      );
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _editQualification(Qualification qual) {
    nameController.text = qual.name;
    institutionController.text = qual.institution;
    yearController.text = qual.date;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Qualification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Qualification Name',
                  ),
                ),
                TextField(
                  controller: institutionController,
                  decoration: const InputDecoration(labelText: 'Institution'),
                ),
                TextField(
                  controller: yearController,
                  decoration: InputDecoration(
                    labelText: 'Year Obtained',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          initialDatePickerMode: DatePickerMode.year,
                        );
                        if (picked != null) {
                          yearController.text = picked.year.toString();
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      institutionController.text.isNotEmpty &&
                      yearController.text.isNotEmpty) {
                    await Provider.of<QualificationsViewModel>(
                      context,
                      listen: false,
                    ).updateQualification(
                      qual.id,
                      nameController.text,
                      institutionController.text,
                      yearController.text,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _deleteQualification(String id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Qualification'),
            content: const Text(
              'Are you sure you want to delete this qualification?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await Provider.of<QualificationsViewModel>(
                    context,
                    listen: false,
                  ).deleteQualification(id);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    Provider.of<QualificationsViewModel>(
      context,
      listen: false,
    ).stopListeningToQualifications();
    nameController.dispose();
    institutionController.dispose();
    yearController.dispose();
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
          'QUALIFICATIONS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, child) {
              final user = authViewModel.user;
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage:
                          _profileImagePath != null &&
                                  File(_profileImagePath!).existsSync()
                              ? FileImage(File(_profileImagePath!))
                              : (_profileImageBytes != null
                                  ? MemoryImage(_profileImageBytes!)
                                  : (user?.photoUrl != null
                                      ? NetworkImage(user!.photoUrl!)
                                          as ImageProvider
                                      : null)),
                      backgroundColor: Colors.transparent,
                      child:
                          (_profileImagePath == null &&
                                  _profileImageBytes == null &&
                                  user?.photoUrl == null)
                              ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              )
                              : null,
                    ),
                  ),
                ),
              );
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
                        false,
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
                    true,
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
                            builder: (context) => const TermsPrivacyScreen(),
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
      body: Consumer<QualificationsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Academic Qualifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            border: Border(
                              left: BorderSide(color: const Color(0xFF0F172A)),
                              right: BorderSide(color: const Color(0xFF0F172A)),
                              bottom: BorderSide(color: const Color(0xFF0F172A)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (viewModel.qualifications.isEmpty)
                                Center(
                                  child: Column(
                                    children: [
                                      const Text(
                                        'No qualifications added yet.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _addQualification,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0F172A),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('+ Add Qualification'),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        dividerThickness: 1.0,
                                        columns: [
                                          DataColumn(
                                            label: Text(
                                              'Qualification Name',
                                              style: TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Institution',
                                              style: TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Year',
                                              style: TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Actions',
                                              style: TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows:
                                            viewModel.qualifications
                                                .map(
                                                  (qual) => DataRow(
                                                    cells: [
                                                      DataCell(Text(qual.name)),
                                                      DataCell(
                                                        Text(qual.institution),
                                                      ),
                                                      DataCell(Text(qual.date)),
                                                      DataCell(
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            GestureDetector(
                                                              onTap:
                                                                  () => _editQualification(
                                                                    qual,
                                                                  ),
                                                              child: const Text(
                                                                'Edit',
                                                                style: TextStyle(
                                                                  color: Color(
                                                                    0xFF0F172A,
                                                                  ),
                                                                  decoration:
                                                                      TextDecoration
                                                                          .underline,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 16,
                                                            ),
                                                            GestureDetector(
                                                              onTap:
                                                                  () => _deleteQualification(
                                                                    qual.id,
                                                                  ),
                                                              child: const Text(
                                                                'Delete',
                                                                style: TextStyle(
                                                                  color: Colors.red,
                                                                  decoration:
                                                                      TextDecoration
                                                                          .underline,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              if (viewModel.errorMessage != null)
                                Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Error: ${viewModel.errorMessage}',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (viewModel.qualifications.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: _addQualification,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('+ Add Qualification'),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    '© 2025 Skills Audit System. All rights reserved.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
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
