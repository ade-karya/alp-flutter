import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import '../auth/models/user_model.dart';
import 'network_discovery_service.dart';
import 'firebase_sync_service.dart';
import 'sync_server.dart';
import 'sync_client.dart';

// ENUM: Connection Mode
enum ConnectionMode {
  local, // LAN only (mDNS)
  internet, // Internet via Firebase
  hybrid, // Both (default)
}

// STATE
abstract class NetworkState extends Equatable {
  const NetworkState();
  @override
  List<Object> get props => [];
}

class NetworkInitial extends NetworkState {}

class NetworkScanning extends NetworkState {
  final List<Map<String, String>> peers;
  final String? serverIp;
  final List<Map<String, String>> availableInterfaces;
  final ConnectionMode mode;
  final bool isFirebaseConnected;

  const NetworkScanning(
    this.peers, {
    this.serverIp,
    this.availableInterfaces = const [],
    this.mode = ConnectionMode.hybrid,
    this.isFirebaseConnected = false,
  });

  @override
  List<Object> get props => [
    peers,
    serverIp ?? '',
    availableInterfaces,
    mode,
    isFirebaseConnected,
  ];
}

class NetworkDisabled extends NetworkState {}

// CUBIT with Internet Support
class NetworkCubitV2 extends Cubit<NetworkState> {
  final NetworkDiscoveryService _localService;
  final FirebaseSyncService _firebaseService;

  StreamSubscription? _localSubscription;
  StreamSubscription? _firebaseSubscription;
  SyncServer? _syncServer;

  String? _serverIp;
  List<Map<String, String>> _availableInterfaces = [];
  ConnectionMode _connectionMode = ConnectionMode.hybrid;
  bool _isFirebaseConnected = false;
  String? _currentSessionCode;
  User? _currentUser;

  // Peers storage
  final List<Map<String, String>> _manualPeers = [];
  List<Map<String, String>> _localPeers = [];
  List<Map<String, String>> _internetPeers = [];

  NetworkCubitV2(this._localService, this._firebaseService)
    : super(NetworkInitial());

  String? get serverIp => _serverIp;
  bool get isServerRunning => _syncServer?.isRunning ?? false;
  List<Map<String, String>> get availableInterfaces => _availableInterfaces;
  ConnectionMode get connectionMode => _connectionMode;
  bool get isFirebaseConnected => _isFirebaseConnected;

  /// Start network with selected mode
  Future<void> start(User user, {ConnectionMode? mode}) async {
    _connectionMode = mode ?? ConnectionMode.hybrid;
    _currentUser = user;

    debugPrint(
      'NetworkCubitV2.start() - User: ${user.name}, Mode: $_connectionMode',
    );

    try {
      // Load available interfaces
      _availableInterfaces = await _localService.getAllNetworkInterfaces();
      if (_availableInterfaces.isNotEmpty) {
        _serverIp = _availableInterfaces.first['ip'];
      }

      // Start based on mode
      switch (_connectionMode) {
        case ConnectionMode.local:
          await _startLocalOnly(user);
          break;
        case ConnectionMode.internet:
          await _startInternetOnly(user);
          break;
        case ConnectionMode.hybrid:
          await _startHybrid(user);
          break;
      }

      _emitScanning();
    } catch (e, stack) {
      debugPrint('Network Start Error: $e\n$stack');
      emit(NetworkDisabled());
    }
  }

  /// Start LOCAL network only (existing mDNS)
  Future<void> _startLocalOnly(User user) async {
    debugPrint('Starting LOCAL mode...');

    // Skip mDNS broadcast on Windows
    if (!Platform.isWindows) {
      await _localService.startBroadcast(user);
    }

    // Start sync server for teachers
    if (user.role == UserRole.teacher && user.id != null) {
      _syncServer = SyncServer(teacherId: user.id!);
      final boundIp = await _syncServer!.start();
      if (boundIp != null) {
        _serverIp = boundIp;
        debugPrint('Local server started at $_serverIp:3000');
      }
    }

    // Discover peers via mDNS
    if (!Platform.isWindows) {
      await _localSubscription?.cancel();
      _localSubscription = _localService.startDiscovery().listen((peers) {
        _localPeers = peers
            .where((p) => p['identifier'] != user.identifier)
            .toList();
        debugPrint('Local peers: ${_localPeers.length}');
        _emitScanning();
      });
    }
  }

