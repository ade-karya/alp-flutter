import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/database/database_helper.dart';
import '../models/class_model.dart';
import '../../../core/network/network_cubit.dart';

class ManageClassScreen extends StatefulWidget {
  const ManageClassScreen({super.key});

  @override
  State<ManageClassScreen> createState() => _ManageClassScreenState();
}

class _ManageClassScreenState extends State<ManageClassScreen> {
  List<ClassModel> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final user = (context.read<AuthCubit>().state as Authenticated).user;
    if (user.id == null) return;

    final classMaps = await DatabaseHelper.instance.getTeacherClasses(user.id!);
    setState(() {
      _classes = classMaps.map((m) => ClassModel.fromMap(m)).toList();
      _isLoading = false;
    });
  }

  Future<void> _createClass(String name, String description) async {
    final l10n = AppLocalizations.of(context)!;
    final user = (context.read<AuthCubit>().state as Authenticated).user;

    final rng = Random();
    String pin = '';
    for (var i = 0; i < 6; i++) {
      pin += rng.nextInt(10).toString();
    }

    try {
      await DatabaseHelper.instance.createClass(
        teacherId: user.id!,
        name: name,
        description: description,
        pin: pin,
      );
      await _loadClasses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mcSnackBarCreated(name, pin)),
            backgroundColor: Colors.green,
          ),
        );

        try {
          final newClass = _classes.firstWhere((c) => c.pin == pin);
          _showQrDialog(newClass);
        } catch (e) {
          // Class not found
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mcErrorCreating(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_circle, color: Colors.green),
            ),
            const SizedBox(width: 12),
            Text(l10n.mcDialogTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.mcClassNameLabel,
                hintText: 'contoh: Matematika Kelas 7A',
                prefixIcon: const Icon(Icons.class_),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.mcClassDescLabel,
                hintText: 'Deskripsi singkat (opsional)',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _createClass(nameController.text, descController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(l10n.commonCreate),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass(ClassModel cls) async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Hapus Kelas?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelas "${cls.name}" akan dihapus.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withAlpha(50)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Semua tugas, pendaftaran siswa, dan data terkait juga akan dihapus.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deleteClass(cls.id!);
        if (mounted) {
          _loadClasses();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kelas "${cls.name}" berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showQrDialog(ClassModel cls) {
    final networkCubit = context.read<NetworkCubit>();
    final serverIp = networkCubit.serverIp;

    if (serverIp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text('P2P Server tidak aktif. Periksa koneksi WiFi.'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final qrData = jsonEncode({
      'host': serverIp,
      'port': 3000,
      'pin': cls.pin,
      'name': cls.name,
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[700]!],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cls.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Scan untuk bergabung',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // QR Code
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(50),
                          spreadRadius: 2,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // PIN Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pin, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'PIN: ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          cls.pin,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'IP: $serverIp',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          l10n.mcTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        label: Text(l10n.mcFabCreate),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _classes.isEmpty
          ? _buildEmptyState(l10n)
          : _buildClassList(),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.class_, size: 64, color: Colors.green),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.mcNoClasses,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat kelas baru untuk mulai mengajar',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Buat Kelas Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final cls = _classes[index];
        final colors = [
          [Colors.blue[400]!, Colors.blue[700]!],
          [Colors.purple[400]!, Colors.purple[700]!],
          [Colors.teal[400]!, Colors.teal[700]!],
          [Colors.orange[400]!, Colors.orange[700]!],
        ];
        final colorPair = colors[index % colors.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(25),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/teacher/manage-classes/${cls.id}'),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colorPair),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.class_,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cls.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              if (cls.description?.isNotEmpty ?? false)
                                Text(
                                  cls.description!,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(200),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                  // Footer with actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.pin,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'PIN: ${cls.pin}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.qr_code),
                          color: Colors.blue,
                          tooltip: 'Show QR',
                          onPressed: () => _showQrDialog(cls),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          tooltip: 'Hapus Kelas',
                          onPressed: () => _deleteClass(cls),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
