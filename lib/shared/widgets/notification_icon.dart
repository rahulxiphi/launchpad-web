import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NavbarNotificationIcon extends StatefulWidget {
  const NavbarNotificationIcon({super.key});

  @override
  State<NavbarNotificationIcon> createState() => _NavbarNotificationIconState();
}

class _NavbarNotificationIconState extends State<NavbarNotificationIcon> {
  final NotificationService _notifService = NotificationService();
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;
  bool _isOpen = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _notifService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _notifService.removeListener(_onServiceUpdate);
    _hideTimer?.cancel();
    _hideOverlay();
    super.dispose();
  }

  void _onServiceUpdate() {
    setState(() {});
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => _NotificationDropdown(
        link: _link,
        notifService: _notifService,
        isOpen: _isOpen,
        onClose: _toggleOpen,
        onMouseEnter: () => _hideTimer?.cancel(),
        onMouseExit: () {
          if (!_isOpen) _startHideTimer();
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 200), () {
      if (!_isHovered && !_isOpen) {
        _hideOverlay();
      }
    });
  }

  void _hideOverlay() {
    _hideTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleOpen() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          _hideTimer?.cancel();
          setState(() {
            _isHovered = true;
            _showOverlay();
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
            if (!_isOpen) _startHideTimer();
          });
        },
        child: GestureDetector(
          onTap: _toggleOpen,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (_isHovered || _isOpen)
                  ? const Color(0xFFF3F4F6).withOpacity(0.12)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                if (_notifService.activeHubNotifications.isNotEmpty)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF87171),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF131F2E), width: 1.5),
                      ),
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

class _NotificationDropdown extends StatefulWidget {
  final LayerLink link;
  final NotificationService notifService;
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onMouseEnter;
  final VoidCallback onMouseExit;

  const _NotificationDropdown({
    required this.link,
    required this.notifService,
    required this.isOpen,
    required this.onClose,
    required this.onMouseEnter,
    required this.onMouseExit,
  });

  @override
  State<_NotificationDropdown> createState() => _NotificationDropdownState();
}

class _NotificationDropdownState extends State<_NotificationDropdown> {
  bool _viewAll = false;

  @override
  void initState() {
    super.initState();
    widget.notifService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.notifService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.notifService.dropdownHistory;
    final visible = _viewAll ? history : history.take(5).toList();

    return Stack(
      children: [
        if (widget.isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.transparent),
            ),
          ),
        Positioned(
          child: CompositedTransformFollower(
            link: widget.link,
            showWhenUnlinked: false,
            offset: const Offset(-250, 40),
            child: MouseRegion(
              onEnter: (_) => widget.onMouseEnter(),
              onExit: (_) => widget.onMouseExit(),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF202020),
                              ),
                            ),
                            const Spacer(),
                            if (history.isNotEmpty)
                              GestureDetector(
                                onTap: widget.notifService.clearHistory,
                                child: const Text(
                                  'Clear history',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1A7B99),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (history.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No notifications now',
                              style: TextStyle(color: Color(0xFF8D8578), fontSize: 13),
                            ),
                          ),
                        )
                      else ...[
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 400),
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children: visible.map((n) => _buildDropdownItem(n)).toList(),
                            ),
                          ),
                        ),
                        if (history.length > 5 && !_viewAll)
                          GestureDetector(
                            onTap: () => setState(() => _viewAll = true),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              child: const Center(
                                child: Text(
                                  'View all notifications',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1A7B99),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownItem(NotificationItem n) {
    return Container(
      color: n.isPriority ? n.bg.withOpacity(0.45) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: n.bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(n.icon, size: 16, color: n.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF202020),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  n.time,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8D8578)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
