import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Automatically sign in anonymously if not signed in
  Future<User> getOrCreateUser() async {
    User? user = _auth.currentUser;
    if (user == null) {
      final cred = await _auth.signInAnonymously();
      user = cred.user;
    }
    return user!;
  }

  String? get userId => _auth.currentUser?.uid;
}