  /// Start INTERNET mode only (Firebase)
  Future<void> _startInternetOnly(User user) async {
    debugPrint('Starting INTERNET mode...');

    try {
      if (user.role == UserRole.teacher) {
        // Teacher creates a session
        _currentSessionCode = await _firebaseService.createSession(
          teacher: user,
          classData: {'teacherId': user.id, 'teacherName': user.name},
        );
        _isFirebaseConnected = true;

        // Listen to connected students
        await _firebaseSubscription?.cancel();
        _firebaseSubscription = _firebaseService
            .listenToConnectedStudents(_currentSessionCode!)
            .listen((students) {
              _internetPeers = students.entries
                  .map(
                    (entry) => {
                      'name':
                          (entry.value as Map)['name']?.toString() ?? 'Unknown',
                      'role': 'student',
                      'identifier':
                          (entry.value as Map)['identifier']?.toString() ?? '',
                      'host': 'firebase:${entry.key}',
                      'serviceName': 'internet_${entry.key}',
                      'source': 'internet',
                    },
                  )
                  .toList();

              debugPrint('Internet peers: ${_internetPeers.length}');
              _emitScanning();
            });

        debugPrint('Firebase session created: $_currentSessionCode');
      }
    } catch (e) {
      debugPrint('Firebase connection failed: $e');
      _isFirebaseConnected = false;
    }
  }

  /// Start HYBRID mode (both local and internet)
  Future<void> _startHybrid(User user) async {
    debugPrint('Starting HYBRID mode...');
    await _startLocalOnly(user);
    await _startInternetOnly(user);
  }

  /// Switch connection mode on-the-fly
  Future<void> switchMode(ConnectionMode newMode, User user) async {
    if (_connectionMode == newMode) return;

    await stop();
    await start(user, mode: newMode);
  }

  void _emitScanning() {
    emit(
      NetworkScanning(
        _getAllPeers(),
        serverIp: _serverIp,
        availableInterfaces: _availableInterfaces,
        mode: _connectionMode,
        isFirebaseConnected: _isFirebaseConnected,
      ),
    );
  }

  /// Combine all peer sources
  List<Map<String, String>> _getAllPeers() {
    final combined = <Map<String, String>>[];

    // Priority: Manual > Internet > Local
    for (final peer in _manualPeers) {
      if (!combined.any((p) => p['identifier'] == peer['identifier'])) {
        combined.add(peer);
      }
    }

    for (final peer in _internetPeers) {
      if (!combined.any((p) => p['identifier'] == peer['identifier'])) {
        combined.add(peer);
      }
    }

    for (final peer in _localPeers) {
      if (!combined.any((p) => p['identifier'] == peer['identifier'])) {
        combined.add(peer);
      }
    }

    return combined;
  }

  /// Add peer manually by IP
  Future<bool> addManualPeer(String ipAddress) async {
    try {
      final client = SyncClient(host: ipAddress);
      final isAlive = await client.ping();

      if (!isAlive) return false;

      final peer = {
        'name': 'Manual ($ipAddress)',
        'role': 'teacher',
        'identifier': 'manual_$ipAddress',
        'host': ipAddress,
        'serviceName': 'manual_$ipAddress',
        'source': 'manual',
      };

      _manualPeers.removeWhere((p) => p['host'] == ipAddress);
      _manualPeers.add(peer);
      _emitScanning();

      return true;
    } catch (e) {
      debugPrint('Failed to add manual peer: $e');
      return false;
    }
  }

  void removeManualPeer(String ipAddress) {
    _manualPeers.removeWhere((p) => p['host'] == ipAddress);
    _emitScanning();
  }

  void selectInterface(String ip) {
    if (_availableInterfaces.any((i) => i['ip'] == ip)) {
      _serverIp = ip;
      _emitScanning();
    }
  }

  List<Map<String, String>> getTeacherPeers() {
    return _getAllPeers().where((p) => p['role'] == 'teacher').toList();
  }

  Future<void> toggleServer(bool enable, User user) async {
    if (enable) {
      await start(user);
    } else {
      await stop();
      emit(NetworkDisabled());
    }
  }

  Future<void> stop() async {
    await _syncServer?.stop();
    _syncServer = null;
    _serverIp = null;

    await _localService.stopBroadcast();
    await _localService.stopDiscovery();
    await _localSubscription?.cancel();

    if (_isFirebaseConnected && _currentSessionCode != null) {
      if (_currentUser?.role == UserRole.teacher) {
        await _firebaseService.closeSession(_currentSessionCode!);
      } else if (_currentUser != null) {
        await _firebaseService.leaveSession(
          sessionCode: _currentSessionCode!,
          studentId: _currentUser!.id ?? 0,
        );
      }
      await _firebaseSubscription?.cancel();
      _isFirebaseConnected = false;
      _currentSessionCode = null;
    }

    _localPeers.clear();
    _internetPeers.clear();

    emit(NetworkDisabled());
  }

  @override
  Future<void> close() {
    stop();
    return super.close();
  }
}
