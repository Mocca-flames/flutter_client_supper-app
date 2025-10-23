import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:molo/models/user_model.dart'; // Assuming UserModel will be used to wrap Firebase User

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentGoogleUser;

  FirebaseAuthService() {
    _googleSignIn.initialize();
  }

  // Wraps Firebase User into UserModel
  UserModel? _userFromFirebaseUser(User? user) {
    if (user == null) {
      return null;
    }
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
    );
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebaseUser(userCredential.user);
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors (e.g., user-not-found, wrong-password)
      var logger = Logger();
      logger.e('FirebaseAuthException on sign in: ${e.message}');
      rethrow; // Re-throw to be handled by the caller (e.g., AuthProvider)
    } catch (e) {
      var logger = Logger();
      logger.e('Error signing in: $e');
      rethrow; // Re-throw for generic error handling
    }
  }

  // Create user with email and password
  Future<UserModel?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebaseUser(userCredential.user);
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors (e.g., email-already-in-use, weak-password)
      var logger = Logger();
      logger.e('FirebaseAuthException on create user: ${e.message}');
      rethrow;
    } catch (e) {
      var logger = Logger();
      logger.e('Error creating user: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser != null) {
        _currentGoogleUser = googleUser;
      }
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.idToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      return _userFromFirebaseUser(userCredential.user);
    } on FirebaseAuthException catch (e) {
      var logger = Logger();
      logger.e('FirebaseAuthException on Google sign in: ${e.message}');
      rethrow;
    } catch (e) {
      var logger = Logger();
      logger.e('Error signing in with Google: $e');
      // If sign-in was attempted but failed, ensure Google Sign-In is signed out
      if (_currentGoogleUser != null) {
        await _googleSignIn.signOut();
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      // Also sign out from Google if the user signed in with Google
      if (_currentGoogleUser != null) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      var logger = Logger();
      logger.e('Error signing out: $e');
      rethrow;
    }
  }

  // Get current user
  UserModel? getCurrentUser() {
    return _userFromFirebaseUser(_firebaseAuth.currentUser);
  }

  // Get ID token for the current user
  Future<String?> getIdToken() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user != null) {
        return await user.getIdToken(true); // Pass true to force refresh the token
      }
      return null;
    } catch (e) {
      var logger = Logger();
      logger.e('Error getting ID token: $e');
      rethrow;
    }
  }

  // Stream of authentication state changes
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_userFromFirebaseUser);
  }
}
