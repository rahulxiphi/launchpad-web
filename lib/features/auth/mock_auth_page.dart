import 'package:flutter/material.dart';

/// Placeholder auth page shown when an unauthenticated user taps a nav item
/// that requires sign-in.
///
/// [featureName] — the human-readable name of the feature they tried to open
///                 (e.g. "Matches", "Catalog"). Shown in the heading.
class MockAuthPage extends StatelessWidget {
  final String featureName;

  const MockAuthPage({super.key, required this.featureName});

  void _showComingSoon(BuildContext context, String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$method — coming soon!'),
        behavior: SnackBarBehavior.floating,
        width: 320,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 36,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 28),

                // Heading
                Text(
                  'Sign in to access $featureName',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtext
                Text(
                  'Create a free account or sign in to unlock matches, '
                  'sessions, the learn hub, and your startup profile.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Continue with Google
                FilledButton.icon(
                  onPressed: () => _showComingSoon(context, 'Google sign-in'),
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
                  label: const Text('Continue with Google'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sign in with email
                OutlinedButton.icon(
                  onPressed: () => _showComingSoon(context, 'Email sign-in'),
                  icon: const Icon(Icons.mail_outline_rounded, size: 18),
                  label: const Text('Sign in with Email'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: colorScheme.outline),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Footer note
                Text(
                  'You can still use Chat without signing in.',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
