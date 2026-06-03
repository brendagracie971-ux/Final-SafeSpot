import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? uid;
  Map<String, dynamic>? userData;

  bool get isLoggedIn => uid != null;

  // 🔐 INIT SESSION
  Future<void> initUser() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      user = (await FirebaseAuth.instance.signInAnonymously()).user;
    }

    uid = user!.uid;

    await loadUserData();
  }

  // 📦 LOAD FIRESTORE PROFILE
  Future<void> loadUserData() async {
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      userData = doc.data();
    }

    notifyListeners();
  }

  // 🔄 REFRESH USER
  Future<void> refresh() async {
    await loadUserData();
  }
}