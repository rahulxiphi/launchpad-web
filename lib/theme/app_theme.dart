import 'package:flutter/material.dart';

class AppThemeTokens {
  const AppThemeTokens._();

  static const String fontFamily = 'Avenir';

  static const Color buttonPrimary = Color(0xFF1A7B99);
  static const Color buttonPrimaryHover = Color(0xFF005075);
  static const Color buttonInactive = Color(0xFF1A7B99);
  static const Color buttonText = Colors.white;

  static const Color modalHeader = Color(0xFF0F1820);
  static const Color goldAccent = Color(0xFFAF8462);
  static const Color bodyText = Color(0xFF1F2937);
  static const Color subtleText = Color(0xFF6B7280);
  static const Color brandInk = Color(0xFF131F2E);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: AppThemeTokens.buttonPrimary,
      onPrimary: AppThemeTokens.buttonText,
      secondary: AppThemeTokens.goldAccent,
      onSecondary: AppThemeTokens.buttonText,
      surface: Colors.white,
      onSurface: AppThemeTokens.bodyText,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppThemeTokens.fontFamily,
      fontFamilyFallback: const ['Helvetica Neue', 'Arial', 'sans-serif'],
    );

    ButtonStyle filledButtonStyle({
      double radius = 12,
      EdgeInsetsGeometry padding =
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    }) {
      return ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppThemeTokens.buttonText),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: AppThemeTokens.fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
        padding: WidgetStateProperty.all(padding),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        elevation: WidgetStateProperty.all(0),
        mouseCursor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return SystemMouseCursors.basic;
          }
          return SystemMouseCursors.click;
        }),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppThemeTokens.buttonInactive;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused)) {
            return AppThemeTokens.buttonPrimaryHover;
          }
          return AppThemeTokens.buttonPrimary;
        }),
      );
    }

    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppThemeTokens.bodyText,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: AppThemeTokens.fontFamily,
        bodyColor: AppThemeTokens.bodyText,
        displayColor: AppThemeTokens.bodyText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: filledButtonStyle(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: filledButtonStyle(),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.focused)) {
              return AppThemeTokens.buttonPrimaryHover;
            }
            return AppThemeTokens.buttonPrimary;
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: AppThemeTokens.fontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SystemMouseCursors.basic;
            }
            return SystemMouseCursors.click;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.focused)) {
              return const BorderSide(
                color: AppThemeTokens.buttonPrimaryHover,
                width: 1.4,
              );
            }
            return const BorderSide(
              color: AppThemeTokens.buttonPrimary,
              width: 1.4,
            );
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              WidgetStateProperty.all(AppThemeTokens.buttonPrimary),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: AppThemeTokens.fontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
          mouseCursor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return SystemMouseCursors.basic;
            }
            return SystemMouseCursors.click;
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppThemeTokens.modalHeader,
        textStyle: const TextStyle(
          fontFamily: AppThemeTokens.fontFamily,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
