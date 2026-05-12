import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'notification_icon.dart';
import 'prospect_id_provider.dart';

class HubNavBar extends StatelessWidget {
  final String companyName;
  final String founderName;
  final String initials;
  final VoidCallback? onProfileTap;
  final VoidCallback? onInteractionsTap;
  final VoidCallback? onClose;
  final String activeLabel;
  final bool isHubEnabled;

  const HubNavBar({
    super.key,
    required this.companyName,
    required this.founderName,
    required this.initials,
    this.onProfileTap,
    this.onInteractionsTap,
    this.onClose,
    this.activeLabel = 'Hub',
    this.isHubEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: AppThemeTokens.modalHeader,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              final pid = ProspectIdProvider.of(context);
              if (pid != null) {
                context.go('/?p=$pid');
              } else {
                context.go('/');
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: AppThemeTokens.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(text: 'JPMorgan '),
                    TextSpan(
                      text: 'Innovation Economy',
                      style: TextStyle(color: AppThemeTokens.goldAccent),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            children: [
              NavPill(
                label: 'Dashboard',
                active: activeLabel == 'Dashboard',
                onTap: () => context.go('/'),
              ),
              NavPill(
                label: 'Interactions',
                active: activeLabel == 'Interactions',
                onTap: onInteractionsTap,
              ),
              NavPill(
                label: 'Relationship Hub',
                active: activeLabel == 'Relationship Hub',
                enabled: isHubEnabled,
                onTap: isHubEnabled ? () {
                  final pid = ProspectIdProvider.of(context);
                  if (pid != null) {
                    context.go('/relationship-hub?p=$pid');
                  } else {
                    context.go('/relationship-hub');
                  }
                } : null,
              ),
            ],
          ),
          const Spacer(),
          const NavbarNotificationIcon(),
          const SizedBox(width: 16),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onProfileTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF223A56),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: const Color(0xFFB99C4C), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppThemeTokens.goldAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    companyName.isNotEmpty && companyName != 'Launchpad'
                        ? companyName
                        : founderName.split(' ').first,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 16),
            GestureDetector(
              onTap: onClose,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NavPill extends StatelessWidget {
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback? onTap;

  const NavPill({
    super.key,
    required this.label,
    this.active = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF28486C) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active 
                  ? Colors.white 
                  : (enabled ? const Color(0xFFB6C2D2) : const Color(0xFF5A6B80)),
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
