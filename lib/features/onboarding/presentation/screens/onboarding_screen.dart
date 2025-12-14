import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_cubit.dart';
import '../../../../l10n/arb/app_localizations.dart';
import 'package:alp/features/shared/widgets/language_selector.dart';
import '../../../../core/theme/app_themes.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/wizard_background.dart';

// Helper for enabling mouse drag
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding(String route) async {
    final authCubit = context.read<AuthCubit>();

    // 1. Navigate to target first (while still in OnboardingRequired state)
    // Router allows /login and /register during OnboardingRequired
    if (mounted) context.go(route);

    // 2. Complete onboarding after navigation (just saves the flag)
    // This no longer triggers router refresh
    await authCubit.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    final isWizard = context.watch<ThemeCubit>().state == AppThemeMode.wizard;

    final List<_OnboardingPage> pages = [
      _OnboardingPage(
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDesc1,
        icon: Icons.auto_awesome,
        color: isWizard ? Colors.blueAccent : Colors.blueAccent,
      ),
      _OnboardingPage(
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
        icon: Icons.insights,
        color: isWizard ? Colors.deepPurpleAccent : Colors.purpleAccent,
      ),
      _OnboardingPage(
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDesc3,
        icon: Icons.people,
        color: isWizard ? Colors.amberAccent : Colors.orangeAccent,
      ),
    ];

    Widget buildContent() {
      return Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length + 1, // +1 for the final login/register page
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              if (index < pages.length) {
                return _OnboardingPage(
                  title: pages[index].title,
                  description: pages[index].description,
                  icon: pages[index].icon,
                  color: pages[index].color,
                );
              } else {
                // Use BlocBuilder to get hasUsers from OnboardingRequired state
                return BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final hasUsers = state is OnboardingRequired
                        ? state.hasUsers
                        : false;
                    return _FinalPage(
                      onAction: _completeOnboarding,
                      hasUsers: hasUsers,
                    );
                  },
                );
              }
            },
          ),
          // Dot Indicator
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length + 1,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? (isWizard
                              ? const Color(0xFFFFD700)
                              : Theme.of(context).primaryColor)
                        : (isWizard
                              ? Colors.white24
                              : Colors.grey.withAlpha(100)),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 32,
            child: _currentPage < pages.length
                ? FilledButton.icon(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    label: Text(
                      l10n.buttonNext,
                      style: TextStyle(
                        fontFamily: isWizard ? 'Cinzel' : null,
                        fontWeight: isWizard ? FontWeight.bold : null,
                        color: isWizard ? const Color(0xFF4A148C) : null,
                      ),
                    ),
                    icon: Icon(
                      Icons.arrow_forward,
                      color: isWizard ? const Color(0xFF4A148C) : null,
                    ),
                    style: isWizard
                        ? FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                          )
                        : null,
                  )
                : const SizedBox.shrink(),
          ),
          Positioned(
            bottom: 40,
            left: 32,
            child: _currentPage > 0 && _currentPage < pages.length
                ? TextButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: isWizard ? Colors.white70 : null,
                    ),
                    label: Text(
                      l10n.buttonBack,
                      style: TextStyle(
                        color: isWizard ? Colors.white70 : null,
                        fontFamily: isWizard ? 'Cinzel' : null,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isWizard ? Colors.transparent : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [LanguageSelector(), SizedBox(width: 16)],
        iconTheme: IconThemeData(color: isWizard ? Colors.white : Colors.black),
      ),
      body: isWizard ? WizardBackground(child: buildContent()) : buildContent(),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isWizard = context.watch<ThemeCubit>().state == AppThemeMode.wizard;

    final iconWidget = Container(
      padding: EdgeInsets.all(isLandscape ? 20 : 32),
      decoration: BoxDecoration(
        color: isWizard ? color.withValues(alpha: 0.2) : color.withAlpha(30),
        shape: BoxShape.circle,
        border: isWizard
            ? Border.all(color: color.withValues(alpha: 0.5))
            : null,
        boxShadow: isWizard
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
      child: Icon(icon, size: isLandscape ? 60 : 100, color: color),
    );

    final textWidget = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isLandscape ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: isWizard ? Colors.white : Colors.black87,
            fontFamily: isWizard ? 'Cinzel' : null,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isLandscape ? 8 : 16),
        Text(
          description,
          style: TextStyle(
            fontSize: isLandscape ? 14 : 16,
            color: isWizard ? Colors.white70 : Colors.grey,
            fontFamily: isWizard ? 'Lato' : null,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isLandscape ? 16.0 : 32.0),
        child: isLandscape
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  const SizedBox(width: 32),
                  Expanded(child: textWidget),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [iconWidget, const SizedBox(height: 64), textWidget],
              ),
      ),
    );
  }
}

