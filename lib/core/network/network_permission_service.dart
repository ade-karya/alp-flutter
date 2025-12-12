import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle platform-specific network permissions
class NetworkPermissionService {
  /// Check and request permissions for network features
  /// Returns true if all permissions are granted
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isWindows) {
      return await _setupWindowsFirewall();
    }
    // Other platforms (iOS, macOS, Linux) - assume OK for now
    return true;
  }

  /// Android: Request runtime permissions for network discovery
  Future<bool> _requestAndroidPermissions() async {
    try {
      // Check if permissions are already granted
      final status = await Permission.location.status;

      if (status.isGranted) {
        debugPrint('Android: Network permissions already granted');
        return true;
      }

      // Request location permission (needed for WiFi scanning on Android 10+)
      final result = await Permission.location.request();

      if (result.isGranted) {
        debugPrint('Android: Network permissions granted');
        return true;
      } else if (result.isPermanentlyDenied) {
        debugPrint('Android: Permission permanently denied, open settings');
        await openAppSettings();
        return false;
      }

      debugPrint('Android: Network permissions denied');
      return false;
    } catch (e) {
      debugPrint('Android permission error: $e');
      return true; // Proceed anyway, may work without explicit permission
    }
  }

  /// Windows: Setup firewall rule for port 3000
  Future<bool> _setupWindowsFirewall() async {
    try {
      // Check if rule already exists
      final checkResult = await Process.run('netsh', [
        'advfirewall',
        'firewall',
        'show',
        'rule',
        'name=ALP Sync Server',
      ], runInShell: true);

      if (checkResult.stdout.toString().contains('ALP Sync Server')) {
        debugPrint('Windows: Firewall rule already exists');
        return true;
      }

      // Create the firewall rule
      debugPrint('Windows: Creating firewall rule for port 3000...');

      // Using PowerShell with elevation request
      const script = '''
        \$ruleName = "ALP Sync Server"
        \$ruleExists = Get-NetFirewallRule -DisplayName \$ruleName -ErrorAction SilentlyContinue
        if (-not \$ruleExists) {
          New-NetFirewallRule -DisplayName \$ruleName -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
          New-NetFirewallRule -DisplayName "\$ruleName Outbound" -Direction Outbound -Protocol TCP -LocalPort 3000 -Action Allow
          Write-Host "Firewall rule created successfully"
        } else {
          Write-Host "Firewall rule already exists"
        }
      ''';

      final result = await Process.run('powershell', [
        '-Command',
        'Start-Process',
        'powershell',
        '-Verb',
        'RunAs',
        '-ArgumentList',
        '"-Command $script"',
        '-Wait',
      ], runInShell: true);

      if (result.exitCode == 0) {
        debugPrint('Windows: Firewall rule setup completed');
        return true;
      } else {
        debugPrint('Windows: Firewall setup failed: ${result.stderr}');
        // Still return true - user may have cancelled but we can try anyway
        return true;
      }
    } catch (e) {
      debugPrint('Windows firewall error: $e');
      return true; // Proceed anyway
    }
  }

  /// Show platform-specific permission info
  String getPermissionInfo() {
    if (Platform.isAndroid) {
      return 'Android memerlukan izin lokasi untuk menemukan perangkat di WiFi yang sama.';
    } else if (Platform.isWindows) {
      return 'Windows memerlukan izin administrator untuk membuka port jaringan.';
    }
    return 'Jaringan akan diaktifkan.';
  }
}
