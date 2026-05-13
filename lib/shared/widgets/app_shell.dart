import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../router/app_router.dart';
import '../../features/voice/conversation_intro_page.dart';
import '../../features/voice/mode_selection_page.dart';
import '../../services/conversation_service.dart';
import 'no_transition_page_route.dart';
import 'hub_nav_bar.dart';
import '../../services/prospect_storage.dart';
import 'prospect_id_provider.dart';

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
  final bool startAtModeSelection;

  const AppShell({
    super.key,
    required this.stageBucket,
    this.prospectId,
    this.dynamicVariables = const {},
    this.startAtModeSelection = false,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}


class _AppShellState extends ConsumerState<AppShell> {
  final _innerNavKey = GlobalKey<NavigatorState>();
  final _service = ConversationService();
  final _prospectStorage = ProspectStorage();
  
  String? _prospectId;
  late Map<String, dynamic> _resolvedDynamicVariables;
  bool _isHydratingReturnProspect = false;
  bool _isInitializing = false;
  bool _isHubEnabled = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _prospectId = widget.prospectId;
    _resolvedDynamicVariables = Map<String, dynamic>.from(widget.dynamicVariables);
    _isHubEnabled = widget.startAtModeSelection;
    if (_prospectId == null) {
      _initLazyProspect();
    } else {
      _hydrateReturnProspect();
    }
  }

  Future<void> _initLazyProspect() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });
    try {
      debugPrint('AppShell: Starting lazy prospect init for bucket ${widget.stageBucket}...');
      final pid = await _service.createProspect(widget.stageBucket);
      debugPrint('AppShell: Lazy prospect created successfully: $pid');
      if (mounted) {
        setState(() {
          _prospectId = pid;
        });
        await _prospectStorage.saveProspectId(pid);
      }
    } catch (e) {
      debugPrint('AppShell: Lazy prospect init failed: $e');
      if (mounted) {
        setState(() => _initError = 'Could not initialize session: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _hydrateReturnProspect() async {
    if (_prospectId == null) return;
    setState(() {
      _isHydratingReturnProspect = true;
    });
    try {
      final prospect = await _service.getProspect(_prospectId!);
      if (!mounted) return;
      setState(() {
        _resolvedDynamicVariables =
            prospect.toDynamicVariables(lockProfileFields: widget.startAtModeSelection);
        if (prospect.conversationPhase > 1) {
          _isHubEnabled = true;
        }
      });
      await _prospectStorage.saveProspectId(_prospectId!);
    } catch (e) {
      debugPrint('Return prospect hydration failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isHydratingReturnProspect = false;
        });
      }
    }
  }

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
  /// Creates a fresh prospect, then replaces the inner navigator stack with
  /// a new ConversationIntroPage.
  Future<void> _handleStartNew() async {
    final freshProspectId = await _service.createProspect(widget.stageBucket);
    if (!mounted) return;

    setState(() {
      _prospectId = freshProspectId;
      _resolvedDynamicVariables = {};
      _isHubEnabled = false;
    });
    await _prospectStorage.saveProspectId(freshProspectId);

    _innerNavKey.currentState?.pushAndRemoveUntil(
      NoTransitionPageRoute(
        builder: (_) => ConversationIntroPage(
          stageBucket: widget.stageBucket,
          prospectId: freshProspectId,
          dynamicVariables: const {},
          onStartNew: _handleStartNew,
          onFormFilled: _handleFormFilled,
          onProspectFound: _handleProspectFound,
          onGoToRelationshipHub: _handleGoToRelationshipHub,
        ),
      ),
      (_) => false, // clear the old voice/intro pages
    );
  }

  Future<void> _handleGoToRelationshipHub() async {
    final router = GoRouter.of(context);
    final path = _prospectId == null
        ? AppRoutes.relationshipHub
        : '${AppRoutes.relationshipHub}?p=${Uri.encodeComponent(_prospectId!)}';
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    router.go(path);
  }

  void _handleFormFilled() {
    setState(() => _isHubEnabled = true);
  }

  void _handleProspectFound(ProspectInitResult prospect) {
    setState(() {
      _prospectId = prospect.prospectId;
      _resolvedDynamicVariables =
          prospect.toDynamicVariables(lockProfileFields: false);
      if (prospect.conversationPhase > 1) {
        _isHubEnabled = true;
      }
    });
    _prospectStorage.saveProspectId(prospect.prospectId);
  }

  String get _initials {
    final name = _resolvedDynamicVariables['userName']?.toString() ?? 'Guest';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).toList();
    if (parts.isEmpty) return 'G';
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (_isHydratingReturnProspect || _isInitializing) {
      return ProspectIdProvider(
        prospectId: _prospectId,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(74),
            child: HubNavBar(
              companyName: _resolvedDynamicVariables['companyName']?.toString() ?? 'Launchpad',
              founderName: _resolvedDynamicVariables['userName']?.toString() ?? 'Guest',
              initials: _initials,
              activeLabel: 'Interactions',
              isHubEnabled: _isHubEnabled,
              onProfileTap: _handleProfileTap,
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  _isInitializing ? 'Preparing your session...' : 'Resuming your session...',
                  style: const TextStyle(color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_initError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initLazyProspect,
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    return ProspectIdProvider(
      prospectId: _prospectId,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: HubNavBar(
            companyName: _resolvedDynamicVariables['companyName']?.toString() ?? 'Launchpad',
            founderName: _resolvedDynamicVariables['userName']?.toString() ?? 'Guest',
            initials: _initials,
            activeLabel: 'Interactions',
            isHubEnabled: _isHubEnabled,
            onProfileTap: _handleProfileTap,
          ),
        ),
        body: Navigator(
          key: _innerNavKey,
          onGenerateInitialRoutes: (navigator, initialRoute) {
            final introRoute = NoTransitionPageRoute(
              builder: (_) => ConversationIntroPage(
                stageBucket: widget.stageBucket,
                prospectId: _prospectId,
                dynamicVariables: _resolvedDynamicVariables,
                onStartNew: _handleStartNew,
                onFormFilled: _handleFormFilled,
                onProspectFound: _handleProspectFound,
                onGoToRelationshipHub: _handleGoToRelationshipHub,
              ),
            );

            final showModeSelection = widget.startAtModeSelection || _isHubEnabled;

            if (!showModeSelection) {
              return [introRoute];
            }

            return [
              introRoute,
              NoTransitionPageRoute(
                builder: (_) => ModeSelectionPage(
                  stageBucket: widget.stageBucket,
                  prospectId: _prospectId,
                  dynamicVariables: _resolvedDynamicVariables,
                  onStartNew: _handleStartNew,
                  onGoToRelationshipHub: _handleGoToRelationshipHub,
                ),
              ),
            ];
          },
          onGenerateRoute: (settings) {
            return NoTransitionPageRoute(
              settings: settings,
              builder: (_) => ConversationIntroPage(
                stageBucket: widget.stageBucket,
                prospectId: _prospectId,
                dynamicVariables: _resolvedDynamicVariables,
                onStartNew: _handleStartNew,
                onFormFilled: _handleFormFilled,
                onProspectFound: _handleProspectFound,
                onGoToRelationshipHub: _handleGoToRelationshipHub,
              ),
            );
          },
        ),
      ),
    );
  }
}
