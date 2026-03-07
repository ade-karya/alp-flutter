import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'models/user_model.dart';

/// OAuth Client ID for desktop platforms (Windows/Linux/macOS)
///
/// IMPORTANT: This must be the Web client ID that Firebase created,
/// found in google-services.json under "other_platform_oauth_client"
///
/// To get the client secret:
/// 1. Go to Google Cloud Console: https://console.cloud.google.com/apis/credentials
/// 2. Select project riau-education
/// 3. Find the Web client: 83128997767-2k4m9rrofgt8a9d712m4vt0p0lg511i3
/// 4. Click on it and copy the Client Secret
const String _desktopClientId =
    '83128997767-2k4m9rrofgt8a9d712m4vt0p0lg511i3.apps.googleusercontent.com';

/// Client secret loaded from compile-time environment variable.
/// Run with: flutter run --dart-define=GOOGLE_CLIENT_SECRET=your_secret_here
const String _desktopClientSecret = String.fromEnvironment(
  'GOOGLE_CLIENT_SECRET',
  defaultValue: '',
);

/// Check if running on desktop platform (Windows, Linux, macOS)
bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

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

      if (_isDesktop) {
        // Desktop (Windows/Linux/macOS): Use OAuth flow with browser
        userCredential = await _signInWithGoogleDesktop();
      } else {
        // Android/iOS/Web: Use native Google Sign-In
        userCredential = await _signInWithGoogleNative();
      }

      return userCredential.user;
    } catch (e) {
      dev.log('Error signing in with Google: $e', name: 'FirebaseAuthService');
      rethrow;
    }
  }

  /// Native Google Sign-In for Android/iOS/Web
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

  /// Google Sign-In for Desktop using manual OAuth 2.0 flow
  ///
  /// This is the most popular and reliable approach for Windows:
  /// 1. Start local HTTP server to receive OAuth callback
  /// 2. Open system browser to Google OAuth consent page
  /// 3. User signs in and grants permissions
  /// 4. Google redirects to localhost with authorization code
  /// 5. Exchange authorization code for tokens
  /// 6. Create Firebase credential and sign in
  Future<firebase_auth.UserCredential> _signInWithGoogleDesktop() async {
    dev.log(
      '=== Starting Desktop Google Sign-In (Manual OAuth) ===',
      name: 'FirebaseAuthService',
    );

    HttpServer? server;

    try {
      // Validate client secret is provided via --dart-define
      if (_desktopClientSecret.isEmpty) {
        throw Exception(
          'GOOGLE_CLIENT_SECRET not provided. '
          'Run with: flutter run --dart-define=GOOGLE_CLIENT_SECRET=your_secret',
        );
      }

      // Step 1: Start local HTTP server to receive the OAuth callback
      const int port = 8080; // Use 8080 as it's commonly whitelisted
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      dev.log(
        'Local server started on port $port',
        name: 'FirebaseAuthService',
      );

      // Step 2: Build Google OAuth URL
      const redirectUri = 'http://localhost:$port';
      final state = DateTime.now().millisecondsSinceEpoch.toString();

      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': _desktopClientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'email profile openid',
        'state': state,
        'access_type': 'offline',
        'prompt': 'select_account',
      });

      dev.log('Opening browser for OAuth...', name: 'FirebaseAuthService');

      // Step 3: Open browser for user to sign in
      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open browser for Google Sign-In');
      }

      dev.log(
        'Waiting for user to complete sign-in...',
        name: 'FirebaseAuthService',
      );

      // Step 4: Wait for the OAuth callback with timeout
      String? authCode;
      await server
          .timeout(const Duration(minutes: 2))
          .forEach((request) async {
            final uri = request.uri;

            // Check for error response
            if (uri.queryParameters.containsKey('error')) {
              final error = uri.queryParameters['error'];
              request.response
                ..statusCode = HttpStatus.ok
                ..headers.contentType = ContentType.html
                ..write(_buildHtmlResponse('Sign-in Failed', 'Error: $error'))
                ..close();
              throw Exception('OAuth error: $error');
            }

            // Check for authorization code
            if (uri.queryParameters.containsKey('code')) {
              authCode = uri.queryParameters['code'];

              // Send success response to browser
              request.response
                ..statusCode = HttpStatus.ok
                ..headers.contentType = ContentType.html
                ..write(
                  _buildHtmlResponse(
                    'Sign-in Successful!',
                    'You can close this window and return to the app.',
                  ),
                )
                ..close();

              // Stop listening after receiving code
              server?.close();
            }
          })
          .catchError((e) {
            if (e is TimeoutException) {
              throw Exception('Sign-in timed out. Please try again.');
            }
            throw e;
          });

      if (authCode == null) {
        throw Exception('Failed to receive authorization code');
      }

      dev.log('✓ Received authorization code', name: 'FirebaseAuthService');

      // Step 5: Exchange authorization code for tokens (with retry)
      dev.log('Exchanging code for tokens...', name: 'FirebaseAuthService');

      http.Response? tokenResponse;
      Exception? lastError;

      // Retry up to 3 times for network issues
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          dev.log(
            'Token exchange attempt $attempt/3',
            name: 'FirebaseAuthService',
          );

          tokenResponse = await http
              .post(
                Uri.parse('https://oauth2.googleapis.com/token'),
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: {
                  'client_id': _desktopClientId,
                  'client_secret': _desktopClientSecret,
                  'code': authCode,
                  'grant_type': 'authorization_code',
                  'redirect_uri': 'http://localhost:$port',
                },
              )
              .timeout(const Duration(seconds: 30));

          // Success - break out of retry loop
          break;
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          dev.log('Attempt $attempt failed: $e', name: 'FirebaseAuthService');

          if (attempt < 3) {
            // Wait before retry
            await Future.delayed(Duration(seconds: attempt));
          }
        }
      }

      if (tokenResponse == null) {
        throw lastError ??
            Exception('Failed to exchange tokens after 3 attempts');
      }

      if (tokenResponse.statusCode != 200) {
        dev.log(
          'Token exchange failed: ${tokenResponse.body}',
          name: 'FirebaseAuthService',
        );
        throw Exception('Failed to exchange authorization code for tokens');
      }

      final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessToken = tokenData['access_token'] as String?;
      final idToken = tokenData['id_token'] as String?;

      if (accessToken == null) {
        throw Exception('No access token received');
      }

      dev.log('✓ Tokens received successfully', name: 'FirebaseAuthService');
      dev.log(
        '  Access Token: ${accessToken.length} chars',
        name: 'FirebaseAuthService',
      );
      dev.log(
        '  ID Token: ${idToken != null ? "present" : "not provided"}',
        name: 'FirebaseAuthService',
      );

      // Step 6: Create Firebase credential and sign in
      dev.log('Authenticating with Firebase...', name: 'FirebaseAuthService');

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      dev.log(
        '✓ Firebase sign-in successful! User: ${userCredential.user?.email}',
        name: 'FirebaseAuthService',
      );

      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      dev.log(
        '✗ Firebase Auth error: ${e.code} - ${e.message}',
        name: 'FirebaseAuthService',
      );
      rethrow;
    } catch (e) {
      dev.log('✗ Sign-in error: $e', name: 'FirebaseAuthService');
      rethrow;
    } finally {
      // Always close the server
      await server?.close();
    }
  }

  /// Build HTML response for OAuth callback
  String _buildHtmlResponse(String title, String message) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <title>$title</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    .card {
      background: white;
      padding: 40px 60px;
      border-radius: 16px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.2);
      text-align: center;
    }
    h1 { color: #333; margin-bottom: 10px; }
    p { color: #666; }
  </style>
</head>
<body>
  <div class="card">
    <h1>$title</h1>
    <p>$message</p>
  </div>
</body>
</html>
''';
  }

  /// Sign out from Firebase and Google
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      if (!_isDesktop) {
        await _googleSignIn.signOut();
      }
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
