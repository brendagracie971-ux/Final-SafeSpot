import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔐 Ensure anonymous session exists
  Future<User> ensureUser() async {
    if (_auth.currentUser != null) {
      return _auth.currentUser!;
    }

    final result = await _auth.signInAnonymously();
    return result.user!;
  }

  // 👤 Get current user
  User? get currentUser => _auth.currentUser;

  // 🚪 Logout (optional future use)
  Future<void> logout() async {
    await _auth.signOut();
  }
}