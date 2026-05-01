import 'package:flutter/material.dart';

class NoTransitionPageRoute<T> extends PageRouteBuilder<T> {
  NoTransitionPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
        );
}
