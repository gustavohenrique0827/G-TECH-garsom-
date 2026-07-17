import 'package:flutter/material.dart';

/// A [FilledButton] with a built-in loading spinner state, so every async
/// action in the app shows the same feedback instead of each screen
/// reinventing its own `_loading ? Spinner : Text` ternary.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
          );

    return FilledButton(onPressed: loading ? null : onPressed, child: child);
  }
}
