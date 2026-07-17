import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChamaGarcomTheme {

  // Base colors (do HTML)
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color paper;
  final Color brass;
  final Color brassBright;
  final Color teal;
  final Color coral;
  final Color line;
  final Color textDimColor;
  final Color textDimmerColor;


  final String spaceFont;

  ChamaGarcomTheme._({
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.paper,
    required this.brass,
    required this.brassBright,
    required this.teal,
    required this.coral,
    required this.line,
    required this.textDimColor,
    required this.textDimmerColor,

    required this.spaceFont,
  });

  static ChamaGarcomTheme of(BuildContext context) {
    return ChamaGarcomThemeData.base();
  }


  // Typography helpers
  TextStyle get textDim => GoogleFonts.inter(color: textDimColor, fontWeight: FontWeight.w500);
  TextStyle get textDimmer => GoogleFonts.inter(color: textDimmerColor, fontWeight: FontWeight.w400);



  TextStyle get space600 => GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: paper);
  TextStyle get paper600 => GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: paper);
  TextStyle get mono600 => GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: brassBright);

  TextStyle get ink700 => GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: ink);

  TextStyle get brassBright600 => GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w600, color: brassBright);


  // HTML uses uppercase letter spacing variants
  static ChamaGarcomTheme base() => ChamaGarcomThemeData.base();
}

class ChamaGarcomThemeExt extends ThemeExtension<ChamaGarcomThemeExt> {
  final ChamaGarcomTheme theme;
  const ChamaGarcomThemeExt(this.theme);

  @override
  ThemeExtension<ChamaGarcomThemeExt> copyWith({ChamaGarcomTheme? theme}) {
    return ChamaGarcomThemeExt(theme ?? this.theme);
  }

  @override
  ThemeExtension<ChamaGarcomThemeExt> lerp(
    ThemeExtension<ChamaGarcomThemeExt>? other,
    double t,
  ) {
    if (other is! ChamaGarcomThemeExt) return this;
    // No animation between themes
    return this;
  }
}

class ChamaGarcomThemeData {
  static ChamaGarcomTheme base() {
    return ChamaGarcomTheme._(
      ink: const Color(0xFF14161C),
      ink2: const Color(0xFF1C1F28),
      ink3: const Color(0xFF252A36),
      paper: const Color(0xFFF5F3EE),
      brass: const Color(0xFFE0A13B),
      brassBright: const Color(0xFFF4B955),
      teal: const Color(0xFF2DD4BF),
      coral: const Color(0xFFFF6B5C),
      line: const Color.fromRGBO(255, 255, 255, 0.08),
      textDimColor: const Color.fromRGBO(245, 243, 238, 0.55),
      textDimmerColor: const Color.fromRGBO(245, 243, 238, 0.35),

      spaceFont: 'Space Grotesk',
    );
  }
}



