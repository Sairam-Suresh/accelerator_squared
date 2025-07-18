import 'package:flutter/material.dart';

/// Light [ColorScheme] made with FlexColorScheme v8.2.0.
/// Requires Flutter 3.22.0 or later.
const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF223A5E),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF97BAEA),
  onPrimaryContainer: Color(0xFF0D1014),
  primaryFixed: Color(0xFFCBD4E1),
  primaryFixedDim: Color(0xFFA1AFC5),
  onPrimaryFixed: Color(0xFF060A10),
  onPrimaryFixedVariant: Color(0xFF0B121D),
  secondary: Color(0xFF144955),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFA9EDFF),
  onSecondaryContainer: Color(0xFF0F1414),
  secondaryFixed: Color(0xFFC7DCE0),
  secondaryFixedDim: Color(0xFF9ABDC5),
  onSecondaryFixed: Color(0xFF010405),
  onSecondaryFixedVariant: Color(0xFF041013),
  tertiary: Color(0xFF208399),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFCCF3FF),
  onTertiaryContainer: Color(0xFF121414),
  tertiaryFixed: Color(0xFFC9E8EE),
  tertiaryFixedDim: Color(0xFF9CD0DB),
  onTertiaryFixed: Color(0xFF0B2B33),
  onTertiaryFixedVariant: Color(0xFF0E3842),
  error: Color(0xFFB00020),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFCD9DF),
  onErrorContainer: Color(0xFF141313),
  surface: Color(0xFFF9F9FA),
  onSurface: Color(0xFF15191E),
  surfaceDim: Color(0xFFDDDDDE),
  surfaceBright: Color(0xFFFAFAFB),
  surfaceContainerLowest: Color(0xFFFCFCFC),
  surfaceContainerLow: Color(0xFFF5F5F6),
  surfaceContainer: Color(0xFFF0F0F1),
  surfaceContainerHigh: Color(0xFFEAEAEB),
  surfaceContainerHighest: Color(0xFFE4E4E5),
  onSurfaceVariant: Color(0xFF3A3D43),
  outline: Color(0xFF888A8D),
  outlineVariant: Color(0xFFC3C5C8),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF2A2A2A),
  onInverseSurface: Color(0xFFEAECEF),
  inversePrimary: Color(0xFFAABBD5),
  surfaceTint: Color(0xFF223A5E),
);

/// Dark [ColorScheme] made with FlexColorScheme v8.2.0.
/// Requires Flutter 3.22.0 or later.
const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF748BAC),
  onPrimary: Color(0xFFFCFDFE),
  primaryContainer: Color(0xFF1B2E4B),
  onPrimaryContainer: Color(0xFFF4F5F7),
  primaryFixed: Color(0xFFCBD4E1),
  primaryFixedDim: Color(0xFFA1AFC5),
  onPrimaryFixed: Color(0xFF060A10),
  onPrimaryFixedVariant: Color(0xFF0B121D),
  secondary: Color(0xFF539EAF),
  onSecondary: Color(0xFFFBFEFE),
  secondaryContainer: Color(0xFF004E5D),
  onSecondaryContainer: Color(0xFFF3F7F8),
  secondaryFixed: Color(0xFFC7DCE0),
  secondaryFixedDim: Color(0xFF9ABDC5),
  onSecondaryFixed: Color(0xFF010405),
  onSecondaryFixedVariant: Color(0xFF041013),
  tertiary: Color(0xFF219AB5),
  onTertiary: Color(0xFFFAFDFE),
  tertiaryContainer: Color(0xFF0F5B6A),
  onTertiaryContainer: Color(0xFFF3F8F9),
  tertiaryFixed: Color(0xFFC9E8EE),
  tertiaryFixedDim: Color(0xFF9CD0DB),
  onTertiaryFixed: Color(0xFF0B2B33),
  onTertiaryFixedVariant: Color(0xFF0E3842),
  error: Color(0xFFCF6679),
  onError: Color(0xFF080505),
  errorContainer: Color(0xFFB1384E),
  onErrorContainer: Color(0xFFFEF6F7),
  surface: Color(0xFF0F1012),
  onSurface: Color(0xFFE7E9EB),
  surfaceDim: Color(0xFF0D0E10),
  surfaceBright: Color(0xFF313234),
  surfaceContainerLowest: Color(0xFF080A0C),
  surfaceContainerLow: Color(0xFF141618),
  surfaceContainer: Color(0xFF1B1C1E),
  surfaceContainerHigh: Color(0xFF222426),
  surfaceContainerHighest: Color(0xFF2D2E30),
  onSurfaceVariant: Color(0xFFC3C4C7),
  outline: Color(0xFF77787A),
  outlineVariant: Color(0xFF444648),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE4E5E6),
  onInverseSurface: Color(0xFF2B2C2D),
  inversePrimary: Color(0xFF3C4755),
  surfaceTint: Color(0xFF748BAC),
);

