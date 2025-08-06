import 'package:flutter/material.dart';

class SlideUpRoute extends PageRouteBuilder {
  final Widget page;
  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: Tween<double>(
                    begin: 1.0,
                    end: 1.0,
                  ).evaluate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}
