import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skills_audit_system/screens/terms_of_use_screen.dart';
import 'package:skills_audit_system/screens/terms_privacy_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'skills_screen.dart';
import 'qualifications_screen.dart';
import 'documents_screen.dart';
import 'notifications_screen.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/training_viewmodel.dart';
import '../models/user.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  _TrainingScreenState createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _profileImagePath;
  Uint8List? _profileImageBytes;

  late TrainingViewModel _trainingViewModel;

  // No static data needed, will filter from viewmodel

  final TextEditingController _trainingNameController = TextEditingController();
  final TextEditingController _providerController = TextEditingController();
  final TextEditingController _plannedController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }

  String _calculateStatus(String startDate, String endDate) {
    try {
      DateTime now = DateTime.now();
      DateTime start = DateTime.parse(startDate);
      DateTime end = DateTime.parse(endDate);
      if (now.isBefore(start)) {
        return 'Upcoming';
      } else if (now.isAfter(end)) {
        return 'Completed';
      } else {
        return 'In Progress';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _trainingViewModel = Provider.of<TrainingViewModel>(
        context,
        listen: false,
      );
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final user = authViewModel.user;
      _loadProfileImage(user?.email, user);
      if (user != null) {
        _trainingViewModel.startListeningToTrainings();
      }
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _trainingViewModel.stopListeningToTrainings();
    _searchController.dispose();
    _trainingNameController.dispose();
    _providerController.dispose();
    _plannedController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      // Filter trainings from viewmodel
      // This will be handled in the build method with Consumer
    });
  }

  void _addPlannedTraining() {
    _selectedStartDate = null;
    _selectedEndDate = null;
    _trainingNameController.clear();
    _providerController.clear();
    _plannedController.clear();
    _endController.clear();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Planned Training'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _trainingNameController,
                  decoration: const InputDecoration(labelText: 'Training Name'),
                ),
                TextField(
                  controller: _providerController,
                  decoration: const InputDecoration(labelText: 'Provider'),
                ),
                TextField(
                  controller: _plannedController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedStartDate = picked;
                            _plannedController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(picked);
                          });
                        }
                      },
                    ),
                  ),
                ),
                TextField(
                  controller: _endController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedEndDate = picked;
                            _endController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(picked);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_trainingNameController.text.isNotEmpty &&
                      _providerController.text.isNotEmpty &&
                      _plannedController.text.isNotEmpty &&
                      _endController.text.isNotEmpty) {
                    _trainingViewModel.addTraining(
                      _trainingNameController.text,
                      _providerController.text,
                      _plannedController.text,
                      _endController.text,
                      '',
                    );
                    _trainingNameController.clear();
                    _providerController.clear();
                    _plannedController.clear();
                    _endController.clear();
                  }
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _editPlannedTraining(Training training) {
    _trainingNameController.text = training.trainingName;
    _providerController.text = training.provider;
    _plannedController.text = training.startDate;
    _endController.text = training.endDate;
    _selectedStartDate = DateTime.tryParse(training.startDate);
    _selectedEndDate = DateTime.tryParse(training.endDate);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Planned Training'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _trainingNameController,
                  decoration: const InputDecoration(labelText: 'Training Name'),
                ),
                TextField(
                  controller: _providerController,
                  decoration: const InputDecoration(labelText: 'Provider'),
                ),
                TextField(
                  controller: _plannedController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedStartDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedStartDate = picked;
                            _plannedController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(picked);
                          });
                        }
                      },
                    ),
                  ),
                ),
                TextField(
                  controller: _endController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedEndDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedEndDate = picked;
                            _endController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(picked);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_trainingNameController.text.isNotEmpty &&
                      _providerController.text.isNotEmpty &&
                      _plannedController.text.isNotEmpty &&
                      _endController.text.isNotEmpty) {
                    _trainingViewModel.updateTraining(
                      training.id,
                      _trainingNameController.text,
                      _providerController.text,
                      _plannedController.text,
                      _endController.text,
                      '',
                    );
                    _trainingNameController.clear();
                    _providerController.clear();
                    _plannedController.clear();
                    _endController.clear();
                    _selectedStartDate = null;
                    _selectedEndDate = null;
                  }
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _deletePlannedTraining(String id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Training'),
            content: const Text(
              'Are you sure you want to delete this training?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await _trainingViewModel.deleteTraining(id);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
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
          'TRAINING',
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
                          user?.photoBase64 != null
                              ? MemoryImage(base64Decode(user!.photoBase64!))
                              : (_profileImagePath != null &&
                                      File(_profileImagePath!).existsSync()
                                  ? FileImage(File(_profileImagePath!))
                                  : (user?.photoUrl != null
                                      ? NetworkImage(user!.photoUrl!)
                                          as ImageProvider
                                      : null)),
                      backgroundColor: Colors.transparent,
                      child:
                          (user?.photoBase64 == null &&
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
                    true,
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search Training',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Planned Training Section
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
                        'Planned Training',
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
                      child: Consumer<TrainingViewModel>(
                        builder: (context, viewModel, child) {
                          final filteredTrainings =
                              viewModel.trainings
                                  .where(
                                    (training) =>
                                        training.trainingName
                                            .toLowerCase()
                                            .contains(_searchQuery) &&
                                        _calculateStatus(
                                          training.startDate,
                                          training.endDate,
                                        ) !=
                                        'Completed',
                                  )
                                  .toList();
                          return Column(
                            children: [
                              if (filteredTrainings.isEmpty)
                                const Center(
                                  child: Text(
                                    'No planned trainings added yet.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 20.0,
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          'Training Name',
                                          style: TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Provider',
                                          style: TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Start Date',
                                          style: TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'End Date',
                                          style: TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Status',
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
                                        filteredTrainings
                                            .map(
                                              (training) => DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(training.trainingName),
                                                  ),
                                                  DataCell(
                                                    Text(training.provider),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      _formatDate(
                                                        training.startDate,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      _formatDate(
                                                        training.endDate,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      _calculateStatus(
                                                        training.startDate,
                                                        training.endDate,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        GestureDetector(
                                                          onTap:
                                                              () =>
                                                                  _editPlannedTraining(
                                                                    training,
                                                                  ),
                                                          child: const Text(
                                                            'Edit',
                                                            style: TextStyle(
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                              color: Color(
                                                                0xFF0F172A,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 16,
                                                        ),
                                                        GestureDetector(
                                                          onTap:
                                                              () =>
                                                                  _deletePlannedTraining(
                                                                    training.id,
                                                                  ),
                                                          child: const Text(
                                                            'Delete',
                                                            style: TextStyle(
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                              color: Colors.red,
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
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _addPlannedTraining,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('+Add Training'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Past Records Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Past Records',
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
                          left: BorderSide(color: Colors.blueGrey),
                          right: BorderSide(color: Colors.blueGrey),
                          bottom: BorderSide(color: Colors.blueGrey),
                        ),
                      ),
                      child: Consumer<TrainingViewModel>(
                        builder: (context, viewModel, child) {
                          final allFilteredTrainings =
                              viewModel.trainings
                                  .where(
                                    (training) => training.trainingName
                                        .toLowerCase()
                                        .contains(_searchQuery),
                                  )
                                  .toList();
                          final pastTrainings =
                              allFilteredTrainings
                                  .where(
                                    (training) =>
                                        _calculateStatus(
                                          training.startDate,
                                          training.endDate,
                                        ) ==
                                        'Completed',
                                  )
                                  .toList();
                          return Column(
                            children: [
                              if (pastTrainings.isEmpty)
                                const Center(
                                  child: Text(
                                    'No past training records.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 20.0,
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          'Training Name',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Provider',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Start Date',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'End Date',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Status',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows:
                                        pastTrainings
                                            .map(
                                              (training) => DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(training.trainingName),
                                                  ),
                                                  DataCell(
                                                    Text(training.provider),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      _formatDate(
                                                        training.startDate,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      _formatDate(
                                                        training.endDate,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      _calculateStatus(
                                                        training.startDate,
                                                        training.endDate,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
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
              Navigator.pop(context);
            },
      ),
    );
  }
}
