import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bonsoir/bonsoir.dart';
import '../auth/models/user_model.dart';

class NetworkDiscoveryService {
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription? _broadcastSubscription;
  StreamSubscription? _discoverySubscription;

  final String _type = '_alp-edu._tcp';

  /// Get local IP address (prefers WiFi)
  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      final validInterfaces = <Map<String, dynamic>>[];

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();

        // Skip VPNs and Virtual Adapters
        if (name.contains('virtual') ||
            name.contains('vmware') ||
            name.contains('vbox') ||
            name.contains('hyper-v') ||
            name.contains('tailscale') ||
            name.contains('docker')) {
          continue;
        }

        for (var addr in interface.addresses) {
          if (addr.isLoopback || addr.address == '127.0.0.1') continue;

          // Score detection
          int score = 0;

          if (name.contains('hotspot') || addr.address == '192.168.137.1') {
            score += 200;
          }

          if (name.contains('wi-fi') ||
              name.contains('wifi') ||
              name.contains('wlan') ||
              name.contains('wireless')) {
            score += 100;
          }

          if (name.contains('local area connection') ||
              name.contains('ethernet')) {
            score += 50;
          }

          if (addr.address.startsWith('192.168.')) score += 20;

          validInterfaces.add({
            'ip': addr.address,
            'score': score,
            'name': interface.name,
          });
        }
      }

      // Sort by score descending
      validInterfaces.sort(
        (a, b) => (b['score'] as int).compareTo(a['score'] as int),
      );

      if (validInterfaces.isNotEmpty) {
        final best = validInterfaces.first;
        debugPrint('Best IP found: ${best['ip']} on ${best['name']}');
        return best['ip'] as String;
      }
    } catch (e) {
      debugPrint('Failed to get local IP: $e');
    }
    return null;
  }

  /// Get all available network interfaces
  Future<List<Map<String, String>>> getAllNetworkInterfaces() async {
    final result = <Map<String, String>>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            final name = interface.name.toLowerCase();

            // Skip virtual adapters
            if (name.contains('virtual') ||
                name.contains('vmware') ||
                name.contains('vbox') ||
                name.contains('docker') ||
                name.contains('hyper-v')) {
              debugPrint('Skipping: ${interface.name}');
              continue;
            }

            final isWifi =
                name.contains('wi-fi') ||
                name.contains('wifi') ||
                name.contains('wlan') ||
                name.contains('wireless');

            result.add({
              'name': interface.name,
              'ip': addr.address,
              'isWifi': isWifi.toString(),
            });
            debugPrint(
              'Found: ${interface.name} = ${addr.address} (WiFi: $isWifi)',
            );
          }
        }
      }

      // Sort: WiFi first
      result.sort((a, b) {
        final aWifi = a['isWifi'] == 'true';
        final bWifi = b['isWifi'] == 'true';
        if (aWifi && !bWifi) return -1;
        if (!aWifi && bWifi) return 1;
        return 0;
      });
    } catch (e) {
      debugPrint('Failed to get interfaces: $e');
    }
    return result;
  }

  Future<void> startBroadcast(User user) async {
    // Stop previous broadcast if exists
    await stopBroadcast();

    final localIp = await getLocalIpAddress();
    debugPrint('Local IP for broadcast: $localIp');

    final safeName = user.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final serviceName = 'ALP-$safeName-${user.role.name}';

    final service = BonsoirService(
      name: serviceName,
      type: _type,
      port: 3000,
      attributes: {
        'id': user.id.toString(),
        'name': user.name,
        'role': user.role.name,
        'identifier': user.identifier,
        'ip': localIp ?? '',
      },
    );

    // Create NEW instance (important - can't reuse stopped instance)
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.initialize();
    await _broadcast!.start();

    debugPrint('Broadcasting: $serviceName with IP: $localIp');
  }

  Stream<List<Map<String, String>>> startDiscovery() {
    final List<Map<String, String>> discoveredUsers = [];
    final controller = StreamController<List<Map<String, String>>>.broadcast();

    // Create new discovery instance
    _discovery = BonsoirDiscovery(type: _type);

    // We need to wait for ready, but this method returns a Stream synchronously.
    // We'll execute the start logic asynchronously.
    Future.microtask(() async {
      try {
        await _discovery!.initialize();
        debugPrint('Starting discovery for type: $_type');
        await _discovery!.start();

        _discoverySubscription = _discovery!.eventStream?.listen((event) {
          debugPrint('Discovery event: $event');

          if (event.service != null) {
            final s = event.service!;
            final eventString = event.toString().toLowerCase();

            if (eventString.contains('found')) {
              try {
                s.resolve(_discovery!.serviceResolver);
              } catch (e) {
                debugPrint('Resolve error: $e');
              }
            }

            if (eventString.contains('resolved')) {
              final attrs = s.attributes;

              if (attrs.containsKey('name') && attrs.containsKey('role')) {
                final hostIp = attrs['ip'] ?? '';

                final user = {
                  'name': attrs['name'] ?? 'Unknown',
                  'role': attrs['role'] ?? 'unknown',
                  'identifier': attrs['identifier'] ?? '',
                  'host': hostIp,
                  'serviceName': s.name,
                };

                final index = discoveredUsers.indexWhere(
                  (u) => u['identifier'] == attrs['identifier'],
                );

                if (index != -1) {
                  discoveredUsers[index] = user;
                } else {
                  discoveredUsers.add(user);
                }

                debugPrint('Added/updated: ${user['name']} at $hostIp');
                controller.add(List.from(discoveredUsers));
              }
            }

            if (eventString.contains('lost')) {
              discoveredUsers.removeWhere((u) => u['serviceName'] == s.name);
              controller.add(List.from(discoveredUsers));
            }
          }
        });
      } catch (e) {
        debugPrint('Discovery failed to start: $e');
        controller.addError(e);
      }
    });

    return controller.stream;
  }

  Future<void> stopBroadcast() async {
    await _broadcastSubscription?.cancel();
    _broadcastSubscription = null;

    if (_broadcast != null) {
      try {
        await _broadcast!.stop();
      } catch (e) {
        debugPrint('Error stopping broadcast: $e');
      }
      _broadcast = null;
    }
    debugPrint('Broadcast stopped');
  }

  Future<void> stopDiscovery() async {
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;

    if (_discovery != null) {
      try {
        await _discovery!.stop();
      } catch (e) {
        debugPrint('Error stopping discovery: $e');
      }
      _discovery = null;
    }
    debugPrint('Discovery stopped');
  }
}
