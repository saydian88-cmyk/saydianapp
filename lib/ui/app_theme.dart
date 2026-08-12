import 'package:flutter/material.dart';

abstract final class SaydianColors {
  static const ink = Color(0xFF101114);
  static const muted = Color(0xFF747981);
  static const canvas = Color(0xFFF5F6F8);
  static const line = Color(0xFFE9EBEF);
  static const green = Color(0xFF48D66B);
  static const blue = Color(0xFF5C9DFF);
  static const orange = Color(0xFFFFB34E);
  static const pink = Color(0xFFF07493);
  static const cyan = Color(0xFF55C7D8);
}

ThemeData buildSaydianTheme() {
  const scheme = ColorScheme.light(
    primary: SaydianColors.ink,
    onPrimary: Colors.white,
    secondary: SaydianColors.green,
    onSecondary: SaydianColors.ink,
    surface: Colors.white,
    onSurface: SaydianColors.ink,
    error: Color(0xFFE3484F),
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: SaydianColors.canvas,
    useMaterial3: true,
    fontFamilyFallback: const ['PingFang SC', 'Microsoft YaHei', 'sans-serif'],
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: SaydianColors.canvas,
      foregroundColor: SaydianColors.ink,
      titleTextStyle: TextStyle(
        color: SaydianColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Color(0xFFB4B8BF), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: SaydianColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: SaydianColors.ink, width: 1.2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        foregroundColor: SaydianColors.ink,
        side: const BorderSide(color: SaydianColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: SaydianColors.line,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 66,
      backgroundColor: Colors.white,
      elevation: 0,
      indicatorColor: SaydianColors.ink,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? SaydianColors.ink
              : const Color(0xFF9DA1A8),
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFF9DA1A8),
          size: 22,
        ),
      ),
    ),
  );
}

const saydianSoftGradient = LinearGradient(
  colors: [Color(0xFFF2FEFF), Color(0xFFFAF7EE), SaydianColors.canvas],
  stops: [0, 0.42, 1],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
