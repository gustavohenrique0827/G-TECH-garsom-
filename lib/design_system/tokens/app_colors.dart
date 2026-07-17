import 'package:flutter/material.dart';

/// Brand palette. [seed] drives Material 3's dynamic ColorScheme; the rest
/// are semantic colors that don't map cleanly onto Material roles.
abstract class AppColors {
  const AppColors._();

  static const seed = Color(0xFFF4B955); // brass

  static const success = Color(0xFF2DD4BF); // teal
  static const danger = Color(0xFFFF6B5C); // coral
  static const warning = Color(0xFFF4B955);

  static const inkDark = Color(0xFF14161C);
  static const inkDark2 = Color(0xFF1C1F28);
  static const inkDark3 = Color(0xFF252A36);
}
