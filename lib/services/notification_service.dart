import 'package:flutter/material.dart';

class NotificationItem {
  final String title;
  final String message;
  final String footer;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final bool isPriority;

  NotificationItem({
    required this.title,
    this.message = '',
    this.footer = '',
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.bg,
    this.isPriority = false,
  });
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationItem> _activeHubNotifications = [
    NotificationItem(
      title: 'Meeting confirmed',
      message: 'Intro call with Sarah on May 6 at 2:00 PM ET. Tap to prep.',
      footer: 'Apr 28 · Click to prepare',
      time: 'Apr 28',
      icon: Icons.calendar_today_rounded,
      iconColor: const Color(0xFF7C5410),
      bg: const Color(0xFFFBEAD5),
      isPriority: true,
    ),
    NotificationItem(
      title: 'Call summary available',
      message: 'Apr 29 call with Sarah. Topics, next steps, and new material added.',
      footer: 'Apr 29 · Click to view',
      time: 'Apr 29',
      icon: Icons.call_outlined,
      iconColor: const Color(0xFF0F6E56),
      bg: const Color(0xFFE1F5EE),
      isPriority: true,
    ),
    NotificationItem(
      title: 'New guide added by Sarah',
      message: 'Preparing for your first credit facility, based on your call.',
      footer: 'Apr 29 · In your learning path',
      time: 'Apr 29',
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF5B55D9),
      bg: const Color(0xFFEEEDFE),
      isPriority: true,
    ),
  ];

  final List<NotificationItem> _dropdownHistory = [
    NotificationItem(
      title: 'Sarah reviewed your guide',
      time: '2 hours ago',
      icon: Icons.description_outlined,
      bg: const Color(0xFFEEEDFE),
      iconColor: const Color(0xFF5B55D9),
    ),
    NotificationItem(
      title: 'New message from Alex',
      time: '5 hours ago',
      icon: Icons.message_outlined,
      bg: const Color(0xFFE1F5EE),
      iconColor: const Color(0xFF0F6E56),
    ),
    NotificationItem(
      title: 'Upcoming meeting: Q3 Review',
      time: '1 day ago',
      icon: Icons.calendar_today_rounded,
      bg: const Color(0xFFFBEAD5),
      iconColor: const Color(0xFF7C5410),
    ),
  ];

  List<NotificationItem> get activeHubNotifications => _activeHubNotifications;
  List<NotificationItem> get dropdownHistory => _dropdownHistory;

  void markAsRead(int index) {
    if (index >= 0 && index < _activeHubNotifications.length) {
      final item = _activeHubNotifications.removeAt(index);
      // Add to history at the top, keep priority flag but update time
      _dropdownHistory.insert(0, NotificationItem(
        title: item.title,
        time: 'Just now',
        icon: item.icon,
        iconColor: item.iconColor,
        bg: item.bg,
        isPriority: true, // Keep it highlighted as it was a hub notification
      ));
      notifyListeners();
    }
  }

  void clearHistory() {
    _dropdownHistory.clear();
    notifyListeners();
  }
}
