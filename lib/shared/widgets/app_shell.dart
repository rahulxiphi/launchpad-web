import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../features/coming_soon/coming_soon_page.dart';
import '../../router/app_router.dart';
import '../../features/voice/conversation_intro_page.dart';
import '../../services/conversation_service.dart';
import 'side_nav.dart';
import 'top_bar.dart';

const _featureNames = {
  1: 'Matches',
  2: 'Sessions',
  3: 'Learn',
  4: 'Connections',
};

/// Persistent application shell: TopBar + SideNav + inner Navigator body.
///
/// The inner Navigator starts with [ConversationIntroPage] and manages the
/// conversation flow independently (intro → voice → ended state).
/// Unauthenticated users are sent to login, while signed-in users see
/// temporary coming-soon pages for unbuilt sections.
class AppShell extends ConsumerStatefulWidget {
  final String conversationToken;
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;

  const AppShell({
    super.key,
    required this.conversationToken,
    required this.stageBucket,
    this.prospectId,
    this.dynamicVariables = const {},
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // Chat (0) is always the active nav item in Phase 0.
  int _selectedNavIndex = 0;

  // Key for the inner navigator that owns the conversation flow.
  final _innerNavKey = GlobalKey<NavigatorState>();

  final _service = ConversationService();

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> get _authRouteExtra => {
    'stageBucket': widget.stageBucket,
  };

  void _handleNavTap(int index) {
    if (index == 0) return; // Already on Chat — no-op.
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final featureName = _featureNames[index] ?? 'This feature';

    if (isAuthenticated) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => ComingSoonPage(featureName: featureName),
        ),
      );
      return;
    }

    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(AppRoutes.login, extra: _authRouteExtra);
  }

  void _handleSignIn() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(AppRoutes.login, extra: _authRouteExtra);
  }

  Future<void> _handleSignOut() async {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    await ref.read(authNotifierProvider.notifier).logout();
    router.go(AppRoutes.home);
  }

  void _handleProfileTap() {
    if (ref.read(isAuthenticatedProvider)) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => const ComingSoonPage(featureName: 'Profile'),
        ),
      );
      return;
    }

    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(AppRoutes.login, extra: _authRouteExtra);
  }

  /// Called by VoicePage when the user taps "Start new session".
  /// Fetches a fresh token for the same stage + prospect, then replaces
  /// the inner navigator stack with a new ConversationIntroPage.
  Future<void> _handleStartNew() async {
    try {
      final result = await _service.getVoiceToken(
        widget.stageBucket,
        prospectId: widget.prospectId,
      );
      if (!mounted) return;
      _innerNavKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ConversationIntroPage(
            conversationToken: result.conversationToken,
            stageBucket: result.stageBucket,
            prospectId: result.prospectId,
            dynamicVariables: result.dynamicVariables,
            onStartNew: _handleStartNew,
          ),
        ),
        (_) => false, // clear the old voice/intro pages
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restart session: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      appBar: AppTopBar(
        onSignIn: _handleSignIn,
        onSignOut: _handleSignOut,
        onProfileTap: _handleProfileTap,
        isAuthenticated: isAuthenticated,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Side navigation ───────────────────────────────────────────────
          SideNav(
            selectedIndex: _selectedNavIndex,
            onNavTap: _handleNavTap,
            onSignIn: _handleSignIn,
            onSignOut: _handleSignOut,
            isAuthenticated: isAuthenticated,
          ),

          // ── Inner navigator (conversation flow) ───────────────────────────
          Expanded(
            child: Navigator(
              key: _innerNavKey,
              onGenerateRoute: (settings) {
                // Initial route: conversation intro page.
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => ConversationIntroPage(
                    conversationToken: widget.conversationToken,
                    stageBucket: widget.stageBucket,
                    prospectId: widget.prospectId,
                    dynamicVariables: widget.dynamicVariables,
                    onStartNew: _handleStartNew,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
