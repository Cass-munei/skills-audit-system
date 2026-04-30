import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Document {
  final String id;
  final String name;
  final String type;
  final String url;
  final DateTime uploadedAt;
  final String? fileName;
  final String? status;

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.uploadedAt,
    this.fileName,
    this.status,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      uploadedAt: DateTime.parse(json['uploadedAt']),
      fileName: json['fileName'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'url': url,
      'uploadedAt': uploadedAt.toIso8601String(),
      'fileName': fileName,
      'status': status,
    };
  }
}

class DocumentsViewModel extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:5171';

  List<Document> _documents = [];
  List<Document> get documents => _documents;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Stream<List<Document>> get documentsStream {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(fb_auth.FirebaseAuth.instance.currentUser?.uid)
        .collection('documents')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            var data = doc.data();
            return Document(
              id: doc.id,
              name: data['name'] ?? '',
              type: data['type'] ?? '',
              url: data['url'] ?? '',
              uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              fileName: data['fileName'],
              status: data['status'],
            );
          }).toList();
        });
  }

  Future<void> loadDocuments() async {
    print('loadDocuments called'); // Debug: method called
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      print('Current user: ${user?.uid ?? 'null'}'); // Debug: user status
      if (user != null) {
        print('Flutter User ID: ${user.uid}'); // Add this line here
        // Load documents from Firestore instead of API
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('documents')
            .get();

        _documents = snapshot.docs.map((doc) {
          var data = doc.data();
          return Document(
            id: doc.id,
            name: data['name'] ?? '',
            type: data['type'] ?? '',
            url: data['url'] ?? '',
            uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            fileName: data['fileName'],
            status: data['status'],
          );
        }).toList();
        print('Loaded ${_documents.length} documents'); // Debug: success
      } else {
        print('No authenticated user found'); // Debug: no user
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Error in loadDocuments: $e'); // Debug: exception
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadDocument(String name, String type, dynamic file) async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Use the backend API to upload the document
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/users/${user.uid}/documents'));
        // Note: Authorization header removed as the API controller does not require it based on the code provided
        request.fields['name'] = name;
        request.fields['type'] = type;

        if (kIsWeb) {
          PlatformFile platformFile = file as PlatformFile;
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            platformFile.bytes!,
            filename: platformFile.name,
          ));
        } else {
          File mobileFile = file as File;
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            mobileFile.path,
            filename: mobileFile.path.split('/').last,
          ));
        }

        var response = await request.send();
        if (response.statusCode == 200) {
          // Reload documents to update the list
          await loadDocuments();
        } else {
          _errorMessage = 'Failed to upload document: ${response.reasonPhrase}';
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteDocument(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get document data to find the file URL for deletion from Storage
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('documents')
            .doc(id)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          final fileUrl = data['url'];

          // Delete from Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('documents')
              .doc(id)
              .delete();

          // Delete from Storage if URL exists
          if (fileUrl != null) {
            final storageRef = FirebaseStorage.instance.refFromURL(fileUrl);
            await storageRef.delete();
          }

          // Remove from local list
          _documents.removeWhere((d) => d.id == id);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
