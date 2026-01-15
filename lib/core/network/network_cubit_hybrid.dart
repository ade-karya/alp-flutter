import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../auth/models/user_model.dart';
import 'network_discovery_service.dart';
import 'firebase_sync_service.dart';
import 'sync_server.dart';
import 'sync_client.dart';
import 'package:flutter/foundation.dart';

// States
abstract class NetworkState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NetworkInitial extends NetworkState {}

class NetworkStarted extends NetworkState {
  final User user;
  final String? localIp;
  final String? firebaseSessionCode;
  final NetworkMode mode;

  NetworkStarted({
    required this.user,
    this.localIp,
    this.firebaseSessionCode,
    required this.mode,
  });

  @override
  List<Object?> get props => [user, localIp, firebaseSessionCode, mode];
}

class NetworkPeersUpdated extends NetworkState {
  final List<Map<String, String>> peers;
  final Map<String, dynamic>? connectedStudents; // For Firebase mode

  NetworkPeersUpdated({required this.peers, this.connectedStudents});

  @override
  List<Object?> get props => [peers, connectedStudents];
}

class NetworkError extends NetworkState {
  final String message;

  NetworkError(this.message);

  @override
  List<Object?> get props => [message];
}

enum NetworkMode {
  localOnly, // P2P via mDNS (same WiFi)
  firebaseOnly, // Firebase Firestore (internet)
  hybrid, // Try local first, fallback to Firebase
}

class NetworkCubit extends Cubit<NetworkState> {
  final NetworkDiscoveryService _discoveryService;
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();

  SyncServer? _server;
  StreamSubscription? _discoverySubscription;
  StreamSubscription? _firebaseStudentsSubscription;

  User? _currentUser;
  String? _firebaseSessionCode;

  NetworkCubit(this._discoveryService) : super(NetworkInitial());

  /// Start network with mode selection
  Future<void> start(User user, {NetworkMode mode = NetworkMode.hybrid}) async {
    try {
      _currentUser = user;

      String? localIp;
      String? sessionCode;

      // Try local P2P if not Firebase-only mode
      if (mode != NetworkMode.firebaseOnly) {
        localIp = await _startLocalNetwork(user);
      }

      // Start Firebase if not local-only mode
      if (mode != NetworkMode.localOnly) {
        sessionCode = await _startFirebaseNetwork(user);
      }

      // Determine active mode based on what succeeded
      final activeMode = _determineActiveMode(localIp, sessionCode, mode);

      emit(
        NetworkStarted(
          user: user,
          localIp: localIp,
          firebaseSessionCode: sessionCode,
          mode: activeMode,
        ),
      );

      debugPrint('Network started - Mode: $activeMode');
    } catch (e) {
      emit(NetworkError('Failed to start network: $e'));
    }
  }

  Future<String?> _startLocalNetwork(User user) async {
    try {
      if (user.role == UserRole.teacher && user.id != null) {
        // Start HTTP server
        _server = SyncServer(teacherId: user.id!);
        final ip = await _server!.start();

        if (ip != null) {
          // Start mDNS broadcast
          await _discoveryService.startBroadcast(user);
          debugPrint('Local P2P started on $ip:3000');
          return ip;
        }
      } else {
        // Start discovery for students
        _discoverySubscription = _discoveryService.startDiscovery().listen(
          (peers) {
            emit(NetworkPeersUpdated(peers: peers));
          },
          onError: (e) {
            debugPrint('Discovery error: $e');
          },
        );
        debugPrint('Local discovery started for student');
        return 'discovering';
      }
    } catch (e) {
      debugPrint('Local network error: $e');
    }
    return null;
  }

  Future<String?> _startFirebaseNetwork(User user) async {
    try {
      if (user.role == UserRole.teacher) {
        // Teacher creates a session
        // You'll need to provide class data when creating
        // For now, we'll just generate a session code
        final sessionCode = await _firebaseSyncService.createSession(
          teacher: user,
          classData: {'teacherId': user.id, 'teacherName': user.name},
        );

        _firebaseSessionCode = sessionCode;

        // Listen to connected students
        _firebaseStudentsSubscription = _firebaseSyncService
            .listenToConnectedStudents(sessionCode)
            .listen((students) {
              emit(
                NetworkPeersUpdated(
                  peers: const [],
                  connectedStudents: students,
                ),
              );
            });

        debugPrint('Firebase session created: $sessionCode');
        return sessionCode;
      }
    } catch (e) {
      debugPrint('Firebase network error: $e');
    }
    return null;
  }

  NetworkMode _determineActiveMode(
    String? localIp,
    String? sessionCode,
    NetworkMode requestedMode,
  ) {
    if (requestedMode == NetworkMode.localOnly) {
      return localIp != null ? NetworkMode.localOnly : NetworkMode.localOnly;
    }

    if (requestedMode == NetworkMode.firebaseOnly) {
      return sessionCode != null
          ? NetworkMode.firebaseOnly
          : NetworkMode.firebaseOnly;
    }

    // Hybrid mode
    if (localIp != null && sessionCode != null) {
      return NetworkMode.hybrid;
    } else if (localIp != null) {
      return NetworkMode.localOnly;
    } else if (sessionCode != null) {
      return NetworkMode.firebaseOnly;
    }

    return NetworkMode.hybrid;
  }

  /// Join Firebase session (for students connecting over internet)
  Future<bool> joinFirebaseSession(String sessionCode, User student) async {
    try {
      final sessionData = await _firebaseSyncService.joinSession(
        sessionCode: sessionCode,
        student: student,
      );

      if (sessionData != null) {
        _firebaseSessionCode = sessionCode;
        debugPrint('Joined Firebase session: $sessionCode');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error joining Firebase session: $e');
      return false;
    }
  }

  /// Connect to local peer (existing local P2P)
  Future<SyncClient?> connectToLocalPeer(String host) async {
    try {
      final client = SyncClient(host: host);
      final isAvailable = await client.ping();

      if (isAvailable) {
        debugPrint('Connected to local peer: $host');
        return client;
      }
    } catch (e) {
      debugPrint('Error connecting to local peer: $e');
    }
    return null;
  }

  /// Get current session code (for teacher to share)
  String? get sessionCode => _firebaseSessionCode;

  /// Get Firebase sync service
  FirebaseSyncService get firebaseSync => _firebaseSyncService;

  /// Stop network
  Future<void> stop() async {
    await _server?.stop();
    await _discoveryService.stopBroadcast();
    await _discoveryService.stopDiscovery();
    await _discoverySubscription?.cancel();
    await _firebaseStudentsSubscription?.cancel();

    if (_firebaseSessionCode != null &&
        _currentUser?.role == UserRole.teacher) {
      await _firebaseSyncService.closeSession(_firebaseSessionCode!);
    } else if (_firebaseSessionCode != null && _currentUser != null) {
      await _firebaseSyncService.leaveSession(
        sessionCode: _firebaseSessionCode!,
        studentId: _currentUser!.id ?? 0,
      );
    }

    _server = null;
    _firebaseSessionCode = null;
    _currentUser = null;

    emit(NetworkInitial());
    debugPrint('Network stopped');
  }

  /// Switch network mode (e.g., from local to Firebase if local fails)
  Future<void> switchMode(NetworkMode newMode) async {
    if (_currentUser == null) return;

    await stop();
    await start(_currentUser!, mode: newMode);
  }
}
