import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skills_audit_system/screens/login_screen.dart';
import 'package:skills_audit_system/screens/terms_of_use_screen.dart';
import 'package:skills_audit_system/screens/terms_privacy_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'qualifications_screen.dart';
import 'training_screen.dart';
import 'documents_screen.dart';
import 'notifications_screen.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/skills_viewmodel.dart' as skills_vm;
import '../models/skill_demand.dart';
import '../models/user.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  String? _profileImagePath;
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final skillsViewModel = context.read<skills_vm.SkillsViewModel>();
      final user = authViewModel.user;
      _loadProfileImage(user?.email, user);
      if (user != null) {
        skillsViewModel.startListeningToSkills();
        skillsViewModel.loadSkillsInDemand(user.department);
      }
    });
  }

  @override
  void dispose() {
    context.read<skills_vm.SkillsViewModel>().stopListeningToSkills();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthViewModel, skills_vm.SkillsViewModel>(
      builder: (context, authViewModel, skillsViewModel, child) {
        final skillsInDemandToShow = skillsViewModel.skillsInDemand;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
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
              'SKILLS',
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
                              _profileImageBytes != null
                                  ? MemoryImage(_profileImageBytes!)
                                  : (_profileImagePath != null &&
                                          File(_profileImagePath!).existsSync()
                                      ? FileImage(File(_profileImagePath!))
                                      : (user?.photoUrl != null
                                          ? NetworkImage(user!.photoUrl!)
                                              as ImageProvider
                                          : null)),
                          backgroundColor: Colors.transparent,
                          child:
                              (_profileImageBytes == null &&
                                      _profileImagePath == null &&
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
                        true,
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
                                          () => Navigator.pop(
                                            screenContext,
                                            false,
                                          ),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(
                                            screenContext,
                                            true,
                                          ),
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
          body: Consumer2<AuthViewModel, skills_vm.SkillsViewModel>(
            builder: (context, authViewModel, skillsViewModel, child) {
              final skillsInDemandToShow = skillsViewModel.skillsInDemand;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Skills In Demand Section
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F172A),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Skills In Demand',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: skillsViewModel.isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : skillsInDemandToShow.isEmpty
                                            ? const Center(
                                              child: Text(
                                                'There are no skills that are in demand within your department',
                                                style: TextStyle(color: Colors.grey),
                                                textAlign: TextAlign.center,
                                              ),
                                            )
                                            : Column(
                                              children: skillsInDemandToShow.map((demand) {
                                                return Column(
                                                  children: [
                                                    _buildSkillDemandRow(context, demand),
                                                    if (demand != skillsInDemandToShow.last)
                                                      const Divider(color: Colors.grey),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Add Your Skills Section
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
                                'Add your skills',
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
                                  const Text(
                                    'Your Skills',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (skillsViewModel.skills.isEmpty)
                                    const Center(
                                      child: Text(
                                        'No skills added yet.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  else
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        dividerThickness: 1.0,
                                        columns: [
                                          DataColumn(
                                            label: Text(
                                              'Skill Name',
                                              style: TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Category',
                                              style: TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Proficiency Level',
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
                                            skillsViewModel.skills
                                                .map(
                                                  (skill) => DataRow(
                                                    cells: [
                                                      DataCell(Text(skill.name)),
                                                      DataCell(
                                                        Text(skill.category),
                                                      ),
                                                      DataCell(
                                                        Text(skill.proficiency),
                                                      ),
                                                      DataCell(
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            GestureDetector(
                                                              onTap:
                                                                  () => _editSkill(
                                                                    context,
                                                                    skill,
                                                                    skillsViewModel,
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
                                                                  () => _deleteSkill(
                                                                    context,
                                                                    skill.id,
                                                                    skillsViewModel,
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
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton(
                                onPressed: () => _addSkill(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('+ Add Skill'),
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
      },
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

  Widget _buildSkillDemandRow(BuildContext context, SkillDemand demand) {
    final gapPercent = (demand.gapPercentage * 100).round();
    Color gapColor;
    if (gapPercent <= 33) {
      gapColor = Colors.green;
    }else if(gapPercent >33 && gapPercent <= 66){
      gapColor = Colors.yellow;
    }
     else {
      gapColor = Colors.red;
    }
    return InkWell(
      onTap: () => _showSkillDetailsDialog(context, demand),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    demand.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    demand.department,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$gapPercent%',
              style: TextStyle(
                color: gapColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSkillDetailsDialog(BuildContext context, SkillDemand demand) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title Row with Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${demand.name} – Details',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Skill Information Section
                Row(
                  children: [
                    const Icon(Icons.info, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Skill Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.grey, thickness: 1),
                const SizedBox(height: 16),
                // Two-Column Metrics Layout
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning, color: Color(0xFF0F172A), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Gap Percentage:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text('${(demand.gapPercentage * 100).round()}%'),
                      ],
                    ),
                    const TableRow(
                      children: [
                        SizedBox(height: 12),
                        SizedBox(height: 12),
                      ],
                    ),
                    TableRow(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people, color: Color(0xFF0F172A), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Employees Matching:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text('${demand.employeesMatching}/${demand.totalEmployees}'),
                      ],
                    ),
                    const TableRow(
                      children: [
                        SizedBox(height: 12),
                        SizedBox(height: 12),
                      ],
                    ),
                    TableRow(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.trending_up, color: Color(0xFF0F172A), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Required Level:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text(demand.requiredLevel),
                      ],
                    ),
                    const TableRow(
                      children: [
                        SizedBox(height: 12),
                        SizedBox(height: 12),
                      ],
                    ),
                    TableRow(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business, color: Color(0xFF0F172A), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Department:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text(demand.department),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey, thickness: 1),
                const SizedBox(height: 16),
                // Skill Description Section
                if (demand.description.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.description, color: Color(0xFF0F172A), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Skill Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          demand.description,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Recommendation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Color(0xFF0F172A), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recommenation: '
                          'High priority – Immediate upskilling recommended.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey, thickness: 1),
                const SizedBox(height: 16),
                // Skill Description Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.book, color: Color(0xFF0F172A), size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Skill Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${demand.name} is a valuable skill in our organization. Mastering this competency will enhance your professional development and contribute to team success. Consider exploring training opportunities and practical applications to strengthen this skill.',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Close Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addSkill(BuildContext context) {
    final nameController = TextEditingController();
    String selectedCategory = 'Cognitive & Analytical Skills';
    String selectedProficiency = 'Beginner';
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Skill',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Skill name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    'Cognitive & Analytical Skills',
                    'Technical & IT Skills',
                    'Accountant',
                    'Business & Management Skills',
                    'Interpersonal & Communication Skills',
                    'Leadership & Supervisory Skills',
                    'Creative & Design Skills',
                    'Engineering & Technical Trade Skills',
                    'Compliance & Legal Skills',
                    'Digital & Media Skills',
                    'Education & Training Skills',
                    'Personal Effectiveness Skills',
                    'Language & Communication Skills',
                    'Operational & Field Skills',
                    'Environmental & Sustainability Skills',
                    'Other',
                  ].map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedCategory = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedProficiency,
                  decoration: const InputDecoration(
                    labelText: 'Proficiency Level',
                  ),
                  items:
                      ['Beginner', 'Intermediate', 'Advanced', 'Expert'].map((
                        level,
                      ) {
                        return DropdownMenuItem<String>(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedProficiency = value;
                    }
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          context.read<skills_vm.SkillsViewModel>().addSkill(
                            name,
                            selectedProficiency,
                            selectedCategory,
                          );
                        }
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editSkill(
    BuildContext context,
    skills_vm.Skill skill,
    skills_vm.SkillsViewModel viewModel,
  ) {
    final nameController = TextEditingController(text: skill.name);
    String selectedCategory = skill.category;
    String selectedProficiency = skill.proficiency;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Skill',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Skill name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items:
                      [
                      'Cognitive & Analytical Skills',
                        'Technical & IT Skills',
                        'Accountant',
                        'Business & Management Skills',
                        'Interpersonal & Communication Skills',
                        'Leadership & Supervisory Skills',
                        'Creative & Design Skills',
                        'Engineering & Technical Trade Skills',
                        'Compliance & Legal Skills',
                        'Digital & Media Skills',
                        'Education & Training Skills',
                        'Personal Effectiveness Skills',
                        'Language & Communication Skills',
                        'Operational & Field Skills',
                        'Environmental & Sustainability Skills',
                        'Other',
                      ].map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedCategory = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedProficiency,
                  decoration: const InputDecoration(
                    labelText: 'Proficiency Level',
                  ),
                  items:
                      ['Beginner', 'Intermediate', 'Advanced', 'Expert'].map((
                        level,
                      ) {
                        return DropdownMenuItem<String>(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedProficiency = value;
                    }
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          viewModel.updateSkill(
                            skill.id,
                            name,
                            selectedProficiency,
                            selectedCategory,
                          );
                        }
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteSkill(
    BuildContext context,
    String skillId,
    skills_vm.SkillsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Skill'),
        content: const Text(
          'Are you sure you want to delete this skill?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              viewModel.deleteSkill(skillId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
