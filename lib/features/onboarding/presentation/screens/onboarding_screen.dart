import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_cubit.dart';
import '../../../../l10n/arb/app_localizations.dart';
import 'package:alp/features/shared/widgets/language_selector.dart';

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
    final List<_OnboardingPage> pages = [
      _OnboardingPage(
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDesc1,
        icon: Icons.auto_awesome,
        color: Colors.blueAccent,
      ),
      _OnboardingPage(
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
        icon: Icons.insights,
        color: Colors.purpleAccent,
      ),
      _OnboardingPage(
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDesc3,
        icon: Icons.people,
        color: Colors.orangeAccent,
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [LanguageSelector(), SizedBox(width: 16)],
      ),
      body: Stack(
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
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withAlpha(100), // Updated for deprecation
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
                    label: Text(l10n.buttonNext),
                    icon: const Icon(Icons.arrow_forward),
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
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.buttonBack),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
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

    final iconWidget = Container(
      padding: EdgeInsets.all(isLandscape ? 20 : 32),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
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
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isLandscape ? 8 : 16),
        Text(
          description,
          style: TextStyle(fontSize: isLandscape ? 14 : 16, color: Colors.grey),
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

    // Icon with gradient
    final iconWidget = Container(
      padding: EdgeInsets.all(isLandscape ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(80),
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
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isLandscape ? 8 : 12),
        Text(
          l10n.onboardingJoinCommunity,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isLandscape ? 12 : 14,
            color: Colors.grey.shade600,
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
              icon: const Icon(Icons.login),
              label: Text(l10n.loginButton),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
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
            icon: const Icon(Icons.person_add),
            label: Text(l10n.registerButton),
            style: FilledButton.styleFrom(
              backgroundColor: hasUsers
                  ? Colors.grey.shade600
                  : Colors.blue.shade600,
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
                color: Colors.grey.shade200,
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
