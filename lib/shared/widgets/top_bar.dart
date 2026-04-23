import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDesktop = screenWidth >= 1024;
    const jpmcBrown = Color(0xFF4A3C31);

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      titleSpacing: isMobile ? 16 : 48,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
              context.go('/');
            },
            child: const Text(
              'J.P.Morgan',
              style: TextStyle(
                fontFamily: 'Georgia, serif',
                fontSize: 26,
                color: jpmcBrown,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Desktop Center Links
          if (isDesktop)
            Row(
              children: [
                _topNavDropdown('Solutions'),
                _topNavDropdown('Who We Serve'),
                _topNavDropdown('Insights'),
                _topNavDropdown('About Us'),
              ],
            ),

          // Right Utilities
          if (!isMobile)
            Row(
              children: [
                const Icon(Icons.search, size: 18, color: Colors.black87),
                const SizedBox(width: 24),
                _topUtilityLink('Careers', null),
                _topUtilityLink('News', null),
                _topUtilityLink('Contact Us', null),
                _topUtilityLink(isAuthenticated ? 'Logout' : 'Login', isAuthenticated ? onSignOut : onSignIn),
                _topUtilityLink('Global', null),
              ],
            )
          else
            InkWell(
              onTap: onSignIn,
              child: const Icon(Icons.menu, color: Colors.black87),
            ),
        ],
      ),
    );
  }

  Widget _topNavDropdown(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _topUtilityLink(String text, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9E3A30),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
