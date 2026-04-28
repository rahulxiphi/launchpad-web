import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../router/app_router.dart';
import '../../features/voice/conversation_intro_page.dart';
import '../../services/conversation_service.dart';
import 'top_bar.dart';

/// Prospect conversation shell — full-width, no SideNav.
///
/// The inner Navigator starts with [ConversationIntroPage] and manages the
/// conversation flow independently (intro → voice → ended state).
/// The SideNav (Matches/Sessions/Learn/Connections) is intentionally absent
/// for prospects; it will be added in the client Relationship Hub flow.
class AppShell extends ConsumerStatefulWidget {
  final String stageBucket;
  final String? prospectId;
  final Map<String, dynamic> dynamicVariables;

  const AppShell({
    super.key,
    required this.stageBucket,
    this.prospectId,
    this.dynamicVariables = const {},
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // Key for the inner navigator that owns the conversation flow.
  final _innerNavKey = GlobalKey<NavigatorState>();

  final _service = ConversationService();

  // ---------------------------------------------------------------------------
  // Auth helpers (TopBar still shows sign-in/out)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> get _authRouteExtra => {
    'stageBucket': widget.stageBucket,
  };

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
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(AppRoutes.login, extra: _authRouteExtra);
  }

  /// Called by VoicePage when the user taps "Start new session".
  /// Fetches a fresh token for the same stage + prospect, then replaces
  /// the inner navigator stack with a new ConversationIntroPage.
  Future<void> _handleStartNew() async {
    _innerNavKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ConversationIntroPage(
          stageBucket: widget.stageBucket,
          prospectId: widget.prospectId,
          dynamicVariables: widget.dynamicVariables,
          onStartNew: _handleStartNew,
        ),
      ),
      (_) => false, // clear the old voice/intro pages
    );
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
      body: Navigator(
        key: _innerNavKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ConversationIntroPage(
              stageBucket: widget.stageBucket,
              prospectId: widget.prospectId,
              dynamicVariables: widget.dynamicVariables,
              onStartNew: _handleStartNew,
            ),
          );
        },
      ),
    );
  }
}
