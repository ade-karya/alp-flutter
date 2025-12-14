import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:alp/l10n/arb/app_localizations.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/widgets/app_drawer.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
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

  // Check if running on desktop/wide screen
  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isPlayful = context.select(
      (ThemeCubit cubit) => cubit.state == AppThemeMode.playful,
    );
    final isWizard = context.select(
      (ThemeCubit cubit) => cubit.state == AppThemeMode.wizard,
    );
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = _isDesktop(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final userName = authState is Authenticated
            ? authState.user.name
            : 'Guru';

        return Scaffold(
          backgroundColor: isWizard ? Colors.transparent : Colors.white,
          appBar: _buildCustomAppBar(context, isPlayful, isWizard, isDesktop),
          drawer: isDesktop ? null : const AppDrawer(),
          body: Row(
            children: [
              // Permanent navigation rail for desktop
              if (isDesktop) _buildNavigationRail(context, l10n, isWizard),

              // Main content
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1400 : double.infinity,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 0,
                        vertical: isDesktop ? 24 : 0,
                      ),
                      child: isDesktop
                          ? _buildDesktopLayout(
                              context,
                              userName,
                              l10n,
                              isWizard,
                            )
                          : _buildMobileLayout(
                              context,
                              userName,
                              l10n,
                              isWizard,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Navigation Rail for desktop
  Widget _buildNavigationRail(
    BuildContext context,
    AppLocalizations l10n,
    bool isWizard,
  ) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isWizard
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[50],
        border: Border(
          right: BorderSide(
            color: isWizard ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
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
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
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
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: isWizard ? Colors.white10 : Colors.grey),
          const SizedBox(height: 10),
          // Navigation items - scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavItem(
                    context,
                    Icons.dashboard,
                    'Dashboard',
                    isSelected: true,
                    onTap: () {},
                    isWizard: isWizard,
                  ),
                  _buildNavItem(
                    context,
                    Icons.note_add,
                    l10n.tileCreateContent,
                    onTap: () => context.push('/teacher/create-content'),
                    isWizard: isWizard,
                  ),
                  _buildNavItem(
                    context,
                    Icons.library_books,
                    l10n.qbTitle,
                    onTap: () => context.push('/teacher/question-bank'),
                    isWizard: isWizard,
                  ),
                  _buildNavItem(
                    context,
                    Icons.people,
                    l10n.tileManageClass,
                    onTap: () => context.push('/teacher/manage-classes'),
                    isWizard: isWizard,
                  ),
                  _buildNavItem(
                    context,
                    Icons.smart_toy,
                    l10n.tileAIAssistant,
                    onTap: () => context.push('/ai-assistant'),
                    isWizard: isWizard,
                  ),
                  _buildNavItem(
                    context,
                    Icons.assessment,
                    'Laporan Siswa',
                    onTap: () => _showComingSoon(context),
                    isWizard: isWizard,
                  ),
                  _buildNavItem(
                    context,
                    Icons.calendar_today,
                    'Jadwal',
                    onTap: () => _showComingSoon(context),
                    isWizard: isWizard,
                  ),
                  _buildNavItem(
                    context,
                    Icons.grade,
                    'Penilaian',
                    onTap: () => _showComingSoon(context),
                    isWizard: isWizard,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: isWizard ? Colors.white10 : Colors.grey),
          _buildNavItem(
            context,
            Icons.settings,
            'Pengaturan',
            onTap: () => _showComingSoon(context),
            isWizard: isWizard,
          ),
          _buildNavItem(
            context,
            Icons.logout,
            'Keluar',
            onTap: () {
              context.read<AuthCubit>().logout();
            },
            isWizard: isWizard,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label, {
    bool isSelected = false,
    required VoidCallback onTap,
    required bool isWizard,
  }) {
    final selectedColor = isWizard
        ? const Color(0xFFFFD700)
        : Colors.blue; // Gold for wizard
    final unselectedColor = isWizard ? Colors.white70 : Colors.grey[700];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor.withAlpha(25) : null,
            border: Border(
              left: BorderSide(
                color: isSelected ? selectedColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? selectedColor
                      : (isWizard ? Colors.white : Colors.grey[800]),
                ),
              ),
            ],
          ),
        ),
      ),
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
        const SizedBox(height: 20),
        _buildQuickActionsSection(
          context,
          isDesktop: false,
          isWizard: isWizard,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  PreferredSizeWidget _buildCustomAppBar(
    BuildContext context,
    bool isPlayful,
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
          onPressed: () => _showComingSoon(context),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifikasi',
          onPressed: () => _showComingSoon(context),
        ),
        // Toggle theme button for demo
        IconButton(
          icon: Icon(isWizard ? Icons.auto_awesome : Icons.palette_outlined),
          tooltip: 'Ganti Tema',
          onPressed: () => context.read<ThemeCubit>().toggleTheme(),
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
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16.0),
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
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16.0),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
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
            height: 160,
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
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            data['icon'] as IconData,
                            size: 100,
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
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['subtitle'] as String,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
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
                                  'Lihat',
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
        'icon': Icons.assessment,
        'id': 'student_reports',
        'label': 'Laporan Siswa',
        'color': Colors.blue,
        'route': null,
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
            crossAxisCount: isDesktop ? 2 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 1.5 : 1.1,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isWizard ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: isWizard ? Colors.white70 : Colors.grey[600],
                  ),
                  maxLines: 2,
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
}
