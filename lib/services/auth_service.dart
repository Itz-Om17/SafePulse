import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign up with role
  Future<User?> signUp(String email, String password, String role, {required Map<String, String> extraData}) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save role in Firestore
      await _db.collection("users").doc(result.user!.uid).set({
        "email": email,
        "role": role,
        "createdAt": DateTime.now(),
      });

      return result.user;
    } catch (e) {
      print("Signup Error: $e");
      return null;
    }
  }

  // Login
  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // Get role
  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    return doc.data()?["role"];
  }

  // Logout
  Future<void> logout() async => _auth.signOut();

  User? get currentUser => _auth.currentUser;
}
