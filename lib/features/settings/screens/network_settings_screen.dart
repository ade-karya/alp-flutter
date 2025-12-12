import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alp/core/network/network_cubit.dart';
import 'package:alp/core/auth/auth_cubit.dart';
import 'package:alp/core/auth/models/user_model.dart';

class NetworkSettingsScreen extends StatelessWidget {
  const NetworkSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: const Text(
                'Sikolah',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: const Text(
                'Apps',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<NetworkCubit, NetworkState>(
        builder: (context, state) {
          final cubit = context.read<NetworkCubit>();
          final authState = context.read<AuthCubit>().state;
          // Determine currentUser role
          final user = (authState is Authenticated) ? authState.user : null;
          final isTeacher = user?.role == UserRole.teacher;

          final isRunning = cubit.isServerRunning;
          final currentIp = cubit.serverIp;
          final interfaces = cubit.availableInterfaces;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Pengaturan Network',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isTeacher
                    ? 'Konfigurasi server kelas dan jaringan untuk koneksi siswa.'
                    : 'Informasi status koneksi jaringan.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Teacher Controls
              if (isTeacher) ...[
                // Server Toggle
                Card(
                  elevation: 0,
                  color: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: SwitchListTile(
                    title: const Text('Aktifkan Server Kelas'),
                    subtitle: Text(
                      isRunning
                          ? 'Server berjalan. Siswa dapat melihat kelas.'
                          : 'Server mati. QR Code tidak akan berfungsi.',
                    ),
                    value: isRunning,
                    onChanged: (val) {
                      if (user != null) {
                        cubit.toggleServer(val, user);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: User tidak ditemukan'),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Interface Selection
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    'Network Interface (IP Address)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Card(
                  elevation: 0,
                  color: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih IP yang digunakan untuk QR Code:',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        if (interfaces.isNotEmpty)
                          InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value:
                                    currentIp != null &&
                                        interfaces.any(
                                          (i) => i['ip'] == currentIp,
                                        )
                                    ? currentIp
                                    : (interfaces.isNotEmpty
                                          ? interfaces.first['ip']
                                          : null),
                                items: interfaces.map((i) {
                                  return DropdownMenuItem<String>(
                                    value: i['ip'],
                                    child: Text('${i['name']} (${i['ip']})'),
                                  );
                                }).toList(),
                                onChanged: isRunning
                                    ? (val) {
                                        if (val != null) {
                                          cubit.selectInterface(val);
                                        }
                                      }
                                    : null, // Disable if server is off
                                hint: const Text('Pilih IP Address'),
                              ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tidak ada interface network terdeteksi. Pastikan WiFi aktif.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Tips: Gunakan IP Hotspot atau WiFi jika Virtual Adapters tidak bekerja.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              // Student View
              if (!isTeacher) ...[
                Card(
                  elevation: 0,
                  color: Colors.blue[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade100),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(Icons.wifi, size: 48, color: Colors.blue),
                        const SizedBox(height: 16),
                        const Text(
                          'Koneksi Siswa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sebagai siswa, kamu tidak perlu mengatur server. Cukup pindai QR Code dari gurumu untuk terhubung ke kelas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.blue[900]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
