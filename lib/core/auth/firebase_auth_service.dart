import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user_model.dart';

/// Service for handling Firebase Authentication with Google Sign-In
/// Supports both Android (native Google Sign-In) and Windows (OAuth flow)
class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _googleSignIn =
           googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']),
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of authentication state changes
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  /// Get current Firebase user
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Sign in with Google
  /// Returns the Firebase User if successful, null otherwise
  Future<firebase_auth.User?> signInWithGoogle() async {
    try {
      firebase_auth.UserCredential userCredential;

      if (Platform.isWindows) {
        // Windows: Use OAuth flow with browser
        userCredential = await _signInWithGoogleWindows();
      } else {
        // Android/iOS: Use native Google Sign-In
        userCredential = await _signInWithGoogleNative();
      }

      return userCredential.user;
    } catch (e) {
      dev.log('Error signing in with Google: $e', name: 'FirebaseAuthService');
      rethrow;
    }
  }

  /// Native Google Sign-In for Android/iOS
  Future<firebase_auth.UserCredential> _signInWithGoogleNative() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled');
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    return await _firebaseAuth.signInWithCredential(credential);
  }

  /// Google Sign-In for Windows using OAuth flow
  Future<firebase_auth.UserCredential> _signInWithGoogleWindows() async {
    // Create a provider for Google
    final googleProvider = firebase_auth.GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    // Use popup sign-in for desktop
    return await _firebaseAuth.signInWithPopup(googleProvider);
  }

  /// Sign out from Firebase and Google
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      dev.log('Error signing out: $e', name: 'FirebaseAuthService');
      rethrow;
    }
  }

  /// Get or create user profile in Firestore
  /// If user doesn't exist, creates a new profile
  Future<User?> getOrCreateUserProfile({
    required firebase_auth.User firebaseUser,
    UserRole? role,
  }) async {
    try {
      final docRef = _firestore.collection('users').doc(firebaseUser.uid);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // User exists, return the profile
        return User.fromFirestore(docSnapshot);
      } else if (role != null) {
        // New user, create profile with selected role
        final newUser = User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? 'User',
          dateOfBirth: DateTime(2000, 1, 1), // Default, user can update later
          role: role,
          photoUrl: firebaseUser.photoURL,
        );

        await docRef.set(newUser.toFirestore());
        return newUser;
      }

      // User doesn't exist and no role provided
      return null;
    } catch (e) {
      dev.log(
        'Error getting/creating user profile: $e',
        name: 'FirebaseAuthService',
      );
      rethrow;
    }
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile(User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(user.toFirestore());
    } catch (e) {
      dev.log('Error updating user profile: $e', name: 'FirebaseAuthService');
      rethrow;
    }
  }

  /// Get user profile from Firestore by UID
  Future<User?> getUserProfile(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        return User.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      dev.log('Error getting user profile: $e', name: 'FirebaseAuthService');
      rethrow;
    }
  }

  /// Migrate local user to Firestore
  /// Used when transitioning from local SQLite storage to Firebase
  Future<void> migrateLocalUser({
    required String uid,
    required String identifier,
    required String name,
    required DateTime dateOfBirth,
    required UserRole role,
    String? apiKey,
    String? selectedModel,
  }) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        final migratedUser = User(
          uid: uid,
          email: _firebaseAuth.currentUser?.email ?? '',
          identifier: identifier,
          name: name,
          dateOfBirth: dateOfBirth,
          role: role,
          apiKey: apiKey,
          selectedModel: selectedModel,
          photoUrl: _firebaseAuth.currentUser?.photoURL,
        );

        await docRef.set(migratedUser.toFirestore());
        dev.log(
          'User migrated successfully: $uid',
          name: 'FirebaseAuthService',
        );
      }
    } catch (e) {
      dev.log('Error migrating user: $e', name: 'FirebaseAuthService');
      rethrow;
    }
  }
}
