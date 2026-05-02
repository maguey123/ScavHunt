import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<User> getOrCreateUser() async {
    var user = _auth.currentUser;
    if (user == null) {
      final cred = await _auth.signInAnonymously();
      user = cred.user!;
    }
    return user;
  }
}
