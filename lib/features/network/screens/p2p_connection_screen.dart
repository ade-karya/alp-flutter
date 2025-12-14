import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/network_cubit.dart';
import '../../../core/network/network_discovery_service.dart';
import '../../../core/network/sync_client.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/wizard_background.dart';

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
    final isWizard = context.watch<ThemeCubit>().state == AppThemeMode.wizard;

    Widget buildContent() {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              decoration: isWizard
                  ? BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    )
                  : null,
              child: Card(
                color: isWizard
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.primaryContainer,
                elevation: isWizard ? 0 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sync_alt,
                        size: 48,
                        color: isWizard
                            ? const Color(0xFFFFD700)
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sinkronisasi Peer-to-Peer',
                        style: isWizard
                            ? const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Cinzel',
                              )
                            : Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hubungkan perangkat di jaringan WiFi yang sama',
                        style: TextStyle(
                          color: isWizard
                              ? Colors.white70
                              : Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer.withAlpha(204),
                          fontFamily: isWizard ? 'Lato' : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // For Teachers: Server Info
            if (isTeacher) ...[
              Text(
                '👨‍🏫 Mode Guru',
                style: isWizard
                    ? const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cinzel',
                      )
                    : Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: isWizard
                    ? BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      )
                    : null,
                child: Card(
                  color: isWizard ? Colors.transparent : null,
                  elevation: isWizard ? 0 : 1,
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
                              color: _isServerActive
                                  ? Colors.green
                                  : (isWizard ? Colors.white38 : Colors.grey),
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status Server',
                                    style: isWizard
                                        ? const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          )
                                        : Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    _isServerActive ? 'Aktif' : 'Tidak Aktif',
                                    style: TextStyle(
                                      color: _isServerActive
                                          ? Colors.green
                                          : (isWizard
                                                ? Colors.white38
                                                : Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isWizard
                                          ? const Color(0xFFFFD700)
                                          : null,
                                    ),
                                  )
                                : FilledButton(
                                    style: isWizard
                                        ? FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF4A148C,
                                            ),
                                            foregroundColor: Colors.white,
                                          )
                                        : null,
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
                          Divider(
                            height: 24,
                            color: isWizard ? Colors.white10 : null,
                          ),

                          // Network interface selector (when multiple available)
                          if (_networkInterfaces.length > 1) ...[
                            Text(
                              'Pilih Network Interface:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isWizard ? Colors.white : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedInterface,
                              dropdownColor: isWizard
                                  ? const Color(0xFF2E004B)
                                  : null,
                              style: TextStyle(
                                color: isWizard ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                enabledBorder: isWizard
                                    ? const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.white24,
                                        ),
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
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

                          Text(
                            'Beritahu siswa IP ini:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isWizard ? Colors.white : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isWizard
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isWizard
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.green.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'IP Address:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isWizard
                                              ? Colors.white70
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        _localIp!,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          color: isWizard
                                              ? Colors.greenAccent
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        'Port: 3000',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isWizard
                                              ? Colors.white70
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton.filled(
                                  onPressed: () => _copyToClipboard(_localIp!),
                                  icon: const Icon(Icons.copy),
                                  style: isWizard
                                      ? IconButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        )
                                      : null,
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
              ),
              const SizedBox(height: 24),
            ],

            // For Students: Connect to Teacher
            Text(
              isTeacher ? '🔗 Hubungkan ke Guru Lain' : '👨‍🎓 Mode Siswa',
              style: isWizard
                  ? const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cinzel',
                    )
                  : Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: isWizard
                  ? BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    )
                  : null,
              child: Card(
                color: isWizard ? Colors.transparent : null,
                elevation: isWizard ? 0 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Masukkan IP Address dari perangkat guru:',
                        style: TextStyle(
                          color: isWizard ? Colors.white70 : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _ipController,
                        style: TextStyle(
                          color: isWizard ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'IP Address Guru',
                          labelStyle: TextStyle(
                            color: isWizard ? Colors.white70 : null,
                          ),
                          hintText: '192.168.1.100',
                          hintStyle: TextStyle(
                            color: isWizard ? Colors.white30 : null,
                          ),
                          prefixIcon: Icon(
                            Icons.computer,
                            color: isWizard ? const Color(0xFFFFD700) : null,
                          ),
                          border: const OutlineInputBorder(),
                          enabledBorder: isWizard
                              ? const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                )
                              : null,
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: isWizard ? Colors.white54 : null,
                            ),
                            onPressed: () => _ipController.clear(),
                          ),
                          filled: isWizard,
                          fillColor: isWizard
                              ? Colors.white.withValues(alpha: 0.05)
                              : null,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: isWizard
                              ? FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A148C),
                                  foregroundColor: const Color(0xFFFFD700),
                                  side: const BorderSide(
                                    color: Color(0xFFFFD700),
                                  ),
                                )
                              : null,
                          onPressed: _isLoading ? null : _testConnection,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isWizard
                                        ? const Color(0xFFFFD700)
                                        : Colors.white,
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
                            color: isWizard
                                ? (_connectionSuccess
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2))
                                : (_connectionSuccess
                                      ? Colors.green.shade50
                                      : Colors.red.shade50),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isWizard
                                  ? (_connectionSuccess
                                        ? Colors.green.withValues(alpha: 0.5)
                                        : Colors.red.withValues(alpha: 0.5))
                                  : (_connectionSuccess
                                        ? Colors.green.shade200
                                        : Colors.red.shade200),
                            ),
                          ),
                          child: Text(
                            _connectionResult!,
                            style: TextStyle(
                              color: isWizard
                                  ? Colors.white
                                  : (_connectionSuccess
                                        ? Colors.green.shade700
                                        : Colors.red.shade700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Container(
              decoration: isWizard
                  ? BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    )
                  : null,
              child: Card(
                color: isWizard ? Colors.transparent : Colors.blue.shade50,
                elevation: isWizard ? 0 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isWizard
                                ? Colors.blueAccent
                                : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Petunjuk',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isWizard
                                  ? Colors.blueAccent
                                  : Colors.blue.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionItem(
                        '1',
                        'Pastikan kedua perangkat terhubung ke WiFi yang sama',
                        isWizard,
                      ),
                      _buildInstructionItem(
                        '2',
                        'Guru: Aktifkan server dan catat IP Address',
                        isWizard,
                      ),
                      _buildInstructionItem(
                        '3',
                        'Siswa: Masukkan IP guru dan tekan "Test Koneksi"',
                        isWizard,
                      ),
                      _buildInstructionItem(
                        '4',
                        'Jika berhasil, siswa dapat gabung kelas via PIN',
                        isWizard,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Network Info
            if (_localIp != null)
              Container(
                decoration: isWizard
                    ? BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      )
                    : null,
                child: Card(
                  color: isWizard ? Colors.transparent : null,
                  elevation: isWizard ? 0 : 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Info Jaringan Anda',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isWizard ? Colors.white : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('IP Address', _localIp!, isWizard),
                        _buildInfoRow(
                          'Platform',
                          Platform.operatingSystem,
                          isWizard,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Koneksi P2P',
          style: isWizard ? const TextStyle(fontFamily: 'Cinzel') : null,
        ),
        backgroundColor: isWizard ? Colors.transparent : null,
        iconTheme: isWizard ? const IconThemeData(color: Colors.white) : null,
        titleTextStyle: isWizard
            ? const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Cinzel',
                fontWeight: FontWeight.bold,
              )
            : null,
      ),
      backgroundColor: isWizard ? Colors.transparent : null,
      drawer: const AppDrawer(),
      body: isWizard ? WizardBackground(child: buildContent()) : buildContent(),
    );
  }

  Widget _buildInstructionItem(String number, String text, bool isWizard) {
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
              color: isWizard ? const Color(0xFF4A148C) : Colors.blue.shade700,
              shape: BoxShape.circle,
              border: isWizard
                  ? Border.all(color: const Color(0xFFFFD700), width: 1)
                  : null,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: isWizard ? const Color(0xFFFFD700) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: isWizard ? Colors.white70 : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isWizard) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: isWizard ? Colors.white54 : Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWizard ? Colors.white : null,
            ),
          ),
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
