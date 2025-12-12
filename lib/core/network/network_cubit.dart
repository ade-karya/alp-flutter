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
  const NetworkScanning(this.peers, {this.serverIp});
  @override
  List<Object> get props => [peers, serverIp ?? ''];
}

class NetworkDisabled extends NetworkState {}

// CUBIT
class NetworkCubit extends Cubit<NetworkState> {
  final NetworkDiscoveryService _service;
  StreamSubscription? _subscription;
  SyncServer? _syncServer;
  String? _serverIp;

  // Manual peers list (added by IP)
  final List<Map<String, String>> _manualPeers = [];
  // Discovered peers list (from mDNS)
  List<Map<String, String>> _discoveredPeers = [];

  NetworkCubit(this._service) : super(NetworkInitial());

  String? get serverIp => _serverIp;
  bool get isServerRunning => _syncServer?.isRunning ?? false;

  Future<void> start(User user) async {
    debugPrint(
      'NetworkCubit.start() called for user: ${user.name}, role: ${user.role}',
    );

    try {
      // 1. Skip mDNS broadcast on Windows (has platform bugs)
      // On mobile platforms, broadcast works fine
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
        _serverIp = await _syncServer!.start();
        if (_serverIp != null) {
          debugPrint('Sync server started at $_serverIp:3000');
        } else {
          debugPrint('Sync server failed to start');
        }
      }

      // 3. Emit scanning state immediately with any existing manual peers
      debugPrint('Emitting NetworkScanning state...');
      emit(NetworkScanning(_getAllPeers(), serverIp: _serverIp));
      debugPrint('NetworkScanning state emitted');

      // 4. Discover others via mDNS (skip on Windows)
      if (!Platform.isWindows) {
        await _subscription?.cancel();
        _subscription = _service.startDiscovery().listen((peers) {
          _discoveredPeers = peers
              .where((p) => p['identifier'] != user.identifier)
              .toList();
          debugPrint('Discovered ${_discoveredPeers.length} peers via mDNS');
          emit(NetworkScanning(_getAllPeers(), serverIp: _serverIp));
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
        emit(NetworkScanning(_getAllPeers(), serverIp: _serverIp));
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
      emit(NetworkScanning(_getAllPeers(), serverIp: _serverIp));
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
