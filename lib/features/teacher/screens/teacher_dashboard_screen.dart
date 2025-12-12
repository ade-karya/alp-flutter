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
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = _isDesktop(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final userName = authState is Authenticated
            ? authState.user.name
            : 'Guru';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildCustomAppBar(context, isPlayful, isDesktop),
          drawer: isDesktop ? null : const AppDrawer(),
          body: Row(
            children: [
              // Permanent navigation rail for desktop
              if (isDesktop) _buildNavigationRail(context, l10n),

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
                          ? _buildDesktopLayout(context, userName, l10n)
                          : _buildMobileLayout(context, userName, l10n),
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
  Widget _buildNavigationRail(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
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
          const Divider(height: 1),
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
                  ),
                  _buildNavItem(
                    context,
                    Icons.note_add,
                    l10n.tileCreateContent,
                    onTap: () => context.push('/teacher/create-content'),
                  ),
                  _buildNavItem(
                    context,
                    Icons.library_books,
                    l10n.qbTitle,
                    onTap: () => context.push('/teacher/question-bank'),
                  ),
                  _buildNavItem(
                    context,
                    Icons.people,
                    l10n.tileManageClass,
                    onTap: () => context.push('/teacher/manage-classes'),
                  ),
                  _buildNavItem(
                    context,
                    Icons.smart_toy,
                    l10n.tileAIAssistant,
                    onTap: () => context.push('/ai-assistant'),
                  ),
                  _buildNavItem(
                    context,
                    Icons.assessment,
                    'Laporan Siswa',
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildNavItem(
                    context,
                    Icons.calendar_today,
                    'Jadwal',
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildNavItem(
                    context,
                    Icons.grade,
                    'Penilaian',
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          _buildNavItem(
            context,
            Icons.settings,
            'Pengaturan',
            onTap: () => _showComingSoon(context),
          ),
          _buildNavItem(
            context,
            Icons.logout,
            'Keluar',
            onTap: () {
              context.read<AuthCubit>().logout();
            },
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
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withAlpha(25) : null,
            border: Border(
              left: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.blue : Colors.grey[700],
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey[800],
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, userName, isDesktop: true),
        const SizedBox(height: 24),
        // Top row: Info cards and Stats
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildInfoCard(context, isDesktop: true)),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: _buildBannerSection(context, isDesktop: true),
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
              child: _buildServiceGrid(context, l10n, isDesktop: true),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildTeachingTipsSection(context, isDesktop: true),
                  const SizedBox(height: 20),
                  _buildQuickActionsSection(context, isDesktop: true),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, userName, isDesktop: false),
        const SizedBox(height: 20),
        _buildInfoCard(context, isDesktop: false),
        const SizedBox(height: 20),
        _buildBannerSection(context, isDesktop: false),
        const SizedBox(height: 10),
        _buildServiceGrid(context, l10n, isDesktop: false),
        const SizedBox(height: 20),
        _buildTeachingTipsSection(context, isDesktop: false),
        const SizedBox(height: 20),
        _buildQuickActionsSection(context, isDesktop: false),
        const SizedBox(height: 40),
      ],
    );
  }

  PreferredSizeWidget _buildCustomAppBar(
    BuildContext context,
    bool isPlayful,
    bool isDesktop,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: !isDesktop,
      iconTheme: const IconThemeData(color: Colors.black),
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari fitur, materi, siswa...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
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
        if (isDesktop) const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String userName, {
    required bool isDesktop,
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
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola kelas dan materi pembelajaran Anda',
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required bool isDesktop}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16.0),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(25),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: isDesktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistik Anda',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      ),
                      _buildInfoItemDesktop(
                        context,
                        'Total Siswa',
                        '150',
                        Icons.people,
                        Colors.orange,
                      ),
                      _buildInfoItemDesktop(
                        context,
                        'Konten',
                        '24',
                        Icons.library_books,
                        Colors.purple,
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
                  ),
                  _buildInfoItem(
                    context,
                    'Total Siswa',
                    '150',
                    Icons.people,
                    Colors.orange,
                  ),
                  _buildInfoItem(
                    context,
                    'Konten',
                    '24',
                    Icons.library_books,
                    Colors.purple,
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBannerSection(BuildContext context, {required bool isDesktop}) {
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
          const Text(
            'Fitur Unggulan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
  }) {
    final services = [
      {
        'icon': Icons.note_add,
        'id': 'create_content',
        'label': l10n.tileCreateContent,
        'color': Colors.purple,
        'route': '/teacher/create-content',
      },
      {
        'icon': Icons.library_books,
        'id': 'question_bank',
        'label': l10n.qbTitle,
        'color': Colors.teal,
        'route': '/teacher/question-bank',
      },
      {
        'icon': Icons.people,
        'id': 'manage_class',
        'label': l10n.tileManageClass,
        'color': Colors.red,
        'route': '/teacher/manage-classes',
      },
      {
        'icon': Icons.smart_toy,
        'id': 'ai_assistant',
        'label': l10n.tileAIAssistant,
        'color': Colors.indigo,
        'route': '/ai-assistant',
      },
      {
        'icon': Icons.assessment,
        'id': 'student_reports',
        'label': 'Laporan Siswa',
        'color': Colors.blue,
        'route': null,
      },
      {
        'icon': Icons.calendar_today,
        'id': 'schedule',
        'label': 'Jadwal',
        'color': Colors.orange,
        'route': null,
      },
      {
        'icon': Icons.grade,
        'id': 'grades',
        'label': 'Penilaian',
        'color': Colors.green,
        'route': null,
      },
      {
        'icon': Icons.grid_view,
        'id': 'more',
        'label': 'Lainnya',
        'color': Colors.grey,
        'route': null,
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16),
      child: Container(
        padding: isDesktop ? const EdgeInsets.all(24) : EdgeInsets.zero,
        decoration: isDesktop
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(25),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fitur Guru',
              style: TextStyle(
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 4 : 4,
                childAspectRatio: isDesktop ? 0.85 : 0.75,
                crossAxisSpacing: isDesktop ? 24 : 16,
                mainAxisSpacing: isDesktop ? 24 : 16,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return _buildServiceItem(
                  context,
                  service['icon'] as IconData,
                  service['label'] as String,
                  service['color'] as Color,
                  service['route'] as String?,
                  isDesktop: isDesktop,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    String? route, {
    required bool isDesktop,
  }) {
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
          padding: isDesktop
              ? const EdgeInsets.all(12)
              : const EdgeInsets.all(4),
          decoration: isDesktop
              ? BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withAlpha(30)),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 14 : 10),
                decoration: BoxDecoration(
                  color: isDesktop ? color.withAlpha(40) : color.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: isDesktop ? 32 : 26),
              ),
              SizedBox(height: isDesktop ? 8 : 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isDesktop ? 12 : 10,
                    fontWeight: isDesktop ? FontWeight.w500 : FontWeight.normal,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeachingTipsSection(
    BuildContext context, {
    required bool isDesktop,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: Colors.blue,
              size: isDesktop ? 40 : 32,
            ),
            SizedBox(width: isDesktop ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tips Mengajar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 18 : 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pelajari teknik mengajar yang efektif',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context, {
    required bool isDesktop,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Cepat',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            'Buat Kuis Baru',
            'Mulai buat kuis untuk siswa Anda',
            Colors.purple,
            Icons.quiz,
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            'Upload Materi',
            'Tambahkan materi pembelajaran baru',
            Colors.teal,
            Icons.upload_file,
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    IconData icon, {
    required bool isDesktop,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showComingSoon(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: isDesktop ? 90 : 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(30),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isDesktop ? 80 : 100,
                decoration: BoxDecoration(
                  color: color.withAlpha(50),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Icon(icon, color: color, size: isDesktop ? 32 : 40),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop ? 15 : 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        'Mulai Sekarang',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
