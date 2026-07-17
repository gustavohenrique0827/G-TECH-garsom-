import 'package:flutter/material.dart';

/// Centers content and caps its width on desktop/tablet, while staying
/// full-bleed on phones. Every top-level page body should be wrapped in
/// this instead of hand-rolling `ConstrainedBox` + `Center` per screen.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 640});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
