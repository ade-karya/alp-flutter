import 'dart:async';
import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'firebase_auth_service.dart';
import 'models/user_model.dart';

// Auth States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Unauthenticated extends AuthState {
  final bool hasUsers;
  Unauthenticated({this.hasUsers = false});
}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}

/// State when user is signed in with Google but hasn't selected a role yet
class RoleSelectionRequired extends AuthState {
  final firebase_auth.User firebaseUser;
  RoleSelectionRequired(this.firebaseUser);
}

class OnboardingRequired extends AuthState {
  final bool hasUsers;
  OnboardingRequired({this.hasUsers = false});
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class RegistrationSuccess extends AuthState {
  final String identifier;
  RegistrationSuccess(this.identifier);
}

// Auth Cubit
class AuthCubit extends Cubit<AuthState> {
  final DatabaseHelper _dbHelper;
  final FirebaseAuthService _firebaseAuthService;

  static const String _onboardingCompletedKey = 'onboarding_completed';

  StreamSubscription<firebase_auth.User?>? _authStateSubscription;

  AuthCubit(this._dbHelper, this._firebaseAuthService) : super(AuthInitial()) {
    _init();
  }

  Future<void> _init() async {
    // Listen to Firebase auth state changes
    _authStateSubscription = _firebaseAuthService.authStateChanges.listen(
      _onAuthStateChanged,
    );

    // Initial auth check
    await _checkAuthStatus();
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }

