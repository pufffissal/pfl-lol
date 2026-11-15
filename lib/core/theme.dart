import 'package:material_ui/material_ui.dart';

/// Original dark theme: deep navy background with a gold accent.
class AppTheme {
  static const gold = Color(0xFFC9A55C);
  static const navy = Color(0xFF0B1320);
  static const surface = Color(0xFF131D2E);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.dark,
    ).copyWith(primary: gold, surface: surface);
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: navy,
      appBarTheme: const AppBarTheme(backgroundColor: navy, centerTitle: false),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: surface),
      cardTheme: const CardThemeData(color: surface, margin: EdgeInsets.zero),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Colors for Data Dragon markup tags such as `<physicalDamage>`.
const markupColors = <String, Color>{
  'physicaldamage': Color(0xFFFF8C34),
  'scalead': Color(0xFFFF8C34),
  'magicdamage': Color(0xFF6FA8FF),
  'scaleap': Color(0xFF9F8CFF),
  'truedamage': Color(0xFFFFFFFF),
  'healing': Color(0xFF5FD068),
  'scalehealth': Color(0xFF5FD068),
  'shield': Color(0xFFB0C4DE),
  'status': Color(0xFFC77DFF),
  'speed': Color(0xFFF5E663),
  'scalemana': Color(0xFF4FC3F7),
  'attention': AppTheme.gold,
  'stats': AppTheme.gold,
  'keywordmajor': AppTheme.gold,
  'keywordstealth': Color(0xFFB39DDB),
  'onhit': Color(0xFFE0A0A0),
  'raritylegendary': Color(0xFFFF9F43),
  'raritymythic': Color(0xFFFF6B9F),
  'raritygeneric': AppTheme.gold,
};

/// Tags rendered in bold.
const markupBold = {
  'attention',
  'passive',
  'active',
  'keywordmajor',
  'unique',
  'raritylegendary',
  'raritymythic',
  'truedamage',
  'b',
  'strong',
};
