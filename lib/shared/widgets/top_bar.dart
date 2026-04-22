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
    const navy = Color(0xFF0A2744);
    const gold = Color(0xFFC8872A);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AppBar(
      backgroundColor: navy,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      title: Row(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontFamily: 'Georgia, serif', fontSize: 20, color: Colors.white, letterSpacing: 0.5),
              children: [
                TextSpan(text: 'J.P. '),
                TextSpan(text: 'Morgan', style: TextStyle(color: gold)),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('× LaunchPad', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
            )
          ]
        ],
      ),
      actions: [
        if (isMobile)
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            color: navy,
            offset: const Offset(0, 56), // Drop it below the app bar
            onSelected: (value) {
              if (value == 'profile') onProfileTap();
              if (value == 'auth') {
                if (isAuthenticated && onSignOut != null) {
                  onSignOut!();
                } else {
                  onSignIn();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'notifications',
                child: Row(children: [Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 18), SizedBox(width: 12), Text('Notifications', style: TextStyle(color: Colors.white))]),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(children: [Icon(Icons.person_rounded, color: Colors.white70, size: 18), SizedBox(width: 12), Text('Profile', style: TextStyle(color: Colors.white))]),
              ),
              PopupMenuItem(
                value: 'auth',
                child: Row(children: [Icon(isAuthenticated ? Icons.logout_rounded : Icons.login_rounded, color: Colors.white70, size: 18), SizedBox(width: 12), Text(isAuthenticated ? 'Sign Out' : 'Sign In', style: const TextStyle(color: Colors.white))]),
              ),
            ],
          )
        else ...[
          // Notification bell
          IconButton(
            tooltip: 'Notifications',
            icon: const Badge(
              isLabelVisible: false,
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.white70,
              ),
            ),
            onPressed: () {},
          ),
          // Profile avatar icon
          IconButton(
            tooltip: 'Profile',
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.15),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: Colors.white,
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
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ]
      ],
    );
  }
}
