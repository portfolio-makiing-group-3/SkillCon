import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // <-- Firestore instance

  /// Register a new user with email and password
  Future<void> registerUser(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      Fluttertoast.showToast(msg: "Account created successfully");
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  /// Register user with extra info (name, phone, dob)
  Future<void> registerUserWithDetails({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String dob,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save additional user info to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'phone': phone,
        'dob': dob,
        'email': email,
      });

      Fluttertoast.showToast(msg: "Account created successfully");
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      rethrow;
    }
  }

  /// Sign up (alias for registerUser)
  Future<void> signUp(String email, String password) async {
    await registerUser(email, password);
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Fluttertoast.showToast(msg: "Login successful");
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  /// Send password reset link to email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(msg: "Password reset link sent to $email");
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  /// Sign out from all sessions
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Sign in using Google account
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in aborted');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      Fluttertoast.showToast(msg: "Google sign-in successful");
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      rethrow;
    }
  }
}
