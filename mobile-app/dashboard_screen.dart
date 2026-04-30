import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'skills_screen.dart';
import 'qualifications_screen.dart';
import 'training_screen.dart';
import 'documents_screen.dart';
import 'notifications_screen.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/user.dart';
import 'terms_privacy_screen.dart';
import 'terms_of_use_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _profileImagePath;
  Uint8List? _profileImageBytes;
  String? _lastPhotoUrl;
  late AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    _authViewModel.addListener(_onUserChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = _authViewModel.user;
      _loadProfileImage(user?.email, user);
      _lastPhotoUrl = user?.photoUrl;
      context.read<DashboardViewModel>().loadDashboardData();
    });
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    final user = _authViewModel.user;
    if (user != null && user.photoUrl != _lastPhotoUrl) {
      _lastPhotoUrl = user.photoUrl;
      _loadProfileImage(user.email, user);
    }
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
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, child) {
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
            actions: [
              Consumer<AuthViewModel>(
                builder: (context, authViewModel, child) {
                  final user = authViewModel.user;
                  final employeeId = user?.employeeId ?? 'User';
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(
                      child: Text(
                        'Welcome, $employeeId',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Consumer<AuthViewModel>(
                builder: (context, authViewModel, child) {
                  final user = authViewModel.user;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
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
                        true,
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
                            await viewModel.signOut();
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildOverviewCard(
                          viewModel.trainingCompleted.toString(),
                          'Trainings Added',
                          onTap:
                              () => Navigator.pushNamed(context, '/training'),
                        ),
                        _buildOverviewCard(
                          viewModel.qualificationsAdded.toString(),
                          'Qualifications Added',
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/qualifications',
                              ),
                        ),
                        _buildOverviewCard(
                          viewModel.newNotifications.toString(),
                          'New Notifications',
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/notifications',
                              ),
                        ),
                        _buildOverviewCard(
                          viewModel.skillsInDemand.toString(),
                          'Skills Added',
                          onTap: () => Navigator.pushNamed(context, '/skills'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildProgressTracker(viewModel),
                    const SizedBox(height: 24),
                    _buildTodaysTasks(viewModel),
                    const SizedBox(height: 24),
                    _buildUpcomingDeadlines(viewModel),
                    const SizedBox(height: 24),
                    _buildRecentActivity(viewModel),
                    const SizedBox(height: 24),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '© 2025 Skills Audit System, All rights reserved',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    final isSelectedColor =
        isSelected ? Colors.grey.shade700 : Colors.transparent;
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
              Navigator.pop(context);
              if (title == 'My Profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              }
            },
      ),
    );
  }

  Widget _buildOverviewCard(String count, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1B3F),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTracker(DashboardViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Tracker',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: viewModel.ratingProgress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF0B1B3F)),
                  ),
                ),
                Text(
                  '${(viewModel.ratingProgress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFF0B1B3F),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Profile completed',
            style: TextStyle(color: Color(0xFF0B1B3F)),
          ),
          const SizedBox(height: 16),
          _buildProgressBar('Rating', viewModel.ratingProgress),
          _buildProgressBar('Skills', viewModel.skillsProgress),
          _buildProgressBar('Documents', viewModel.documentsProgress),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF0F172A)),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: const Color(0xFF0F172A),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysTasks(DashboardViewModel viewModel) {
    final taskIcons = {
      'Upload documents': Icons.cloud_upload,
      'Add acquired skills': Icons.add,
      'Add planned training': Icons.book,
      'Add qualification': Icons.school,
    };

    final taskRoutes = {
      'Upload documents': '/documents',
      'Add acquired skills': '/skills',
      'Add planned training': '/training',
      'Add qualification': '/qualifications',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Access Panel",
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...viewModel.todaysTasks.map((task) {
            return GestureDetector(
              onTap: () {
                final route = taskRoutes[task];
                if (route != null) {
                  Navigator.pushNamed(context, route);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      taskIcons[task] ?? Icons.task,
                      color: const Color(0xFF0F172A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildUpcomingDeadlines(DashboardViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Deadlines',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (viewModel.upcomingDeadlines.isEmpty)
            const Text(
              'No upcoming deadline',
              style: TextStyle(color: Color(0xFF0F172A)),
            )
          else
            ...viewModel.upcomingDeadlines.map((deadline) {
              final date = deadline['date'] as String? ?? '';
              final title = deadline['title'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF0F172A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(DashboardViewModel viewModel) {
    if (viewModel.recentActivities.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Recent Activity',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...viewModel.recentActivities.map((activity) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.play_arrow, color: Color(0xFF0F172A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
