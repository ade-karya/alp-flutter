import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/auth/auth_cubit.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  void _showLogoutConfirmation(BuildContext context) {
    final isWizard = context.read<ThemeCubit>().state == AppThemeMode.wizard;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isWizard ? const Color(0xFF1A1A1A) : Colors.white,
          title: Text(
            'Keluar',
            style: TextStyle(color: isWizard ? Colors.amber : Colors.black),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar?',
            style: TextStyle(color: isWizard ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: isWizard ? Colors.white54 : Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthCubit>().logout();
              },
              child: const Text(
                'Keluar Akun',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                exit(0);
              },
              child: const Text(
                'Tutup Aplikasi',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Coming Soon'),
          content: const Text('Fitur ini sedang dalam pengembangan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // Check screen layout type
  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  bool _isLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height && size.width > 500 && size.width <= 900;
  }

  bool _isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= 600;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select((ThemeCubit cubit) => cubit.state);
    final isForest = themeMode == AppThemeMode.forest;
    final isWizard = themeMode == AppThemeMode.wizard;
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = _isDesktop(context);
    final isLandscape = _isLandscape(context);
    final isTablet = _isTablet(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final userName = authState is Authenticated
            ? authState.user.name
            : 'Guru';

        Widget bodyContent;
        if (isDesktop) {
          bodyContent = _buildDesktopLayout(context, userName, l10n, isWizard);
        } else if (isLandscape || isTablet) {
          bodyContent = _buildLandscapeLayout(
            context,
            userName,
            l10n,
            isWizard,
            isTablet,
          );
        } else {
          bodyContent = _buildMobileLayout(context, userName, l10n, isWizard);
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildCustomAppBar(context, isForest, isWizard, isDesktop),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1400 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : (isLandscape ? 16 : 0),
                  vertical: isDesktop ? 24 : (isLandscape ? 16 : 0),
                ),
                child: bodyContent,
              ),
            ),
          ),
          floatingActionButton: isDesktop
              ? null
              : _buildScanFAB(context, isForest),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  // Landscape layout for Android phones and smaller tablets
  Widget _buildLandscapeLayout(
    BuildContext context,
    String userName,
    AppLocalizations l10n,
    bool isWizard,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          context,
          userName,
          isDesktop: false,
          isWizard: isWizard,
          isLandscape: true,
        ),
        const SizedBox(height: 16),
        // Two-column layout for landscape
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Stats and Quick Actions
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildInfoCard(
                    context,
                    isDesktop: false,
                    isWizard: isWizard,
                    isLandscape: true,
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActionsSection(
                    context,
                    isDesktop: false,
                    isWizard: isWizard,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right column: Services
            Expanded(
              flex: isTablet ? 2 : 1,
              child: _buildServiceGrid(
                context,
                l10n,
                isDesktop: false,
                isWizard: isWizard,
                isLandscape: true,
                isTablet: isTablet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Banner section spans full width
        _buildBannerSection(context, isDesktop: false, isWizard: isWizard),
        const SizedBox(height: 16),
        _buildTeachingTipsSection(
          context,
          isDesktop: false,
          isWizard: isWizard,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // Desktop layout with side-by-side sections
  Widget _buildDesktopLayout(
    BuildContext context,
    String userName,
    AppLocalizations l10n,
    bool isWizard,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, userName, isDesktop: true, isWizard: isWizard),
        const SizedBox(height: 24),
        // Top row: Info cards and Stats
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildInfoCard(
                context,
                isDesktop: true,
                isWizard: isWizard,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: _buildBannerSection(
                context,
                isDesktop: true,
                isWizard: isWizard,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Middle row: Service grid and Quick actions
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildServiceGrid(
                context,
                l10n,
                isDesktop: true,
                isWizard: isWizard,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildTeachingTipsSection(
                    context,
                    isDesktop: true,
                    isWizard: isWizard,
                  ),
                  const SizedBox(height: 20),
                  _buildQuickActionsSection(
                    context,
                    isDesktop: true,
                    isWizard: isWizard,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // Mobile layout (original vertical stack)
  Widget _buildMobileLayout(
    BuildContext context,
    String userName,
    AppLocalizations l10n,
    bool isWizard,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, userName, isDesktop: false, isWizard: isWizard),
        const SizedBox(height: 20),
        _buildInfoCard(context, isDesktop: false, isWizard: isWizard),
        const SizedBox(height: 20),
        _buildBannerSection(context, isDesktop: false, isWizard: isWizard),
        const SizedBox(height: 10),
        _buildServiceGrid(context, l10n, isDesktop: false, isWizard: isWizard),
        const SizedBox(height: 20),
        _buildTeachingTipsSection(
          context,
          isDesktop: false,
          isWizard: isWizard,
        ),
        const SizedBox(height: 100), // Extra padding for bottom nav
      ],
    );
  }

  PreferredSizeWidget _buildCustomAppBar(
    BuildContext context,
    bool isForest,
    bool isWizard,
    bool isDesktop,
  ) {
    return AppBar(
      backgroundColor: isWizard ? Colors.transparent : Colors.white,
      elevation: 0,
      automaticallyImplyLeading: !isDesktop,
      iconTheme: IconThemeData(
        color: isWizard ? const Color(0xFFFFD700) : Colors.black,
      ),
      title: isDesktop
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
      actions: [
        if (isDesktop) ...[
          // Search bar for desktop
          Container(
            width: 300,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isWizard
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: isWizard ? Border.all(color: Colors.white24) : null,
            ),
            child: TextField(
              style: TextStyle(color: isWizard ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Cari fitur, materi, siswa...',
                hintStyle: TextStyle(
                  color: isWizard ? Colors.white54 : Colors.grey[500],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isWizard ? Colors.white54 : Colors.grey[500],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'Profil',
          onPressed: () => context.push('/edit-profile'),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifikasi',
          onPressed: () => _showComingSoon(context),
        ),
        // Toggle theme button for demo
        IconButton(
          icon: Icon(isForest ? Icons.forest : Icons.auto_awesome),
          tooltip: 'Ganti Tema',
          onPressed: () => context.read<ThemeCubit>().toggleTheme(),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Keluar',
          onPressed: () => _showLogoutConfirmation(context),
        ),
        if (isDesktop) const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String userName, {
    required bool isDesktop,
    required bool isWizard,
    bool isLandscape = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop || isLandscape ? 0 : 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isDesktop ? 0 : 10),
          Text(
            'Selamat datang, $userName',
            style: TextStyle(
              fontSize: isDesktop ? 28 : 18,
              fontWeight: FontWeight.bold,
              color: isWizard
                  ? const Color(0xFFFFD700)
                  : Colors.black87, // Gold for wizard
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola kelas dan materi pembelajaran Anda',
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14,
              color: isWizard ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required bool isDesktop,
    required bool isWizard,
    bool isLandscape = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop || isLandscape ? 0 : 16.0,
      ),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : (isLandscape ? 20 : 16)),
        decoration: BoxDecoration(
          color: isWizard ? Colors.black.withValues(alpha: 0.4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(isWizard ? 0 : 25),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isWizard
                ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                : Colors.grey.shade100,
          ),
        ),
        child: isDesktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistik Anda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isWizard ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItemDesktop(
                        context,
                        'Total Kelas',
                        '5',
                        Icons.class_,
                        Colors.blue,
                        isWizard,
                      ),
                      _buildInfoItemDesktop(
                        context,
                        'Total Siswa',
                        '150',
                        Icons.people,
                        Colors.orange,
                        isWizard,
                      ),
                      _buildInfoItemDesktop(
                        context,
                        'Konten',
                        '24',
                        Icons.library_books,
                        Colors.purple,
                        isWizard,
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                    context,
                    'Total Kelas',
                    '5',
                    Icons.class_,
                    Colors.blue,
                    isWizard,
                  ),
                  _buildInfoItem(
                    context,
                    'Total Siswa',
                    '150',
                    Icons.people,
                    Colors.orange,
                    isWizard,
                  ),
                  _buildInfoItem(
                    context,
                    'Konten',
                    '24',
                    Icons.library_books,
                    Colors.purple,
                    isWizard,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isWizard,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isWizard ? Colors.white70 : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isWizard ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItemDesktop(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isWizard,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 32, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: isWizard ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isWizard ? Colors.white70 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSection(
    BuildContext context, {
    required bool isDesktop,
    required bool isWizard,
  }) {
    final bannerData = [
      {
        'colors': [Colors.purple[300]!, Colors.purple[600]!],
        'title': 'Buat Materi Menarik',
        'subtitle': 'Gunakan template interaktif',
        'icon': Icons.create,
      },
      {
        'colors': [Colors.teal[300]!, Colors.teal[600]!],
        'title': 'Pantau Progres Siswa',
        'subtitle': 'Lihat perkembangan belajar',
        'icon': Icons.trending_up,
      },
      {
        'colors': [Colors.orange[300]!, Colors.orange[600]!],
        'title': 'AI Assistant Guru',
        'subtitle': 'Bantuan cerdas untuk mengajar',
        'icon': Icons.smart_toy,
      },
    ];

    if (isDesktop) {
      // Desktop: Show all banners in a row
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fitur Unggulan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isWizard ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              children: bannerData.map((data) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: data == bannerData.last ? 0 : 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: data['colors'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: isWizard
                          ? Border.all(color: Colors.white24)
                          : null,
                    ),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          right: -15,
                          bottom: -15,
                          child: Icon(
                            data['icon'] as IconData,
                            size: 70,
                            color: Colors.white.withAlpha(50),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['title'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    data['subtitle'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Lihat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    // Mobile: Horizontal scrollable banners
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: bannerData.length,
        itemBuilder: (context, index) {
          final data = bannerData[index];
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: data['colors'] as List<Color>,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: isWizard ? Border.all(color: Colors.white24) : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    data['icon'] as IconData,
                    size: 120,
                    color: Colors.white.withAlpha(50),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Lihat Selengkapnya',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceGrid(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isDesktop,
    required bool isWizard,
    bool isLandscape = false,
    bool isTablet = false,
  }) {
    final services = [
      {
        'icon': Icons.note_add,
        'id': 'create_content',
        'label': l10n.tileCreateContent,
        'color': Colors.purple,
        'route': '/teacher/create-content',
        'desc': 'Buat materi baru',
      },
      {
        'icon': Icons.library_books,
        'id': 'question_bank',
        'label': l10n.qbTitle,
        'color': Colors.teal,
        'route': '/teacher/question-bank',
        'desc': 'Bank soal & kuis',
      },
      {
        'icon': Icons.people,
        'id': 'manage_class',
        'label': l10n.tileManageClass,
        'color': Colors.red,
        'route': '/teacher/manage-classes',
        'desc': 'Kelola siswa & kelas',
      },
      {
        'icon': Icons.smart_toy,
        'id': 'ai_assistant',
        'label': l10n.tileAIAssistant,
        'color': Colors.indigo,
        'route': '/ai-assistant',
        'desc': 'Bantuan AI',
      },
      {
        'icon': Icons.support_agent,
        'id': 'ai_agent',
        'label': 'AI Agent Guru',
        'color': Colors.green,
        'route': '/teacher/ai-agent',
        'desc': 'Perintah Agent',
      },
      {
        'icon': Icons.assessment,
        'id': 'student_reports',
        'label': 'Laporan Siswa',
        'color': Colors.blue,
        'route': '/teacher/reports',
        'desc': 'Analisis performa',
      },
      {
        'icon': Icons.calendar_today,
        'id': 'schedule',
        'label': 'Jadwal',
        'color': Colors.orange,
        'route': null,
        'desc': 'Kalender akademik',
      },
      {
        'icon': Icons.grade,
        'id': 'grades',
        'label': 'Penilaian',
        'color': Colors.green,
        'route': null,
        'desc': 'Input nilai',
      },
      {
        'icon': Icons.grid_view,
        'id': 'more',
        'label': 'Lainnya',
        'color': Colors.grey,
        'route': null,
        'desc': 'Fitur lainnya',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layanan Cepat',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isWizard ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop
                ? 3
                : (isTablet ? 3 : (isLandscape ? 2 : 3)),
            crossAxisSpacing: isLandscape ? 10 : 12,
            mainAxisSpacing: isLandscape ? 10 : 12,
            childAspectRatio: isDesktop
                ? 1.2
                : (isTablet ? 0.95 : (isLandscape ? 1.1 : 0.85)),
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return _buildServiceCard(
              context,
              service['label'] as String,
              service['icon'] as IconData,
              service['color'] as Color,
              service['route'] as String?,
              service['desc'] as String,
              isWizard,
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String? route,
    String desc,
    bool isWizard,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (route != null) {
            context.push(route);
          } else {
            _showComingSoon(context);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isWizard
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWizard
                  ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(isWizard ? 0 : 20),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isWizard ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: isWizard ? Colors.white70 : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeachingTipsSection(
    BuildContext context, {
    required bool isDesktop,
    required bool isWizard,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWizard
            ? const Color(0xFF4A148C).withValues(alpha: 0.3)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWizard
              ? Colors.purple.withValues(alpha: 0.3)
              : Colors.blue.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: isWizard ? Colors.amber : Colors.blue[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Tips Mengajar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isWizard ? Colors.white : Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Gunakan fitur AI Assistant untuk membuat soal latihan yang lebih variatif dan sesuai dengan kurikulum terbaru.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isWizard ? Colors.white70 : Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context, {
    required bool isDesktop,
    required bool isWizard,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWizard ? Colors.black.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWizard
              ? const Color(0xFFFFD700).withValues(alpha: 0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivitas Terbaru',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isWizard ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'Materi Matematika Bab 1',
            'Dibuat 2 jam yang lalu',
            Icons.book,
            Colors.orange,
            isWizard,
          ),
          const Divider(),
          _buildActivityItem(
            'Kuis Biologi Dasar',
            'Dibuat kemarin',
            Icons.quiz,
            Colors.green,
            isWizard,
          ),
          const Divider(),
          _buildActivityItem(
            'Kelas X-A',
            'Diupdate 2 hari lalu',
            Icons.class_,
            Colors.blue,
            isWizard,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isWizard,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isWizard ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isWizard ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: isWizard ? Colors.white30 : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  // Floating Scan Button
  Widget _buildScanFAB(BuildContext context, bool isForest) {
    return Container(
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isForest
              ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
              : [const Color(0xFFFFD700), const Color(0xFFFF8C00)],
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isForest ? const Color(0xFF2E7D32) : const Color(0xFFFFD700))
                    .withAlpha(150),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showScanOptions(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, size: 32, color: Colors.white),
      ),
    );
  }

  void _showScanOptions(BuildContext context) {
    final isWizard = context.read<ThemeCubit>().state == AppThemeMode.wizard;
    final isForest = context.read<ThemeCubit>().state == AppThemeMode.forest;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isWizard ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isForest
                  ? const Color(0xFF2E7D32).withAlpha(100)
                  : const Color(0xFFFFD700).withAlpha(100),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Scan & Akses Cepat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isWizard ? const Color(0xFFFFD700) : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan QR code atau pilih akses cepat',
                style: TextStyle(
                  fontSize: 14,
                  color: isWizard ? Colors.white54 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildScanOption(
                    context,
                    icon: Icons.qr_code_scanner,
                    label: 'Scan Kelas',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/teacher/classes');
                    },
                    isWizard: isWizard,
                  ),
                  _buildScanOption(
                    context,
                    icon: Icons.assignment,
                    label: 'Scan Tugas',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon(context);
                    },
                    isWizard: isWizard,
                  ),
                  _buildScanOption(
                    context,
                    icon: Icons.school,
                    label: 'Scan Siswa',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon(context);
                    },
                    isWizard: isWizard,
                  ),
                  _buildScanOption(
                    context,
                    icon: Icons.book,
                    label: 'Scan Materi',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon(context);
                    },
                    isWizard: isWizard,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isWizard,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isWizard ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar
}
