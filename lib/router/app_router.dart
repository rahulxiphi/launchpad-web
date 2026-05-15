import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/landing_jpmc/jpmc_startups_clone_page.dart';
import '../features/relationship_hub/relationship_hub_page.dart';
import '../features/stage_selector/stage_selector_page.dart';
import '../shared/widgets/app_shell.dart';

// ── Route paths ───────────────────────────────────────────────────────────────

class AppRoutes {
  static const login = '/login';
  static const signup = '/signup';
  static const stageSelector = '/stages';
  static const relationshipHub = '/relationship-hub';
  static const home = '/';
}

/// Simple [ChangeNotifier] owned by the root widget and notified whenever
/// auth state changes. Passed to [GoRouter.refreshListenable] so redirects
/// are re-evaluated on every login / logout.
class RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

// ── Router factory ────────────────────────────────────────────────────────────

/// [refreshNotifier] — the [RouterRefreshNotifier] owned by the root widget.
/// [isAuthenticated] — reads current auth state (via `ref.read`).
GoRouter createRouter({
  required RouterRefreshNotifier refreshNotifier,
  required bool Function() isAuthenticated,
}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authed = isAuthenticated();
      final isOnAuth =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;

      if (authed && isOnAuth) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SignupPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.stageSelector,
        pageBuilder: (context, state) {
          final invitationCode = state.uri.queryParameters['invite'];
          final returnProspectId = state.uri.queryParameters['p'];
          return NoTransitionPage(
            child: StageSelectorPage(
              invitationCode: invitationCode,
              returnProspectId: returnProspectId,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) {
          final invitationCode = state.uri.queryParameters['invite'];
          final returnProspectId = state.uri.queryParameters['p'];
          return NoTransitionPage(
            child: JpmcStartupsClonePage(
              invitationCode: invitationCode,
              returnProspectId: returnProspectId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/p=:prospectId',
        pageBuilder: (context, state) {
          final prospectId = state.pathParameters['prospectId'];
          final mode = state.uri.queryParameters['mode'];
          return NoTransitionPage(
            child: AppShell(
              stageBucket: 'super_agent',
              prospectId: prospectId,
              startAtModeSelection: true,
              initialConversationMode: mode,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.relationshipHub,
        pageBuilder: (context, state) {
          final prospectId = state.uri.queryParameters['p'];
          return NoTransitionPage(
            child: RelationshipHubPage(
              prospectId: prospectId,
            ),
          );
        },
      ),
    ],
  );
}
