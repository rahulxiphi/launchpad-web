import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'notification_icon.dart'; // Assuming this exists or I will create it

class HubNavBar extends StatelessWidget {
  final String companyName;
  final String founderName;
  final String initials;
  final VoidCallback? onProfileTap;
  final String activeLabel;

  const HubNavBar({
    super.key,
    required this.companyName,
    required this.founderName,
    required this.initials,
    this.onProfileTap,
    this.activeLabel = 'Hub',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: AppThemeTokens.modalHeader,
      child: Row(
        children: [
          RichText(
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
          const Spacer(),
          Wrap(
            spacing: 8,
            children: [
              NavPill(label: 'Hub', active: activeLabel == 'Hub'),
              NavPill(label: 'My profile', active: activeLabel == 'My profile'),
              NavPill(label: 'Events', active: activeLabel == 'Events'),
              NavPill(label: 'Resources', active: activeLabel == 'Resources'),
            ],
          ),
          const Spacer(),
          const NavbarNotificationIcon(),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onProfileTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF223A56),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFB99C4C), width: 1),
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
    );
  }
}

class NavPill extends StatelessWidget {
  final String label;
  final bool active;

  const NavPill({super.key, required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF28486C) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFFB6C2D2),
          fontSize: 13,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
