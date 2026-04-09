import 'package:flutter/material.dart';

/// Top application bar shown across all shell pages.
/// Height: 64 px (implements PreferredSizeWidget).
///
/// Left  : ⚡ LaunchPad wordmark
/// Right : notification bell (placeholder) + profile icon + "Sign In" outlined button
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Called when the user taps "Sign In" in the top bar.
  final VoidCallback onSignIn;

  /// Called when the user taps "Sign Out" in the top bar.
  final VoidCallback? onSignOut;

  /// Called when the user taps the profile avatar icon.
  final VoidCallback onProfileTap;

  /// Controls whether the auth action renders as Sign In or Sign Out.
  final bool isAuthenticated;

  const AppTopBar({
    super.key,
    required this.onSignIn,
    this.onSignOut,
    required this.onProfileTap,
    this.isAuthenticated = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      title: Row(
        children: [
          Icon(
            Icons.bolt_rounded,
            color: colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 6),
          Text(
            'LaunchPad',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        // Notification bell — placeholder, no action yet
        IconButton(
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: false,
            child: Icon(
              Icons.notifications_none_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          onPressed: () {},
        ),
        // Profile avatar icon
        IconButton(
          tooltip: 'Profile',
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              size: 18,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          onPressed: onProfileTap,
        ),
        const SizedBox(width: 4),
        OutlinedButton.icon(
          onPressed: isAuthenticated ? onSignOut : onSignIn,
          icon: Icon(
            isAuthenticated ? Icons.logout_rounded : Icons.login_rounded,
            size: 16,
          ),
          label: Text(isAuthenticated ? 'Sign Out' : 'Sign In'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.outline),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
