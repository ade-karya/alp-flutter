import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/network_cubit.dart';
import '../cubit/join_class_cubit.dart';
import '../cubit/join_class_state.dart';

class MyCoursesScreen extends StatelessWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JoinClassCubit(
        networkCubit: context.read<NetworkCubit>(),
        user: (context.read<AuthCubit>().state as Authenticated).user,
      ),
      child: const _MyCoursesView(),
    );
  }
}

class _MyCoursesView extends StatefulWidget {
  const _MyCoursesView();

  @override
  State<_MyCoursesView> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<_MyCoursesView> {
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final user = (context.read<AuthCubit>().state as Authenticated).user;
    if (user.id == null) return;

    final courses = await DatabaseHelper.instance.getStudentClasses(user.id!);
    if (mounted) {
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    }
  }

  void _showJoinDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.login, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Text(l10n.mcJoinDialogTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan PIN kelas yang diberikan oleh guru',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              decoration: InputDecoration(
                labelText: l10n.mcEnterPinLabel,
                hintText: '123456',
                prefixIcon: const Icon(Icons.pin),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.isNotEmpty) {
                Navigator.pop(dialogContext);
                context.read<JoinClassCubit>().joinClass(
                  pin: pinController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(l10n.mcCommonJoin),
          ),
        ],
      ),
    );
  }

  Future<void> _scanQr(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScanScreen()),
    );

    if (result != null && result is String && context.mounted) {
      try {
        final data = jsonDecode(result);
        final host = data['host'];
        final port = data['port'];
        final pin = data['pin'];

        if (host != null && port != null && pin != null) {
          context.read<JoinClassCubit>().joinClassViaQr(
            host: host,
            port: port,
            pin: pin,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format QR Code tidak valid'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membaca QR Code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<JoinClassCubit, JoinClassState>(
      listener: (context, state) {
        if (state is JoinClassSuccess) {
          _loadCourses();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.mcJoinedSuccess(state.className)),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/student/courses/${state.classId}');
        } else if (state is JoinClassFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: Text(
            l10n.mcCoursesTitle,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCourses,
            ),
          ],
        ),
        body: Stack(
          children: [
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : _courses.isEmpty
                ? _buildEmptyState(l10n)
                : _buildCourseList(l10n),
            // Loading Overlay
            BlocBuilder<JoinClassCubit, JoinClassState>(
              builder: (context, state) {
                if (state is JoinClassLoading) {
                  return Container(
                    color: Colors.black54,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.blue),
                            SizedBox(height: 16),
                            Text('Bergabung ke kelas...'),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(context),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, size: 64, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.mcNoCourses,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bergabung dengan kelas menggunakan PIN atau scan QR Code',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showJoinDialog(context),
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Input PIN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => _scanQr(context),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        final colors = [
          [Colors.blue[400]!, Colors.blue[700]!],
          [Colors.purple[400]!, Colors.purple[700]!],
          [Colors.teal[400]!, Colors.teal[700]!],
          [Colors.orange[400]!, Colors.orange[700]!],
          [Colors.pink[400]!, Colors.pink[700]!],
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
              onTap: () => context.go('/student/courses/${course['id']}'),
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
                            Icons.book,
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
                                course['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.white.withAlpha(200),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    course['teacher_name'],
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                  // Description if available
                  if (course['description'] != null &&
                      course['description'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey[500],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              course['description'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _scanQr(context),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showJoinDialog(context),
                icon: const Icon(Icons.keyboard),
                label: const Text('Input PIN'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
    returnImage: false,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto, color: Colors.white);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front, color: Colors.white);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear, color: Colors.white);
                  default:
                    return const Icon(Icons.camera, color: Colors.white);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  controller.stop();
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          // Scan overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Arahkan kamera ke QR Code kelas',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
