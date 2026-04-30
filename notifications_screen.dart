import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skills_audit_system/screens/terms_of_use_screen.dart';
import 'package:skills_audit_system/screens/terms_privacy_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_html/flutter_html.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'skills_screen.dart';
import 'qualifications_screen.dart';
import 'training_screen.dart';
import 'documents_screen.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notifications_viewmodel.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final user = authViewModel.user;
      _loadProfileImage(user?.email);
      context.read<NotificationsViewModel>().loadNotifications();
    });
  }

  Future<void> _loadProfileImage(String? email) async {
    if (email != null) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _profileImagePath = prefs.getString('profile_image_path_$email');
      });
    }
  }

  void _openNotification(NotificationItem notification) {
    // Mark as read when opening
    if (!notification.isRead) {
      context.read<NotificationsViewModel>().markAsRead(notification.id);
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Html(data: notification.message),
              if (notification.attachmentUrl != null && notification.attachmentName != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.attach_file, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final url = Uri.parse(notification.attachmentUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unable to open attachment')),
                            );
                          }
                        },
                        child: Text(
                          notification.attachmentName!,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(String id) {
    context.read<NotificationsViewModel>().deleteNotification(id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
  }

  void _markAllAsRead() {
    final vm = context.read<NotificationsViewModel>();
    for (var notification in vm.notifications.where((n) => !n.isRead)) {
      vm.markAsRead(notification.id);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
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
          'NOTIFICATIONS',
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
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: user?.photoBase64 != null
                          ? MemoryImage(base64Decode(user!.photoBase64!))
                          : (_profileImagePath != null &&
                                  File(_profileImagePath!).existsSync()
                              ? FileImage(File(_profileImagePath!))
                              : (user?.photoUrl != null
                                  ? NetworkImage(user!.photoUrl!)
                                      as ImageProvider
                                  : null)),
                      backgroundColor: Colors.transparent,
                      child: (user?.photoBase64 == null &&
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
                    true,
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
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unable to open URL')),
                          );
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
      body: Consumer<NotificationsViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.errorMessage != null) {
            return Center(child: Text('Error: ${vm.errorMessage}'));
          }
          List<NotificationItem> filtered =
              _selectedFilter == 'All'
                  ? vm.notifications
                  : vm.notifications.where((n) => !n.isRead).toList();
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter and Mark All As Read Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                value: _selectedFilter,
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'All',
                                    child: Text('All'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Unread',
                                    child: Text('Unread'),
                                  ),
                                ],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedFilter = newValue!;
                                  });
                                },
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                ),
                                dropdownColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _markAllAsRead,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Mark All As Read'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Notifications List or Empty Message
                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(
                              child: const Text(
                                'No notifications available.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          ...filtered.map((notification) {
                            return GestureDetector(
                              onTap: () => _openNotification(notification),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0F000000),
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                  border: const Border(
                                    left: BorderSide(
                                      color: Color(0xFF0F172A),
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: notification.isRead,
                                      onChanged: (value) {
                                        if (!notification.isRead) {
                                          context.read<NotificationsViewModel>().markAsRead(notification.id);
                                        }
                                      },
                                      activeColor: const Color(0xFF0F172A),
                                      shape: const CircleBorder(),
                                      side: const BorderSide(
                                        color: Color(0xFF6B7280),
                                        width: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notification.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('dd MMM yyyy, HH:mm').format(notification.timestamp),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Html(
                                                  data: notification.message,
                                                  style: {
                                                    'body': Style(
                                                      fontSize: FontSize(14.0),
                                                      color: const Color(0xFF374151),
                                                      fontWeight: FontWeight.w500,
                                                      lineHeight: LineHeight(1.4),
                                                    ),
                                                  },
                                                ),
                                              ),
                                              if (notification.attachmentUrl != null) ...[
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.attach_file,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: const Text(
                    '© 2025 Skills Audit System, All rights reserved',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
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
