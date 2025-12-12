import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/network_cubit.dart';
import '../../../core/network/network_discovery_service.dart';
import '../../../core/network/sync_client.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/widgets/app_drawer.dart';

class P2PConnectionScreen extends StatefulWidget {
  const P2PConnectionScreen({super.key});

  @override
  State<P2PConnectionScreen> createState() => _P2PConnectionScreenState();
}

class _P2PConnectionScreenState extends State<P2PConnectionScreen> {
  final _ipController = TextEditingController();
  String? _localIp;
  bool _isLoading = false;
  bool _isServerActive = false;
  String? _connectionResult;
  bool _connectionSuccess = false;

  // Network interfaces for Windows with multiple adapters
  List<Map<String, String>> _networkInterfaces = [];
  String? _selectedInterface;

  @override
  void initState() {
    super.initState();
    _loadNetworkInterfaces();
    _checkServerStatus();
  }

  Future<void> _loadNetworkInterfaces() async {
    final service = NetworkDiscoveryService();
    final interfaces = await service.getAllNetworkInterfaces();
    if (mounted) {
      setState(() {
        _networkInterfaces = interfaces;
        // Select first 192.x.x.x IP if available, otherwise first one
        if (interfaces.isNotEmpty) {
          final preferred = interfaces.firstWhere(
            (i) => i['ip']?.startsWith('192.') == true,
            orElse: () => interfaces.first,
          );
          _selectedInterface = preferred['ip'];
          _localIp = preferred['ip'];
        }
      });
    }
  }

  void _checkServerStatus() {
    final networkCubit = context.read<NetworkCubit>();
    setState(() => _isServerActive = networkCubit.isServerRunning);
  }

  Future<void> _startServer() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showMessage('Anda harus login terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('Starting server...');
      await context.read<NetworkCubit>().start(authState.user);
      await _loadNetworkInterfaces();
      _checkServerStatus();

      if (_isServerActive) {
        _showMessage('Server berhasil diaktifkan pada $_localIp:3000');
      } else {
        _showMessage('Server gagal diaktifkan, coba lagi', isError: true);
      }
    } catch (e) {
      debugPrint('Server start error: $e');
      _showMessage('Gagal mengaktifkan server: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _stopServer() async {
    await context.read<NetworkCubit>().stop();
    _checkServerStatus();
    _showMessage('Server dinonaktifkan');
  }

  Future<void> _testConnection() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      _showMessage('Masukkan IP Address terlebih dahulu', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _connectionResult = null;
    });

    try {
      final client = SyncClient(host: ip);
      final isAlive = await client.ping();

      if (mounted) {
        setState(() {
          _connectionSuccess = isAlive;
          _connectionResult = isAlive
              ? '✅ Berhasil terhubung ke $ip:3000'
              : '❌ Tidak dapat terhubung ke $ip:3000';
        });

        if (isAlive) {
          // Add to peer list
          await context.read<NetworkCubit>().addManualPeer(ip);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionSuccess = false;
          _connectionResult = '❌ Error: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showMessage('Tersalin: $text');
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isTeacher =
        authState is Authenticated && authState.user.role.name == 'teacher';

    return Scaffold(
      appBar: AppBar(title: const Text('Koneksi P2P')),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.sync_alt,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sinkronisasi Peer-to-Peer',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hubungkan perangkat di jaringan WiFi yang sama',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withAlpha(204),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // For Teachers: Server Info
            if (isTeacher) ...[
              Text(
                '👨‍🏫 Mode Guru',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isServerActive
                                ? Icons.cloud_done
                                : Icons.cloud_off,
                            color: _isServerActive ? Colors.green : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Server',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  _isServerActive ? 'Aktif' : 'Tidak Aktif',
                                  style: TextStyle(
                                    color: _isServerActive
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : FilledButton(
                                  onPressed: _isServerActive
                                      ? _stopServer
                                      : _startServer,
                                  child: Text(
                                    _isServerActive ? 'Stop' : 'Start',
                                  ),
                                ),
                        ],
                      ),
                      if (_isServerActive && _localIp != null) ...[
                        const Divider(height: 24),

                        // Network interface selector (when multiple available)
                        if (_networkInterfaces.length > 1) ...[
                          const Text(
                            'Pilih Network Interface:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedInterface,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: _networkInterfaces.map((iface) {
                              return DropdownMenuItem<String>(
                                value: iface['ip'],
                                child: Text(
                                  '${iface['name']} - ${iface['ip']}',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedInterface = value;
                                _localIp = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                        ],

                        const Text(
                          'Beritahu siswa IP ini:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'IP Address:',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      _localIp!,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const Text(
                                      'Port: 3000',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filled(
                                onPressed: () => _copyToClipboard(_localIp!),
                                icon: const Icon(Icons.copy),
                                tooltip: 'Salin IP',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // For Students: Connect to Teacher
            Text(
              isTeacher ? '🔗 Hubungkan ke Guru Lain' : '👨‍🎓 Mode Siswa',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Masukkan IP Address dari perangkat guru:'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        labelText: 'IP Address Guru',
                        hintText: '192.168.1.100',
                        prefixIcon: const Icon(Icons.computer),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _ipController.clear(),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _testConnection,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.link),
                        label: const Text('Test Koneksi'),
                      ),
                    ),
                    if (_connectionResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _connectionSuccess
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _connectionSuccess
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          _connectionResult!,
                          style: TextStyle(
                            color: _connectionSuccess
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Petunjuk',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      '1',
                      'Pastikan kedua perangkat terhubung ke WiFi yang sama',
                    ),
                    _buildInstructionItem(
                      '2',
                      'Guru: Aktifkan server dan catat IP Address',
                    ),
                    _buildInstructionItem(
                      '3',
                      'Siswa: Masukkan IP guru dan tekan "Test Koneksi"',
                    ),
                    _buildInstructionItem(
                      '4',
                      'Jika berhasil, siswa dapat gabung kelas via PIN',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Network Info
            if (_localIp != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Info Jaringan Anda',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('IP Address', _localIp!),
                      _buildInfoRow('Platform', Platform.operatingSystem),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
}