// Theme mode enum
enum AppThemeMode { system, light, dark }

// App theme data class
class AppTheme {
  static const String _fontFamily = 'IBMPlexSans';

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: _fontFamily,
    colorScheme: lightColorScheme,
    brightness: Brightness.light,

    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.surface,
      foregroundColor: lightColorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: lightColorScheme.onSurface,
        fontFamily: _fontFamily,
      ),
      iconTheme: IconThemeData(
        color: lightColorScheme.onSurfaceVariant,
        size: 24,
      ),
    ),

    // Card theme
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: lightColorScheme.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: lightColorScheme.surface,
      surfaceTintColor: lightColorScheme.surfaceTint,
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shadowColor: lightColorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: _fontFamily,
        ),
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightColorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(
        color: lightColorScheme.onSurfaceVariant,
        fontSize: 16,
        fontFamily: _fontFamily,
      ),
      hintStyle: TextStyle(
        color: lightColorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 16,
        fontFamily: _fontFamily,
      ),
    ),

    // Navigation rail theme
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: lightColorScheme.surface,
      selectedIconTheme: IconThemeData(
        color: lightColorScheme.primary,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: lightColorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: lightColorScheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: _fontFamily,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: lightColorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: _fontFamily,
      ),
      indicatorColor: lightColorScheme.primaryContainer,
    ),

    // Floating action button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: lightColorScheme.surface,
      surfaceTintColor: lightColorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: lightColorScheme.onSurface,
        fontFamily: _fontFamily,
      ),
      contentTextStyle: TextStyle(
        fontSize: 16,
        color: lightColorScheme.onSurfaceVariant,
        fontFamily: _fontFamily,
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: lightColorScheme.surface,
      surfaceTintColor: lightColorScheme.surfaceTint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Tab bar theme
    tabBarTheme: TabBarThemeData(
      labelColor: lightColorScheme.primary,
      unselectedLabelColor: lightColorScheme.onSurfaceVariant,
      indicatorColor: lightColorScheme.primary,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: _fontFamily,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: _fontFamily,
      ),
    ),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: lightColorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    // Icon theme
    iconTheme: IconThemeData(
      color: lightColorScheme.onSurfaceVariant,
      size: 24,
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: _fontFamily,
    colorScheme: darkColorScheme,
    brightness: Brightness.dark,

    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.surface,
      foregroundColor: darkColorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkColorScheme.onSurface,
        fontFamily: _fontFamily,
      ),
      iconTheme: IconThemeData(
        color: darkColorScheme.onSurfaceVariant,
        size: 24,
      ),
    ),

    // Card theme
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: darkColorScheme.shadow.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: darkColorScheme.surfaceContainer,
      surfaceTintColor: darkColorScheme.surfaceTint,
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shadowColor: darkColorScheme.shadow.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: _fontFamily,
        ),
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
        ),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkColorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkColorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkColorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkColorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(
        color: darkColorScheme.onSurfaceVariant,
        fontSize: 16,
        fontFamily: _fontFamily,
      ),
      hintStyle: TextStyle(
        color: darkColorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 16,
        fontFamily: _fontFamily,
      ),
    ),

    // Navigation rail theme
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: darkColorScheme.surface,
      selectedIconTheme: IconThemeData(
        color: darkColorScheme.primary,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: darkColorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: darkColorScheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: _fontFamily,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: darkColorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: _fontFamily,
      ),
      indicatorColor: darkColorScheme.primaryContainer,
    ),

    // Floating action button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: darkColorScheme.surface,
      surfaceTintColor: darkColorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: darkColorScheme.onSurface,
        fontFamily: _fontFamily,
      ),
      contentTextStyle: TextStyle(
        fontSize: 16,
        color: darkColorScheme.onSurfaceVariant,
        fontFamily: _fontFamily,
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: darkColorScheme.surface,
      surfaceTintColor: darkColorScheme.surfaceTint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Tab bar theme
    tabBarTheme: TabBarThemeData(
      labelColor: darkColorScheme.primary,
      unselectedLabelColor: darkColorScheme.onSurfaceVariant,
      indicatorColor: darkColorScheme.primary,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: _fontFamily,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: _fontFamily,
      ),
    ),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: darkColorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    // Icon theme
    iconTheme: IconThemeData(color: darkColorScheme.onSurfaceVariant, size: 24),
  );
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;

  AppThemeMode get themeMode => _themeMode;

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  bool get isDarkMode {
    if (_themeMode == AppThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == AppThemeMode.dark;
  }

  ThemeData get theme => isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  ColorScheme get colorScheme =>
      isDarkMode ? darkColorScheme : lightColorScheme;
}

class InvitesPageProvider extends ChangeNotifier {
  bool _showInvitesPage = false;

  bool get showInvitesPage => _showInvitesPage;

  void setShowInvitesPage(bool value) {
    _showInvitesPage = value;
    notifyListeners();
  }
}
