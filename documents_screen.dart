import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skills_audit_system/screens/terms_of_use_screen.dart';
import 'package:skills_audit_system/screens/terms_privacy_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import 'profile_screen.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/documents_viewmodel.dart';

// ignore: library_private_types_in_public_api
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  _DocumentsScreenState createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _profileImageBase64;
  late DocumentsViewModel documentsViewModel;

  // Document lists
  List<Map<String, dynamic>> identityComplianceDocuments = [];
  List<Map<String, dynamic>> educationalDocuments = [];
  List<Map<String, dynamic>> professionalDocuments = [];
  List<Map<String, dynamic>> trainingDevelopmentDocuments = [];
  List<Map<String, dynamic>> regulatoryDocuments = [];

  // Filtered document lists
  List<Map<String, dynamic>> filteredIdentityComplianceDocuments = [];
  List<Map<String, dynamic>> filteredEducationalDocuments = [];
  List<Map<String, dynamic>> filteredProfessionalDocuments = [];
  List<Map<String, dynamic>> filteredTrainingDevelopmentDocuments = [];
  List<Map<String, dynamic>> filteredRegulatoryDocuments = [];

  // Document categories and their types
  final Map<String, List<String>> documentCategories = {
    'Identity & Compliance Documents': [
      'SA ID / Passport',
      'Work/Residence Permit',
      'Tax Num / SARS Documentation',
      'Police Clearance Cert.',
    ],
    'Educational Qualifications': [
      'NSC/Grade 12',
      'Diplomas / Degrees',
      ' Professional Cert.',
      'Academic Transcript',
    ],
    'Professional & Employment Records': [
      'Curriculum Vitae (CV)',
      'Reference Letters',
      'Employement Contracts',
      'Proof of Employement',
    ],
    'Training & Development': [
      'Training Certificates',
      'Skills Development Cert.',
      'Learnership / Apprenticeship',
    ],
    'Regulatory & Industry-Specific Documents': [
      'Membership Certificates',
      'Registration with Professional Bodies',
      'Security Clearance',
    ],
  };

  // Map for displaying detailed names
  final Map<String, String> typeDisplayMap = {
    'SA ID / Passport': 'South African ID or Passport',
    'Work/Residence Permit': 'Work/Residence Permit (if applicable)',
    'Tax Num / SARS Documentation': 'Tax Number / SARS Documentation',
    'Police Clearance Cert.':
        'Police Clearance Certificate (for compliance in certain roles)',
    'NSC/Grade 12': 'Matric Certificate (NSC/Grade 12)',
    'Diplomas / Degrees':
        'Diplomas / Degrees (Bachelor\'s, Honours, Masters, PhD, etc.)',
    ' Professional Cert.':
        'Professional Certifications (e.g., CIMA, ACCA, PMP, CISCO, Microsoft certifications)',
    'Academic Transcript': 'Academic Transcripts',
    'Curriculum Vitae (CV)': 'Curriculum Vitae (CV)',
    'Reference Letters': 'Reference Letters',
    'Employement Contracts': 'Employment Contracts (previous or current)',
    'Proof of Employement':
        'Proof of Employment (confirmation of service letters)',
    'Training Certificates':
        'Training Certificates (short courses, workshops, seminars)',
    'Skills Development Cert.': 'Skills Development Program Certificates',
    'Learnership / Apprenticeship':
        'Learnership/Apprenticeship Completion Certificates',
    'Membership Certificates':
        'Membership Certificates (e.g., SAICA, HPCSA, ECSA, SABPP)',
    'Registration with Professional Bodies':
        'Registration with Professional Bodies (e.g., accounting, medical, engineering, law)',
    'Security Clearance':
        'Security Clearances (if handling confidential/state finances)',
  };

  // Reverse map for matching API names (full) to short names
  Map<String, String> get fullToShort => {
    for (var e in typeDisplayMap.entries) e.value: e.key,
  };

  @override
  void initState() {
    super.initState();
    _initializeDocuments();
    _onSearchChanged(); // Initialize filtered lists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final user = authViewModel.user;
      _loadProfileImage(user?.email);

      // Load documents from API
      documentsViewModel.loadDocuments();
      documentsViewModel.addListener(_updateLists);
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    documentsViewModel = Provider.of<DocumentsViewModel>(
      context,
      listen: false,
    );
  }

  void _initializeDocuments() {
    identityComplianceDocuments =
        documentCategories['Identity & Compliance Documents']!
            .map(
              (name) => {
                'name': name,
                'type': 'Identity & Compliance Documents',
                'filePaths': <String>[],
                'fileNames': <String>[],
                'statuses': <String>[],
                'uploadDates': <String>[],
                'ids': <String>[],
              },
            )
            .toList();
    educationalDocuments =
        documentCategories['Educational Qualifications']!
            .map(
              (name) => {
                'name': name,
                'type': 'Educational Qualifications',
                'filePaths': <String>[],
                'fileNames': <String>[],
                'statuses': <String>[],
                'uploadDates': <String>[],
                'ids': <String>[],
              },
            )
            .toList();
    professionalDocuments =
        documentCategories['Professional & Employment Records']!
            .map(
              (name) => {
                'name': name,
                'type': 'Professional & Employment Records',
                'filePaths': <String>[],
                'fileNames': <String>[],
                'statuses': <String>[],
                'uploadDates': <String>[],
                'ids': <String>[],
              },
            )
            .toList();
    trainingDevelopmentDocuments =
        documentCategories['Training & Development']!
            .map(
              (name) => {
                'name': name,
                'type': 'Training & Development',
                'filePaths': <String>[],
                'fileNames': <String>[],
                'statuses': <String>[],
                'uploadDates': <String>[],
                'ids': <String>[],
              },
            )
            .toList();
    regulatoryDocuments =
        documentCategories['Regulatory & Industry-Specific Documents']!
            .map(
              (name) => {
                'name': name,
                'type': 'Regulatory & Industry-Specific Documents',
                'filePaths': <String>[],
                'fileNames': <String>[],
                'statuses': <String>[],
                'uploadDates': <String>[],
                'ids': <String>[],
              },
            )
            .toList();
    filteredIdentityComplianceDocuments = List.from(
      identityComplianceDocuments,
    );
    filteredEducationalDocuments = List.from(educationalDocuments);
    filteredProfessionalDocuments = List.from(professionalDocuments);
    filteredTrainingDevelopmentDocuments = List.from(
      trainingDevelopmentDocuments,
    );
    filteredRegulatoryDocuments = List.from(regulatoryDocuments);
  }

  String _getCategoryForType(String type) {
    for (var entry in documentCategories.entries) {
      if (entry.value.contains(type)) {
        return entry.key;
      }
    }
    return '';
  }

  List<Map<String, dynamic>> _getListForCategory(String category) {
    switch (category) {
      case 'Identity & Compliance Documents':
        return identityComplianceDocuments;
      case 'Educational Qualifications':
        return educationalDocuments;
      case 'Professional & Employment Records':
        return professionalDocuments;
      case 'Training & Development':
        return trainingDevelopmentDocuments;
      case 'Regulatory & Industry-Specific Documents':
        return regulatoryDocuments;
      default:
        return [];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _updateLists() {
    if (mounted) {
      final documentsViewModel = Provider.of<DocumentsViewModel>(
        context,
        listen: false,
      );
      // Reset local lists
      _initializeDocuments();
      // Populate from ViewModel
      for (var doc in documentsViewModel.documents) {
        String category = doc.type;
        List<Map<String, dynamic>> list = _getListForCategory(category);
        var localDoc = list.firstWhere(
          (d) => d['name'] == doc.name,
          orElse: () => <String, Object>{},
        );
        if (localDoc.isNotEmpty) {
          localDoc['filePaths'].add(doc.url);
          localDoc['statuses'].add(doc.status ?? 'N/A');
          localDoc['uploadDates'].add(_formatDate(doc.uploadedAt));
          localDoc['ids'].add(doc.id);
          if (doc.fileName != null) {
            localDoc['fileNames'].add(doc.fileName!);
          }
        }
      }
      _onSearchChanged();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    documentsViewModel.removeListener(_updateLists);
    super.dispose();
  }

  void _loadProfileImage(String? email) async {
    if (email != null) {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _profileImageBase64 = prefs.getString('profile_image_base64_$email');
        });
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      filteredIdentityComplianceDocuments =
          identityComplianceDocuments
              .where(
                (doc) =>
                    doc['name'].toLowerCase().contains(_searchQuery) ||
                    (doc['filePaths'].isNotEmpty
                        ? path
                            .basename(doc['filePaths'][0])
                            .toLowerCase()
                            .contains(_searchQuery)
                        : false),
              )
              .toList();
      filteredEducationalDocuments =
          educationalDocuments
              .where(
                (doc) =>
                    doc['name'].toLowerCase().contains(_searchQuery) ||
                    (doc['filePaths'].isNotEmpty
                        ? path
                            .basename(doc['filePaths'][0])
                            .toLowerCase()
                            .contains(_searchQuery)
                        : false),
              )
              .toList();
      filteredProfessionalDocuments =
          professionalDocuments
              .where(
                (doc) =>
                    doc['name'].toLowerCase().contains(_searchQuery) ||
                    (doc['filePaths'].isNotEmpty
                        ? path
                            .basename(doc['filePaths'][0])
                            .toLowerCase()
                            .contains(_searchQuery)
                        : false),
              )
              .toList();
      filteredTrainingDevelopmentDocuments =
          trainingDevelopmentDocuments
              .where(
                (doc) =>
                    doc['name'].toLowerCase().contains(_searchQuery) ||
                    (doc['filePaths'].isNotEmpty
                        ? path
                            .basename(doc['filePaths'][0])
                            .toLowerCase()
                            .contains(_searchQuery)
                        : false),
              )
              .toList();
      filteredRegulatoryDocuments =
          regulatoryDocuments
              .where(
                (doc) =>
                    doc['name'].toLowerCase().contains(_searchQuery) ||
                    (doc['filePaths'].isNotEmpty
                        ? path
                            .basename(doc['filePaths'][0])
                            .toLowerCase()
                            .contains(_searchQuery)
                        : false),
              )
              .toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'N/A':
        return Colors.grey;
      case 'verified':
        return Colors.green;
      case 'Awaiting Review':
        return Colors.orange;
      case 'pending':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    Color foreground = _getStatusColor(status);
    return foreground.withOpacity(0.2); // Lighter shade by reducing opacity
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthViewModel>(context, listen: true).user;
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
          'DOCUMENTS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
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
                  backgroundColor: Colors.transparent,
                  backgroundImage:
                      _profileImageBase64 != null
                          ? MemoryImage(base64Decode(_profileImageBase64!))
                          : (user?.photoBase64 != null
                              ? MemoryImage(base64Decode(user!.photoBase64!))
                              : null),
                  child:
                      (_profileImageBase64 == null && user?.photoBase64 == null)
                          ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          )
                          : null,
                ),
              ),
            ),
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
                    true,
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
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Documents',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 16),
              // My Documents Button
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _viewAllDocuments,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'My Documents',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Identity & Compliance Documents Section
              _buildSection(
                'Identity & Compliance Documents',
                filteredIdentityComplianceDocuments,
                false,
                identityComplianceDocuments,
              ),
              const SizedBox(height: 32),
              // Educational Qualifications Section
              _buildSection(
                'Educational Qualifications',
                filteredEducationalDocuments,
                false,
                educationalDocuments,
              ),
              const SizedBox(height: 32),
              // Professional & Employment Records Section
              _buildSection(
                'Professional & Employment Records',
                filteredProfessionalDocuments,
                false,
                professionalDocuments,
              ),
              const SizedBox(height: 32),
              // Training & Development Section
              _buildSection(
                'Training & Development',
                filteredTrainingDevelopmentDocuments,
                false,
                trainingDevelopmentDocuments,
              ),
              const SizedBox(height: 32),
              // Regulatory & Industry-Specific Documents Section
              _buildSection(
                'Regulatory & Industry-Specific Documents',
                filteredRegulatoryDocuments,
                false,
                regulatoryDocuments,
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
      ),
    );
  }

  void _viewDocument(Map<String, dynamic> doc) async {
    if (doc['filePaths'].isNotEmpty) {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Viewing documents is not supported on web platform.',
              ),
            ),
          );
        }
      } else {
        try {
          final result = await OpenFile.open(doc['filePaths'][0]);
          if (result.type != ResultType.done) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error opening file: ${result.message}'),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file uploaded for this document.')),
        );
      }
    }
  }

  void _uploadDocument(
    Map<String, dynamic> doc,
    List<Map<String, dynamic>> originalDocuments,
  ) async {
    List<String> allTypes =
        documentCategories.values.expand((types) => types).toList();
    String selectedFileName = 'No file chosen';
    dynamic selectedFile;
    String? selectedType = doc['name'];
    final BuildContext uploadContext = context;

    await showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => StatefulBuilder(
            builder:
                (
                  BuildContext context,
                  StateSetter setDialogState,
                ) => AlertDialog(
                  title: const Text('Upload document'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // File selection
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedFileName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.attach_file),
                                onPressed: () async {
                                  try {
                                    FilePickerResult? result =
                                        await FilePicker.platform.pickFiles();
                                    if (result != null &&
                                        result.files.isNotEmpty) {
                                      PlatformFile file = result.files.single;
                                      setDialogState(() {
                                        selectedFile = file;
                                        selectedFileName = file.name;
                                      });
                                    }
                                  } catch (e) {
                                    Navigator.of(dialogContext).pop();
                                    if (uploadContext.mounted) {
                                      ScaffoldMessenger.of(
                                        uploadContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error selecting file: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Document type dropdown
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Document type',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Select document type'),
                          items: [
                            DropdownMenuItem<String>(
                              value: doc['name'],
                              child: Text(
                                doc['name'],
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              selectedType = newValue;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          (selectedFile != null && selectedType != null)
                              ? () async {
                                try {
                                  // Upload to Firebase via ViewModel
                                  await documentsViewModel.uploadDocument(
                                    selectedType!,
                                    doc['type'],
                                    selectedFile,
                                  );

                                  Navigator.of(dialogContext).pop();
                                  if (uploadContext.mounted) {
                                    ScaffoldMessenger.of(
                                      uploadContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Document "$selectedType" uploaded successfully!',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  Navigator.of(dialogContext).pop();
                                  if (uploadContext.mounted) {
                                    ScaffoldMessenger.of(
                                      uploadContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error uploading document: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Upload document'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _deleteDocument(
    Map<String, dynamic> doc,
    List<Map<String, dynamic>> originalDocuments,
  ) async {
    final BuildContext deleteContext = context;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Document'),
            content: Text(
              'Are you sure you want to delete the uploaded file for "${doc['name']}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    // Delete from Firebase via ViewModel
                    await documentsViewModel.deleteDocument(doc['ids'][0]);

                    Navigator.of(deleteContext).pop();
                    if (deleteContext.mounted) {
                      ScaffoldMessenger.of(deleteContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Document "${doc['name']}" deleted successfully!',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.of(deleteContext).pop();
                    if (deleteContext.mounted) {
                      ScaffoldMessenger.of(deleteContext).showSnackBar(
                        SnackBar(content: Text('Error deleting document: $e')),
                      );
                    }
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _viewAllDocuments() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('My Documents'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Consumer<DocumentsViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.documents.isEmpty) {
                  return const Center(child: Text('No documents found'));
                }
                return ListView.builder(
                  itemCount: viewModel.documents.length,
                  itemBuilder: (context, index) {
                    final doc = viewModel.documents[index];
                    return ListTile(
                      title: Text(doc.name),
                      subtitle: Text(
                        'Type: ${doc.type}\nStatus: ${doc.status ?? 'N/A'}\nUploaded: ${_formatDate(doc.uploadedAt)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => _viewDocumentFromModel(doc),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _viewDocumentFromModel(dynamic doc) async {
    if (doc.url.isNotEmpty) {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Viewing documents is not supported on web platform.',
              ),
            ),
          );
        }
      } else {
        try {
          final result = await OpenFile.open(doc.url);
          if (result.type != ResultType.done) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error opening file: ${result.message}'),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file uploaded for this document.')),
        );
      }
    }
  }

  Widget _buildSection(
    String title,
    List<Map<String, dynamic>> documents,
    bool isIdentity,
    List<Map<String, dynamic>> originalDocuments,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header
                Row(
                  children: [
                    Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF0F172A),
                            width: 1,
                          ),
                          right: BorderSide(color: Color(0xFF0F172A), width: 1),
                        ),
                      ),
                      child: Text(
                        isIdentity ? 'Name' : 'Name',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF0F172A),
                            width: 1,
                          ),
                          right: BorderSide(color: Color(0xFF0F172A), width: 1),
                        ),
                      ),
                      child: const Text(
                        'File Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF0F172A),
                            width: 1,
                          ),
                          right: BorderSide(color: Color(0xFF0F172A), width: 1),
                        ),
                      ),
                      child: const Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF0F172A),
                            width: 1,
                          ),
                          right: BorderSide(color: Color(0xFF0F172A), width: 1),
                        ),
                      ),
                      child: const Text(
                        'Upload\nDate',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF0F172A),
                            width: 1,
                          ),
                          right: BorderSide(color: Color(0xFF0F172A), width: 1),
                        ),
                      ),
                      child: const Text(
                        'Uploaded',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      width: 160,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF0F172A),
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Action',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Table Rows
                ...documents.map(
                  (doc) => Row(
                    children: [
                      Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF0F172A),
                              width: 1,
                            ),
                            right: BorderSide(
                              color: Color(0xFF0F172A),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(doc['name']),
                      ),
                      Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF0F172A),
                              width: 1,
                            ),
                            right: BorderSide(
                              color: Color(0xFF0F172A),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          doc['fileNames'].isNotEmpty
                              ? doc['fileNames'][0]
                              : (doc['filePaths'].isNotEmpty
                                  ? (doc['filePaths'].length == 1
                                      ? path.basename(doc['filePaths'][0])
                                      : '${doc['filePaths'].length} files')
                                  : 'N/A'),
                        ),
                      ),
                      Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF0F172A),
                              width: 1,
                            ),
                            right: BorderSide(
                              color: Color(0xFF0F172A),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getStatusBackgroundColor(
                              doc['statuses'].isNotEmpty
                                  ? doc['statuses'][0]
                                  : 'N/A',
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            doc['statuses'].isNotEmpty
                                ? doc['statuses'][0]
                                : 'N/A',
                            style: TextStyle(
                              color: _getStatusColor(
                                doc['statuses'].isNotEmpty
                                    ? doc['statuses'][0]
                                    : 'N/A',
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF0F172A),
                              width: 1,
                            ),
                            right: BorderSide(
                              color: Color(0xFF0F172A),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          doc['uploadDates'].isNotEmpty
                              ? doc['uploadDates'][0]
                              : '',
                        ),
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF0F172A),
                              width: 1,
                            ),
                            right: BorderSide(
                              color: Color(0xFF0F172A),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(doc['filePaths'].isNotEmpty ? 'Yes' : 'No'),
                      ),
                      Container(
                        width: 160,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF0F172A),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              iconSize: 16,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              icon: const Icon(
                                Icons.visibility,
                                color: Colors.blue,
                              ),
                              onPressed: () => _viewDocument(doc),
                            ),
                            IconButton(
                              iconSize: 16,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              icon: const Icon(
                                Icons.file_upload,
                                color: Colors.green,
                              ),
                              onPressed:
                                  () => _uploadDocument(doc, originalDocuments),
                            ),

                            IconButton(
                              iconSize: 16,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              icon: Icon(
                                Icons.delete,
                                color:
                                    doc['filePaths'].isNotEmpty
                                        ? Colors.red
                                        : Colors.grey,
                              ),
                              onPressed:
                                  doc['filePaths'].isNotEmpty
                                      ? () => _deleteDocument(
                                        doc,
                                        originalDocuments,
                                      )
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (documents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No documents found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
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
              Navigator.pop(context); // Close drawer
            },
      ),
    );
  }
}
