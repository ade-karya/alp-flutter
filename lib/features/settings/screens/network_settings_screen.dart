import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alp/core/network/network_cubit.dart';
import 'package:alp/core/auth/auth_cubit.dart';
import 'package:alp/core/auth/models/user_model.dart';

import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/wizard_background.dart';

class NetworkSettingsScreen extends StatefulWidget {
  const NetworkSettingsScreen({super.key});

  @override
  State<NetworkSettingsScreen> createState() => _NetworkSettingsScreenState();
}

class _NetworkSettingsScreenState extends State<NetworkSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh interfaces when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        final user = authState.user;
        // For students, start discovery to populate interfaces/IP
        if (user.role == UserRole.student) {
          context.read<NetworkCubit>().start(user);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWizard = context.watch<ThemeCubit>().state == AppThemeMode.wizard;

    Widget buildContent() {
      return BlocBuilder<NetworkCubit, NetworkState>(
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
              Text(
                'Pengaturan Network',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isWizard ? Colors.white : Colors.black87,
                  fontFamily: isWizard ? 'Cinzel' : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isTeacher
                    ? 'Konfigurasi server kelas dan jaringan untuk koneksi siswa.'
                    : 'Informasi status koneksi jaringan.',
                style: TextStyle(
                  fontSize: 16,
                  color: isWizard ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Teacher Controls
              if (isTeacher) ...[
                // Server Toggle
                Container(
                  decoration: isWizard
                      ? BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        )
                      : null,
                  child: Card(
                    elevation: isWizard ? 0 : 0,
                    color: isWizard ? Colors.transparent : Colors.grey[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isWizard
                          ? BorderSide.none
                          : BorderSide(color: Colors.grey.shade200),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'Aktifkan Server Kelas',
                        style: TextStyle(
                          color: isWizard ? Colors.white : null,
                          fontWeight: isWizard
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontFamily: isWizard ? 'Cinzel' : null,
                        ),
                      ),
                      subtitle: Text(
                        isRunning
                            ? 'Server berjalan. Siswa dapat melihat kelas.'
                            : 'Server mati. QR Code tidak akan berfungsi.',
                        style: TextStyle(
                          color: isWizard ? Colors.white70 : null,
                        ),
                      ),
                      value: isRunning,
                      activeThumbColor: isWizard
                          ? const Color(0xFFFFD700)
                          : null,
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
                ),
                const SizedBox(height: 16),

                // Interface Selection
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Text(
                    'Network Interface (IP Address)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isWizard ? Colors.white : null,
                      fontFamily: isWizard ? 'Cinzel' : null,
                    ),
                  ),
                ),
                Container(
                  decoration: isWizard
                      ? BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        )
                      : null,
                  child: Card(
                    elevation: isWizard ? 0 : 0,
                    color: isWizard ? Colors.transparent : Colors.grey[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isWizard
                          ? BorderSide.none
                          : BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih IP yang digunakan untuk QR Code:',
                            style: TextStyle(
                              color: isWizard ? Colors.white54 : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (interfaces.isNotEmpty)
                            InputDecorator(
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
                                  vertical: 4,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  dropdownColor: isWizard
                                      ? const Color(0xFF2E004B)
                                      : null,
                                  value:
                                      currentIp != null &&
                                          interfaces.any(
                                            (i) => i['ip'] == currentIp,
                                          )
                                      ? currentIp
                                      : (interfaces.isNotEmpty
                                            ? interfaces.first['ip']
                                            : null),
                                  style: TextStyle(
                                    color: isWizard
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
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
                                  hint: Text(
                                    'Pilih IP Address',
                                    style: TextStyle(
                                      color: isWizard ? Colors.white54 : null,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange,
                                  ),
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
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Tips: Gunakan IP Hotspot atau WiFi jika Virtual Adapters tidak bekerja.',
                    style: TextStyle(
                      color: isWizard ? Colors.white54 : Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              // Student View
              if (!isTeacher) ...[
                Card(
                  elevation: 0,
                  color: isWizard
                      ? const Color(0xFF4A148C).withValues(alpha: 0.5)
                      : Colors.blue[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isWizard
                          ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                          : Colors.blue.shade100,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.wifi,
                          size: 48,
                          color: isWizard
                              ? const Color(0xFFFFD700)
                              : Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Koneksi Siswa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isWizard ? Colors.white : null,
                            fontFamily: isWizard ? 'Cinzel' : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sebagai siswa, kamu tidak perlu mengatur server. Cukup pindai QR Code dari gurumu untuk terhubung ke kelas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isWizard ? Colors.white70 : Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // IP Address Display for Student
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isWizard
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isWizard
                                  ? Colors.white24
                                  : Colors.blue.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IP Address Kamu:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isWizard
                                      ? Colors.white54
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (interfaces.isNotEmpty)
                                ...interfaces.map(
                                  (i) => Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.computer,
                                          size: 16,
                                          color: isWizard
                                              ? const Color(0xFFFFD700)
                                              : Colors.blue[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${i['ip']} (${i['name']})',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isWizard
                                                ? Colors.white
                                                : Colors.blue[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  'Mendeteksi IP...',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: isWizard
                                        ? Colors.white38
                                        : Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: isWizard ? Colors.transparent : Colors.white,
      appBar: AppBar(
        backgroundColor: isWizard ? Colors.transparent : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isWizard ? Colors.white : Colors.black),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isWizard ? const Color(0xFF4A148C) : Colors.red[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                border: isWizard
                    ? Border.all(color: const Color(0xFFFFD700))
                    : null,
              ),
              child: Text(
                'Sikolah',
                style: TextStyle(
                  color: isWizard ? const Color(0xFFFFD700) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: isWizard ? 'Cinzel' : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isWizard ? const Color(0xFFFFD700) : Colors.green[700],
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                'Apps',
                style: TextStyle(
                  color: isWizard ? const Color(0xFF4A148C) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: isWizard ? 'Cinzel' : null,
                ),
              ),
            ),
          ],
        ),
      ),
      body: isWizard ? WizardBackground(child: buildContent()) : buildContent(),
    );
  }
}
