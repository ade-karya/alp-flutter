import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
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
  static const String _currentUserIdKey = 'current_user_id';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  AuthCubit(this._dbHelper) : super(AuthInitial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    emit(AuthLoading());

    // START PARALLEL TASKS
    // 1. Minimum Splash Duration (1.5s for snappiness)
    final minSplashTask = Future.delayed(const Duration(milliseconds: 1500));

    // 2. Data Loading (SharedPreferences)
    final prefsTask = SharedPreferences.getInstance();

    // 3. Data Loading (Database Check - dependent on DB helper which is sync, but we check users async)
    final hasUsersTask = _dbHelper.hasAnyUser();

    try {
      // WAIT FOR ALL TASKS TO COMPLETE
      // This runs them in parallel. We wait for the longest one (likely the 1.5s timer).
      final results = await Future.wait([
        minSplashTask,
        prefsTask,
        hasUsersTask,
      ]);

      // Extract results
      final prefs = results[1] as SharedPreferences;
      final hasUsers = results[2] as bool;

      // Check onboarding status first
      final onboardingCompleted =
          prefs.getBool(_onboardingCompletedKey) ?? false;
      if (!onboardingCompleted) {
        emit(OnboardingRequired(hasUsers: hasUsers));
        return;
      }

      // 4. CHECK USER EXISTENCE (Enforce User Selection on Startup)
      // We explicitly DO NOT check for a stored current_user_id here.
      // This ensures that on every cold start, the user is presented with the
      // User Selection screen (if users exist) to re-authenticate (PIN),
      // fulfilling the requirement: "Show list of users if data exists".

      /* AUTO-LOGIN DISABLED
      final userId = prefs.getInt(_currentUserIdKey);

      if (userId != null) {
        final user = await _dbHelper.getUserById(userId);
        if (user != null) {
          emit(Authenticated(user));
          return;
        }
      }
      */

      emit(Unauthenticated(hasUsers: hasUsers));
    } catch (e) {
      emit(AuthError('Failed to check authentication status: $e'));
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      // Don't call _checkAuthStatus() here - let the caller handle navigation
      // This prevents the router from immediately redirecting before navigation
    } catch (e) {
      emit(AuthError('Failed to complete onboarding: $e'));
    }
  }

  Future<void> login(String identifier, String pin) async {
    emit(AuthLoading());
    try {
      // Strict sanitization: remove any non-digit characters
      final cleanIdentifier = identifier.replaceAll(RegExp(r'[^0-9]'), '');

      // Try strict lookup first
      var user = await _dbHelper.getUserByIdentifier(cleanIdentifier);

      // Auto-Repair: User might be saved with invisible characters (legacy)
      if (user == null) {
        final allUsers = await _dbHelper.getAllUsers();
        try {
          // Scan for any user whose "cleaned" identifier matches our input
          final dirtyUser = allUsers.firstWhere(
            (u) =>
                u.identifier.replaceAll(RegExp(r'[^0-9]'), '') ==
                cleanIdentifier,
          );

          // Found it! Clean the database record immediately
          user = dirtyUser.copyWith(identifier: cleanIdentifier);
          await _dbHelper.updateUser(user);
          // Successfully repaired and retrieved the user
        } catch (_) {
          // Truly not found
        }
      }

      if (user == null) {
        emit(AuthError('User not found: $cleanIdentifier')); // Debug info
        return;
      }

      if (user.pin != pin) {
        emit(AuthError('Invalid PIN'));
        return;
      }

      await _setCurrentUser(user.id!);
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
      // Strict sanitization
      final cleanIdentifier = identifier.replaceAll(RegExp(r'[^0-9]'), '');
      dev.log('cleanIdentifier: $cleanIdentifier', name: 'AuthCubit');

      // Check if user already exists
      final existingUser = await _dbHelper.getUserByIdentifier(cleanIdentifier);
      if (existingUser != null) {
        dev.log('User already exists', name: 'AuthCubit');
        emit(
          AuthError(
            'User with this ${role == UserRole.student ? 'NISN' : 'NUPTK'} already exists',
          ),
        );
        return;
      }

      // Create new user with PIN
      final newUser = User(
        identifier: cleanIdentifier,
        name: name,
        dateOfBirth: dateOfBirth,
        role: role,
        pin: pin,
      );

      dev.log('Creating user in database...', name: 'AuthCubit');
      final userId = await _dbHelper.createUser(newUser);
      dev.log('User created with ID: $userId', name: 'AuthCubit');
      final createdUser = newUser.copyWith(id: userId);

      // Auto-login after registration - user goes directly to dashboard
      dev.log('Setting current user...', name: 'AuthCubit');
      await _setCurrentUser(createdUser.id!);
      dev.log('Emitting Authenticated state', name: 'AuthCubit');
      emit(Authenticated(createdUser));
      dev.log('Authenticated state emitted', name: 'AuthCubit');
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

      await _setCurrentUser(userId);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Failed to select user: $e'));
    }
  }

  Future<bool> updatePin(String currentPin, String newPin) async {
    if (state is! Authenticated) return false;

    final user = (state as Authenticated).user;

    // Verify current PIN
    if (user.pin != currentPin) {
      return false;
    }

    // Update PIN
    final updatedUser = user.copyWith(pin: newPin);
    await _dbHelper.updateUser(updatedUser);
    emit(Authenticated(updatedUser));
    return true;
  }

  Future<void> deleteUser(int userId) async {
    emit(AuthLoading());
    try {
      await _dbHelper.deleteUser(userId);
      // Determine if any users remain
      final hasUsers = await _dbHelper.hasAnyUser();
      emit(Unauthenticated(hasUsers: hasUsers));
    } catch (e) {
      emit(AuthError('Failed to delete user: $e'));
      // Fallback to unauthenticated mostly likely
      final hasUsers = await _dbHelper.hasAnyUser();
      emit(Unauthenticated(hasUsers: hasUsers));
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserIdKey);

      final hasUsers = await _dbHelper.hasAnyUser();
      emit(Unauthenticated(hasUsers: hasUsers));
    } catch (e) {
      emit(AuthError('Logout failed: $e'));
    }
  }

  Future<void> _setCurrentUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentUserIdKey, userId);
  }

  Future<void> refreshCurrentUser() async {
    if (state is Authenticated) {
      final currentUser = (state as Authenticated).user;
      final updatedUser = await _dbHelper.getUserById(currentUser.id!);
      if (updatedUser != null) {
        emit(Authenticated(updatedUser));
      }
    }
  }

  Future<void> reloadAuthStatus() async {
    // Quick check to reset state after registration or other events
    try {
      final hasUsers = await _dbHelper.hasAnyUser();
      emit(Unauthenticated(hasUsers: hasUsers));
    } catch (e) {
      emit(AuthError('Failed to reload auth status: $e'));
    }
  }
}