  void _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      // User signed out
      final hasUsers = await _dbHelper.hasAnyUser();
      emit(Unauthenticated(hasUsers: hasUsers));
    } else {
      // User signed in, check if profile exists
      final userProfile = await _firebaseAuthService.getUserProfile(
        firebaseUser.uid,
      );
      if (userProfile != null) {
        emit(Authenticated(userProfile));
      } else {
        // New user, need to select role
        emit(RoleSelectionRequired(firebaseUser));
      }
    }
  }

  Future<void> _checkAuthStatus() async {
    emit(AuthLoading());
    dev.log('Starting auth status check...', name: 'AuthCubit');

    // START PARALLEL TASKS
    // 1. Minimum Splash Duration (1.5s for snappiness)
    final minSplashTask = Future.delayed(const Duration(milliseconds: 1500));

    // 2. Data Loading (SharedPreferences)
    final prefsTask = SharedPreferences.getInstance();

    // 3. Data Loading (Database Check)
    final hasUsersTask = _dbHelper.hasAnyUser();

    try {
      // WAIT FOR ALL TASKS TO COMPLETE
      final results = await Future.wait([
        minSplashTask,
        prefsTask,
        hasUsersTask,
      ]);

      final prefs = results[1] as SharedPreferences;
      final hasUsers = results[2] as bool;
      dev.log(
        'SharedPreferences loaded, hasUsers: $hasUsers',
        name: 'AuthCubit',
      );

      // Check onboarding status first
      final onboardingCompleted =
          prefs.getBool(_onboardingCompletedKey) ?? false;
      dev.log('Onboarding completed: $onboardingCompleted', name: 'AuthCubit');

      if (!onboardingCompleted) {
        emit(OnboardingRequired(hasUsers: hasUsers));
        return;
      }

      // Check Firebase auth status
      final firebaseUser = _firebaseAuthService.currentUser;
      dev.log(
        'Firebase user: ${firebaseUser?.email ?? "null"}',
        name: 'AuthCubit',
      );

      if (firebaseUser != null) {
        // User is signed in with Firebase - add timeout
        try {
          final userProfile = await _firebaseAuthService
              .getUserProfile(firebaseUser.uid)
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  dev.log(
                    'Firestore timeout, falling back to unauthenticated',
                    name: 'AuthCubit',
                  );
                  return null;
                },
              );

          if (userProfile != null) {
            dev.log(
              'User profile found: ${userProfile.name}',
              name: 'AuthCubit',
            );
            emit(Authenticated(userProfile));
          } else {
            // User is signed in but hasn't completed profile
            dev.log('No profile, needs role selection', name: 'AuthCubit');
            emit(RoleSelectionRequired(firebaseUser));
          }
        } catch (e) {
          dev.log('Error getting user profile: $e', name: 'AuthCubit');
          // Firestore error, emit unauthenticated to allow offline usage
          emit(Unauthenticated(hasUsers: hasUsers));
        }
      } else {
        dev.log(
          'No firebase user, emitting Unauthenticated',
          name: 'AuthCubit',
        );
        emit(Unauthenticated(hasUsers: hasUsers));
      }
    } catch (e) {
      dev.log('Error checking auth status: $e', name: 'AuthCubit');
      emit(AuthError('Failed to check authentication status: $e'));
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
    } catch (e) {
      emit(AuthError('Failed to complete onboarding: $e'));
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final firebaseUser = await _firebaseAuthService.signInWithGoogle();
      if (firebaseUser == null) {
        emit(Unauthenticated());
        return;
      }

      // Check if user profile exists
      final userProfile = await _firebaseAuthService.getUserProfile(
        firebaseUser.uid,
      );
      if (userProfile != null) {
        emit(Authenticated(userProfile));
      } else {
        // New user, need to select role
        emit(RoleSelectionRequired(firebaseUser));
      }
    } catch (e) {
      dev.log('Error signing in with Google: $e', name: 'AuthCubit');
      emit(AuthError('Sign in failed: ${e.toString()}'));
    }
  }

  /// Complete profile setup after Google Sign-In by selecting role
  Future<void> completeProfile({
    required firebase_auth.User firebaseUser,
    required UserRole role,
    String? identifier,
    DateTime? dateOfBirth,
  }) async {
    emit(AuthLoading());
    try {
      final userProfile = await _firebaseAuthService.getOrCreateUserProfile(
        firebaseUser: firebaseUser,
        role: role,
      );

      if (userProfile != null) {
        // Update with additional info if provided
        if (identifier != null || dateOfBirth != null) {
          final updatedUser = userProfile.copyWith(
            identifier: identifier,
            dateOfBirth: dateOfBirth,
          );
          await _firebaseAuthService.updateUserProfile(updatedUser);
          emit(Authenticated(updatedUser));
        } else {
          emit(Authenticated(userProfile));
        }
      } else {
        emit(AuthError('Failed to create user profile'));
      }
    } catch (e) {
      dev.log('Error completing profile: $e', name: 'AuthCubit');
      emit(AuthError('Failed to complete profile: $e'));
    }
  }

  /// Migrate local user data to Firestore
  Future<void> migrateLocalUsers() async {
    try {
      final firebaseUser = _firebaseAuthService.currentUser;
      if (firebaseUser == null) return;

      // Get all local users
      final localUsers = await _dbHelper.getAllUsers();

      for (final localUser in localUsers) {
        // Check if email matches (if available) or migrate all to current Firebase user
        await _firebaseAuthService.migrateLocalUser(
          uid: firebaseUser.uid,
          identifier: localUser.identifier ?? '',
          name: localUser.name,
          dateOfBirth: localUser.dateOfBirth,
          role: localUser.role,
          apiKey: localUser.apiKey,
          selectedModel: localUser.selectedModel,
        );
      }

      dev.log('Migrated ${localUsers.length} local users', name: 'AuthCubit');
    } catch (e) {
      dev.log('Error migrating local users: $e', name: 'AuthCubit');
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuthService.signOut();
      final hasUsers = await _dbHelper.hasAnyUser();
      emit(Unauthenticated(hasUsers: hasUsers));
    } catch (e) {
      emit(AuthError('Logout failed: $e'));
    }
  }

  Future<void> refreshCurrentUser() async {
    if (state is Authenticated) {
      final currentUser = (state as Authenticated).user;
      if (currentUser.uid != null) {
        final updatedUser = await _firebaseAuthService.getUserProfile(
          currentUser.uid!,
        );
        if (updatedUser != null) {
          emit(Authenticated(updatedUser));
        }
      }
    }
  }

  Future<void> reloadAuthStatus() async {
    await _checkAuthStatus();
  }

  /// Update user profile (e.g., API key, selected model)
  Future<void> updateUserProfile(User updatedUser) async {
    try {
      await _firebaseAuthService.updateUserProfile(updatedUser);
      emit(Authenticated(updatedUser));
    } catch (e) {
      dev.log('Error updating user profile: $e', name: 'AuthCubit');
      emit(AuthError('Failed to update profile: $e'));
    }
  }

  // ============================================
  // LEGACY METHODS - Kept for backward compatibility
  // These will use local SQLite database
  // ============================================

  Future<void> login(String identifier, String pin) async {
    emit(AuthLoading());
    try {
      final cleanIdentifier = identifier.replaceAll(RegExp(r'[^0-9]'), '');
      var user = await _dbHelper.getUserByIdentifier(cleanIdentifier);

      // Auto-Repair: User might be saved with invisible characters (legacy)
      if (user == null) {
        final allUsers = await _dbHelper.getAllUsers();
        try {
          final dirtyUser = allUsers.firstWhere(
            (u) =>
                (u.identifier ?? '').replaceAll(RegExp(r'[^0-9]'), '') ==
                cleanIdentifier,
          );
          user = dirtyUser.copyWith(identifier: cleanIdentifier);
          await _dbHelper.updateUser(user);
        } catch (_) {
          // Truly not found
        }
      }

      if (user == null) {
        emit(AuthError('User not found: $cleanIdentifier'));
        return;
      }

      if (user.pin != pin) {
        emit(AuthError('Invalid PIN'));
        return;
      }

      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Login failed: $e'));
    }
  }

  Future<void> register({
    required String identifier,
    required String name,
    required DateTime dateOfBirth,
    required UserRole role,
    required String pin,
  }) async {
    dev.log('register() called', name: 'AuthCubit');
    emit(AuthLoading());
    try {
      final cleanIdentifier = identifier.replaceAll(RegExp(r'[^0-9]'), '');

      final existingUser = await _dbHelper.getUserByIdentifier(cleanIdentifier);
      if (existingUser != null) {
        emit(
          AuthError(
            'User with this ${role == UserRole.student ? 'NISN' : 'NUPTK'} already exists',
          ),
        );
        return;
      }

      final newUser = User(
        identifier: cleanIdentifier,
        name: name,
        dateOfBirth: dateOfBirth,
        role: role,
        pin: pin,
      );

      final userId = await _dbHelper.createUser(newUser);
      final createdUser = newUser.copyWith(id: userId);
      emit(Authenticated(createdUser));
    } catch (e) {
      dev.log('Registration error: $e', name: 'AuthCubit', error: e);
      emit(AuthError('Registration failed: $e'));
    }
  }

  Future<void> selectUser(int userId) async {
    emit(AuthLoading());
    try {
      final user = await _dbHelper.getUserById(userId);
      if (user == null) {
        emit(AuthError('User not found'));
        return;
      }
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Failed to select user: $e'));
    }
  }

  Future<bool> updatePin(String currentPin, String newPin) async {
    if (state is! Authenticated) return false;

    final user = (state as Authenticated).user;

    if (user.pin != currentPin) {
      return false;
    }

    final updatedUser = user.copyWith(pin: newPin);
    await _dbHelper.updateUser(updatedUser);
    emit(Authenticated(updatedUser));
    return true;
  }

  Future<void> deleteUser(int userId) async {
    emit(AuthLoading());
    try {
      await _dbHelper.deleteUser(userId);
      final hasUsers = await _dbHelper.hasAnyUser();
      emit(Unauthenticated(hasUsers: hasUsers));
    } catch (e) {
      emit(AuthError('Failed to delete user: $e'));
      final hasUsers = await _dbHelper.hasAnyUser();
      emit(Unauthenticated(hasUsers: hasUsers));
    }
  }
}
