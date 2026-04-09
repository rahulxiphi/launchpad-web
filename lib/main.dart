import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_provider.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: LaunchPadApp()));
}

class LaunchPadApp extends ConsumerStatefulWidget {
  const LaunchPadApp({super.key});

  @override
  ConsumerState<LaunchPadApp> createState() => _LaunchPadAppState();
}

class _LaunchPadAppState extends ConsumerState<LaunchPadApp> {
  late final RouterRefreshNotifier _routerNotifier;
  late final _router;

  @override
  void initState() {
    super.initState();
    _routerNotifier = RouterRefreshNotifier();
    _router = createRouter(
      refreshNotifier: _routerNotifier,
      isAuthenticated: () => ref.read(isAuthenticatedProvider),
    );
    // Restore session from secure storage silently on first launch
    Future.microtask(
      () => ref.read(authNotifierProvider.notifier).tryAutoLogin(),
    );
  }

  @override
  void dispose() {
    _routerNotifier.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Drive GoRouter refresh whenever auth state changes.
    // ref.listen is safe here — called during build.
    ref.listen<bool>(isAuthenticatedProvider, (_, __) {
      _routerNotifier.notify();
    });

    return MaterialApp.router(
      title: 'LaunchPad',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A56DB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
    );
  }
}
