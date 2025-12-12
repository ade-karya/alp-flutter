import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import '../auth/models/user_model.dart';
import 'network_discovery_service.dart';
import 'sync_server.dart';
import 'sync_client.dart';

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

  const NetworkScanning(
    this.peers, {
    this.serverIp,
    this.availableInterfaces = const [],
  });

  @override
  List<Object> get props => [peers, serverIp ?? '', availableInterfaces];
}

class NetworkDisabled extends NetworkState {}

// CUBIT
class NetworkCubit extends Cubit<NetworkState> {
  final NetworkDiscoveryService _service;
  StreamSubscription? _subscription;
  SyncServer? _syncServer;
  String? _serverIp;
  List<Map<String, String>> _availableInterfaces = [];

  // Manual peers list (added by IP)
  final List<Map<String, String>> _manualPeers = [];
  // Discovered peers list (from mDNS)
  List<Map<String, String>> _discoveredPeers = [];

  NetworkCubit(this._service) : super(NetworkInitial());

  String? get serverIp => _serverIp;
  bool get isServerRunning => _syncServer?.isRunning ?? false;
  List<Map<String, String>> get availableInterfaces => _availableInterfaces;

  Future<void> start(User user) async {
    debugPrint(
      'NetworkCubit.start() called for user: ${user.name}, role: ${user.role}',
    );

    try {
      // 0. Load available interfaces first
      _availableInterfaces = await _service.getAllNetworkInterfaces();
      if (_availableInterfaces.isNotEmpty) {
        // Default to the first one (usually WiFi based on sort)
        _serverIp = _availableInterfaces.first['ip'];
      }

      // 1. Skip mDNS broadcast on Windows (has platform bugs)
      if (!Platform.isWindows) {
        debugPrint('Starting mDNS broadcast...');
        await _service.startBroadcast(user);
        debugPrint('Broadcast started');
      } else {
        debugPrint(
          'Windows detected - skipping mDNS broadcast (use manual IP)',
        );
      }

      // 2. Start sync server for teachers
      if (user.role == UserRole.teacher && user.id != null) {
        debugPrint('Starting sync server for teacher...');
        _syncServer = SyncServer(teacherId: user.id!);
        // We bind to 0.0.0.0 (all interfaces) so selection is just for display
        final boundIp = await _syncServer!.start();

        if (boundIp != null) {
          debugPrint('Sync server started at $boundIp:3000');
          // If auto-detected IP is different and valid, add it or use it
          _serverIp ??= boundIp;

          // Ensure boundIp is in availableInterfaces so dropdown works
          if (!_availableInterfaces.any((i) => i['ip'] == boundIp)) {
            _availableInterfaces.insert(0, {
              'ip': boundIp,
              'name': 'Auto-detected Interface',
              'score': '1000',
            });
            // Update _serverIp to match this valid interface
            _serverIp = boundIp;
          }
        } else {
          debugPrint('Sync server failed to start');
        }
      }

      // 3. Emit scanning state immediately
      debugPrint('Emitting NetworkScanning state...');
      _emitScanning();
      debugPrint('NetworkScanning state emitted');

      // 4. Discover others via mDNS (skip on Windows)
      if (!Platform.isWindows) {
        await _subscription?.cancel();
        _subscription = _service.startDiscovery().listen((peers) {
          _discoveredPeers = peers
              .where((p) => p['identifier'] != user.identifier)
              .toList();
          debugPrint('Discovered ${_discoveredPeers.length} peers via mDNS');
          _emitScanning();
        });
        debugPrint('Discovery started');
      } else {
        debugPrint('Windows - use manual IP entry for peer connection');
      }
    } catch (e, stack) {
      debugPrint('Network Start Error: $e');
      debugPrint('Stack: $stack');
      emit(NetworkDisabled());
    }
  }

  Future<void> toggleServer(bool enable, User user) async {
    if (enable) {
      await start(user);
    } else {
      await stop();
      // Emitting disabled state ensures UI reflects the 'OFF' state
      emit(NetworkDisabled());
    }
  }

  void selectInterface(String ip) {
    if (_availableInterfaces.any((i) => i['ip'] == ip)) {
      _serverIp = ip;
      _emitScanning();
    }
  }

  void _emitScanning() {
    emit(
      NetworkScanning(
        _getAllPeers(),
        serverIp: _serverIp,
        availableInterfaces: _availableInterfaces,
      ),
    );
  }

  /// Combine manual + discovered peers
  List<Map<String, String>> _getAllPeers() {
    final combined = <Map<String, String>>[];

    // Add manual peers first
    for (final peer in _manualPeers) {
      if (!combined.any((p) => p['host'] == peer['host'])) {
        combined.add(peer);
      }
    }

    // Add discovered peers
    for (final peer in _discoveredPeers) {
      if (!combined.any((p) => p['host'] == peer['host'])) {
        combined.add(peer);
      }
    }

    return combined;
  }

  /// Add peer manually by IP address
  Future<bool> addManualPeer(String ipAddress) async {
    debugPrint('Adding manual peer: $ipAddress');

    try {
      // Ping the server to verify it's running
      final client = SyncClient(host: ipAddress);
      final isAlive = await client.ping();

      if (!isAlive) {
        debugPrint('Peer at $ipAddress is not responding');
        return false;
      }

      // Get peer info from ping response
      final peer = {
        'name': 'Guru ($ipAddress)',
        'role': 'teacher',
        'identifier': 'manual_$ipAddress',
        'host': ipAddress,
        'serviceName': 'manual_$ipAddress',
        'manual': 'true',
      };

      // Remove existing entry with same IP
      _manualPeers.removeWhere((p) => p['host'] == ipAddress);
      _manualPeers.add(peer);

      debugPrint('Manual peer added: $ipAddress');

      // Emit updated state
      if (state is NetworkScanning) {
        _emitScanning();
      }

      return true;
    } catch (e) {
      debugPrint('Failed to add manual peer: $e');
      return false;
    }
  }

  /// Remove a manual peer
  void removeManualPeer(String ipAddress) {
    _manualPeers.removeWhere((p) => p['host'] == ipAddress);
    if (state is NetworkScanning) {
      _emitScanning();
    }
  }

  /// Get list of discovered teacher peers (for students to connect)
  List<Map<String, String>> getTeacherPeers() {
    return _getAllPeers().where((p) => p['role'] == 'teacher').toList();
  }

  Future<void> stop() async {
    await _syncServer?.stop();
    _syncServer = null;
    _serverIp = null;
    await _service.stopBroadcast();
    await _service.stopDiscovery();
    await _subscription?.cancel();
    _discoveredPeers.clear();
    // Keep manual peers for next session
    emit(NetworkDisabled());
  }

  @override
  Future<void> close() {
    stop();
    return super.close();
  }
}
