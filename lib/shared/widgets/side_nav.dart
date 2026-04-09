import 'package:flutter/material.dart';

/// A nav item descriptor.
class _NavItem {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const _navItems = <_NavItem>[
  _NavItem(
    index: 0,
    icon: Icons.chat_bubble_outline_rounded,
    activeIcon: Icons.chat_bubble_rounded,
    label: 'Chat',
  ),
  _NavItem(
    index: 1,
    icon: Icons.star_outline_rounded,
    activeIcon: Icons.star_rounded,
    label: 'Matches',
  ),
  _NavItem(
    index: 2,
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today_rounded,
    label: 'Sessions',
  ),
  _NavItem(
    index: 3,
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book_rounded,
    label: 'Learn',
  ),
  // divider placed between index 3 and 4
  _NavItem(
    index: 4,
    icon: Icons.people_outline_rounded,
    activeIcon: Icons.people_rounded,
    label: 'Connections',
  ),
];

/// Fixed-width (240 px) always-expanded side navigation panel.
///
/// [selectedIndex] — index of the currently active item (0 = Chat).
/// [onNavTap]      — called with the tapped item's index.
/// [onSignIn]      — called when the bottom "Sign In" button is tapped.
class SideNav extends StatelessWidget {
  final int selectedIndex;
  final void Function(int index) onNavTap;
  final VoidCallback onSignIn;
  final VoidCallback? onSignOut;
  final bool isAuthenticated;

  const SideNav({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
    required this.onSignIn,
    this.onSignOut,
    this.isAuthenticated = false,
  });

  static const double _width = 240;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: _width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // ── Nav items 0–3 (Chat, Matches, Sessions, Learn) ───────────────
          for (final item in _navItems.where((i) => i.index <= 3))
            _NavTile(
              item: item,
              isSelected: selectedIndex == item.index,
              onTap: () => onNavTap(item.index),
            ),

          // ── Divider ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(
              color: colorScheme.outlineVariant,
              height: 1,
            ),
          ),

          // ── Nav item 4 (Connections) ──────────────────────────────────────
          for (final item in _navItems.where((i) => i.index >= 4))
            _NavTile(
              item: item,
              isSelected: selectedIndex == item.index,
              onTap: () => onNavTap(item.index),
            ),

          const Spacer(),

          // ── Bottom auth action ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: TextButton.icon(
              onPressed: isAuthenticated ? onSignOut : onSignIn,
              icon: Icon(
                isAuthenticated ? Icons.logout_rounded : Icons.login_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              label: Text(
                isAuthenticated ? 'Sign Out' : 'Sign In',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual nav tile
// ---------------------------------------------------------------------------
class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bgColor = isSelected
        ? colorScheme.primaryContainer
        : Colors.transparent;

    final fgColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: isSelected
              ? colorScheme.primaryContainer.withAlpha(180)
              : colorScheme.onSurface.withAlpha(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 20,
                  color: fgColor,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: fgColor,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
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
