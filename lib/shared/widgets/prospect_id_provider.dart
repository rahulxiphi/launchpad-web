import 'package:flutter/material.dart';

class ProspectIdProvider extends InheritedWidget {
  final String? prospectId;
  const ProspectIdProvider({
    super.key,
    required this.prospectId,
    required super.child,
  });

  static String? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ProspectIdProvider>()?.prospectId;
  }

  @override
  bool updateShouldNotify(ProspectIdProvider oldWidget) =>
      prospectId != oldWidget.prospectId;
}
