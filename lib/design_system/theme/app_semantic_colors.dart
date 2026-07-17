import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Semantic colors that don't map onto Material 3's [ColorScheme] roles.
/// Access via `Theme.of(context).extension<AppSemanticColors>()!`.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.danger,
    required this.warning,
  });

  final Color success;
  final Color danger;
  final Color warning;

  static const light = AppSemanticColors(
    success: AppColors.success,
    danger: AppColors.danger,
    warning: Color(0xFFB8791E),
  );

  static const dark = AppSemanticColors(
    success: AppColors.success,
    danger: AppColors.danger,
    warning: AppColors.warning,
  );

  @override
  AppSemanticColors copyWith({Color? success, Color? danger, Color? warning}) {
    return AppSemanticColors(
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppSemanticColors lerp(
    ThemeExtension<AppSemanticColors>? other,
    double t,
  ) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