class _FinalPage extends StatelessWidget {
  final Function(String) onAction;
  final bool hasUsers;

  const _FinalPage({required this.onAction, required this.hasUsers});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWizard = context.watch<ThemeCubit>().state == AppThemeMode.wizard;

    // Icon with gradient
    final iconWidget = Container(
      padding: EdgeInsets.all(isLandscape ? 16 : 24),
      decoration: BoxDecoration(
        gradient: isWizard
            ? const LinearGradient(
                colors: [Color(0xFF4A148C), Color(0xFFFFD700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isWizard
                ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                : Colors.blue.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.school,
        size: isLandscape ? 48 : 64,
        color: Colors.white,
      ),
    );

    // Text content
    final textContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.onboardingGetStarted,
          style: TextStyle(
            fontSize: isLandscape ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: isWizard ? Colors.white : Colors.black87,
            fontFamily: isWizard ? 'Cinzel' : null,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isLandscape ? 8 : 12),
        Text(
          l10n.onboardingJoinCommunity,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isLandscape ? 12 : 14,
            color: isWizard ? Colors.white70 : Colors.grey.shade600,
            fontFamily: isWizard ? 'Lato' : null,
          ),
        ),
      ],
    );

    // Styled buttons - conditionally show based on hasUsers
    final buttons = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Only show Login button if there are existing users
        if (hasUsers) ...[
          SizedBox(
            width: isLandscape ? 200 : double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => onAction('/login'),
              icon: Icon(
                Icons.login,
                color: isWizard ? const Color(0xFFFFD700) : null,
              ),
              label: Text(
                l10n.loginButton,
                style: TextStyle(
                  color: isWizard ? const Color(0xFFFFD700) : null,
                  fontFamily: isWizard ? 'Cinzel' : null,
                  fontWeight: isWizard ? FontWeight.bold : null,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isWizard
                    ? const Color(0xFF4A148C)
                    : Colors.blue.shade600,
                side: isWizard
                    ? const BorderSide(color: Color(0xFFFFD700))
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Register button is always shown (primary for fresh install)
        SizedBox(
          width: isLandscape ? 200 : double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () => onAction('/register'),
            icon: Icon(
              Icons.person_add,
              color: isWizard ? const Color(0xFF4A148C) : Colors.white,
            ),
            label: Text(
              l10n.registerButton,
              style: TextStyle(
                color: isWizard ? const Color(0xFF4A148C) : Colors.white,
                fontFamily: isWizard ? 'Cinzel' : null,
                fontWeight: isWizard ? FontWeight.bold : null,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: hasUsers
                  ? (isWizard ? Colors.white70 : Colors.grey.shade600)
                  : (isWizard ? const Color(0xFFFFD700) : Colors.blue.shade600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );

    if (isLandscape) {
      // Landscape: horizontal split layout
      return SafeArea(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconWidget,
                    const SizedBox(height: 16),
                    textContent,
                  ],
                ),
              ),
              Container(
                width: 1,
                height: screenHeight * 0.5,
                color: isWizard ? Colors.white24 : Colors.grey.shade200,
              ),
              Expanded(child: Center(child: buttons)),
            ],
          ),
        ),
      );
    }

    // Portrait: vertical layout
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight - 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(height: 24),
              textContent,
              const SizedBox(height: 48),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: buttons,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
