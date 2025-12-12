import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/network_cubit.dart';
import '../../../core/network/network_permission_service.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/widgets/app_drawer.dart';

class NetworkStatusScreen extends StatefulWidget {
  const NetworkStatusScreen({super.key});

  @override
  State<NetworkStatusScreen> createState() => _NetworkStatusScreenState();
}

class _NetworkStatusScreenState extends State<NetworkStatusScreen> {
  bool _isLoading = false;
  final _permissionService = NetworkPermissionService();

  Future<void> _activateNetwork() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login terlebih dahulu')),
      );
      return;
    }

    // Show platform-specific permission info
    final shouldProceed = await _showPermissionDialog();
    if (!shouldProceed) return;

    setState(() => _isLoading = true);

    try {
      // Request platform permissions first
      final hasPermission = await _permissionService.requestPermissions();

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin jaringan diperlukan untuk melanjutkan'),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final cubit = context.read<NetworkCubit>();
      await cubit.start(authState.user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jaringan berhasil diaktifkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengaktifkan jaringan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showPermissionDialog() async {
    String title;
    String content;
    String confirmText;

    if (Platform.isWindows) {
      title = 'Izin Administrator Diperlukan';
      content =
          'Windows memerlukan izin administrator untuk membuka port jaringan (3000).\n\nDialog UAC akan muncul untuk mengonfirmasi.';
      confirmText = 'Lanjutkan sebagai Admin';
    } else if (Platform.isAndroid) {
      title = 'Izin Lokasi Diperlukan';
      content =
          'Android memerlukan izin lokasi untuk menemukan perangkat lain di WiFi yang sama.\n\nData lokasi tidak akan disimpan atau dikirim ke server.';
      confirmText = 'Izinkan';
    } else {
      return true; // Other platforms don't need permission dialog
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Platform.isWindows
                  ? Icons.admin_panel_settings
                  : Icons.location_on,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _deactivateNetwork() async {
    await context.read<NetworkCubit>().stop();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jaringan dinonaktifkan')));
    }
  }

  Future<void> _showAddPeerDialog() async {
    final ipController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_link, color: Colors.blue),
            SizedBox(width: 8),
            Text('Tambah Peer Manual'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan IP Address dari perangkat guru:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
                prefixIcon: Icon(Icons.lan),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contoh: 192.168.1.100',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (ipController.text.isNotEmpty) {
                Navigator.pop(context, ipController.text);
              }
            },
            child: const Text('Hubungkan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Menghubungkan ke $result...')));

      final success = await context.read<NetworkCubit>().addManualPeer(result);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Berhasil terhubung ke $result')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tidak dapat terhubung ke $result. Pastikan server aktif.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Jaringan')),
      drawer: const AppDrawer(),
      floatingActionButton: BlocBuilder<NetworkCubit, NetworkState>(
        builder: (context, state) {
          if (state is NetworkScanning) {
            return FloatingActionButton.extended(
              onPressed: _showAddPeerDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Manual'),
              tooltip: 'Tambah peer secara manual dengan IP',
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: BlocBuilder<NetworkCubit, NetworkState>(
        builder: (context, state) {
          final networkCubit = context.read<NetworkCubit>();

          // Handle Initial and Disabled states
          if (state is NetworkInitial || state is NetworkDisabled) {
            return _buildDisabledView(context);
          }

          if (state is NetworkScanning) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Toggle Card
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.wifi, color: Colors.green, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Jaringan Aktif',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _deactivateNetwork,
                            icon: const Icon(Icons.power_settings_new),
                            label: const Text('Nonaktifkan Jaringan'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Server Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              networkCubit.isServerRunning
                                  ? Icons.cloud_done
                                  : Icons.cloud_off,
                              color: networkCubit.isServerRunning
                                  ? Colors.green
                                  : Colors.grey,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sync Server',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  Text(
                                    networkCubit.isServerRunning
                                        ? 'Running'
                                        : 'Stopped (Hanya Siswa)',
                                    style: TextStyle(
                                      color: networkCubit.isServerRunning
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (networkCubit.isServerRunning &&
                            state.serverIp != null) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            'IP Address',
                            state.serverIp!,
                            Icons.lan,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Port',
                            '3000',
                            Icons.settings_ethernet,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'URL',
                            'http://${state.serverIp}:3000',
                            Icons.link,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Peers Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Pengguna di Jaringan (${state.peers.length})',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (state.peers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Mencari pengguna lain...',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...state.peers.map((peer) => _buildPeerTile(peer)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info Card
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pastikan semua perangkat terhubung ke WiFi yang sama untuk dapat saling menemukan.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildDisabledView(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 24),
                Text(
                  'Jaringan Tidak Aktif',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aktifkan jaringan untuk mulai berbagi data dengan perangkat lain di WiFi yang sama.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : FilledButton.icon(
                        onPressed: _activateNetwork,
                        icon: const Icon(Icons.power_settings_new),
                        label: const Text('Aktifkan Jaringan'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPeerTile(Map<String, String> peer) {
    final name = peer['name'] ?? 'Unknown';
    final role = peer['role'] ?? 'unknown';
    final host = peer['host'] ?? '';

    IconData roleIcon;
    Color roleColor;

    switch (role) {
      case 'teacher':
        roleIcon = Icons.school;
        roleColor = Colors.orange;
        break;
      case 'student':
        roleIcon = Icons.person;
        roleColor = Colors.blue;
        break;
      default:
        roleIcon = Icons.person_outline;
        roleColor = Colors.grey;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: roleColor.withAlpha(50),
        child: Icon(roleIcon, color: roleColor),
      ),
      title: Text(name),
      subtitle: Text(
        role == 'teacher' ? 'Guru' : 'Siswa',
        style: TextStyle(color: roleColor),
      ),
      trailing: Text(
        host,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
