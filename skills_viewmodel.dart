import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/skill_demand.dart';

class Skill {
  final String id;
  final String name;
  final String proficiency;
  final String category;

  Skill({required this.id, required this.name, required this.proficiency, required this.category});

  factory Skill.fromMap(Map<String, dynamic> data, String id) {
    return Skill(
      id: id,
      name: data['name'] ?? '',
      proficiency: data['proficiency'] ?? 'Beginner',
      category: data['category'] ?? 'ICT',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'proficiency': proficiency, 'category': category};
  }
}

class SkillsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Skill> _skills = [];
  List<Skill> get skills => _skills;

  List<SkillDemand> _skillsInDemand = [];
  List<SkillDemand> get skillsInDemand => _skillsInDemand;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<QuerySnapshot>? _skillsSubscription;

  void startListeningToSkills() {
    fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      _skillsSubscription?.cancel(); // Cancel any existing subscription
      _skillsSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('skills')
          .snapshots()
          .listen(
            (snapshot) {
              _skills = snapshot.docs
                  .map(
                    (doc) => Skill.fromMap(doc.data() as Map<String, dynamic>, doc.id),
                  )
                  .toList();
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = error.toString();
              notifyListeners();
            },
          );
    }
  }

  void stopListeningToSkills() {
    _skillsSubscription?.cancel();
    _skillsSubscription = null;
  }

  Future<void> loadSkills() async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot snapshot =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('skills')
                .get();
        _skills =
            snapshot.docs
                .map(
                  (doc) =>
                      Skill.fromMap(doc.data() as Map<String, dynamic>, doc.id),
                )
                .toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSkillsInDemand(String department) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('skillsDemand')
          .where('department', isEqualTo: department)
          .get();
      _skillsInDemand = snapshot.docs
          .map((doc) => SkillDemand.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      // Do not fall back to mock data if empty; show empty list as in MVC
    } catch (e) {
      _errorMessage = e.toString();
      // Fall back to mock data on error
      _skillsInDemand = getMockSkillsInDemand(department);
    }

    _isLoading = false;
    notifyListeners();
  }

  List<SkillDemand> getMockSkillsInDemand(String department) {
    return [
      SkillDemand(
        id: 'mock1',
        name: 'Sample Skill 1',
        department: department,
        demandLevel: 0.25, // 1 - 0.75
        requiredLevel: 'Intermediate',
        gapPercentage: 0.75, // (20 - 5) / 20 = 0.75
        employeesMatching: 5,
        totalEmployees: 20,
        description: 'Mock description 1',
      ),
      SkillDemand(
        id: 'mock2',
        name: 'Sample Skill 2',
        department: department,
        demandLevel: 0.7, // 1 - 0.3
        requiredLevel: 'Advanced',
        gapPercentage: 0.3, // (20 - 14) / 20 = 0.3
        employeesMatching: 14,
        totalEmployees: 20,
        description: 'Mock description 2',
      ),
    ];
  }



  List<Skill> getSkillsByCategory(String category) {
    return _skills.where((skill) => skill.category == category).toList();
  }

  Future<void> addSkill(String name, String proficiency, String category) async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('skills')
            .add({
              'name': name,
              'proficiency': proficiency,
              'category': category,
              'createdAt': FieldValue.serverTimestamp(),
            });
        // No need to manually add to _skills as the listener will handle it
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSkill(String id, String name, String proficiency, String category) async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('skills')
            .doc(id)
            .update({'name': name, 'proficiency': proficiency, 'category': category});
        // No need to manually update _skills as the listener will handle it
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteSkill(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('skills')
            .doc(id)
            .delete();
        // No need to manually remove from _skills as the listener will handle it
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListeningToSkills();
    super.dispose();
  }
}
