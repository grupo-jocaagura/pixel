import 'package:flutter/material.dart';

/// Utility functions for converting between [Color] and hexadecimal strings,
/// and validating color string formats.
///
/// Example:
/// ```dart
/// import 'package:your_package/utils/color_utils.dart';
/// import 'package:flutter/material.dart';
///
/// final Color color = UtilColor.hexToColor('#80FF5722');
/// final String hex = UtilColor.colorToHex(color); // '#80FF5722'
/// final bool valid1 = UtilColor.isValidHexColor('#FF5722');   // true
/// final bool valid2 = UtilColor.isValidHexColor('#80FF5722'); // true
/// final bool valid3 = UtilColor.isValidHexColor('FF5722');    // false
/// ```
class UtilColor {
  const UtilColor._(); // coverage:ignore-line

  /// Expresión regular que valida strings de color hex:
  /// - #RRGGBB
  /// - #AARRGGBB
  static const String hexPattern = r'^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$';
  static const String defaultHexColor = '#000000';

  /// Converts a [color] to a hexadecimal string in `#AARRGGBB` format.
  ///
  /// The returned string always includes the alpha channel, padded to 2 digits.
  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static Color gridLineColor = Colors.grey.shade300;

  /// Parses a hexadecimal [hex] string and returns a [Color].
  ///
  /// Accepts `#RRGGBB` (assumes alpha = `FF`) or `#AARRGGBB`.
  /// Throws a [FormatException] if [hex] is not a valid format.
  static Color hexToColor(String hex) {
    final String sanitized = hex.trim();
    if (!isValidHexColor(sanitized)) {
      throw FormatException('Invalid hex color format: $hex');
    }
    String hexDigits = sanitized.substring(1);
    if (hexDigits.length == 6) {
      // Add opaque alpha if missing
      hexDigits = 'FF$hexDigits';
    }
    final int value = int.parse(hexDigits, radix: 16);
    return Color(value);
  }

  /// Validates whether a [hex] string is a valid color format:
  /// - `#RRGGBB`
  /// - `#AARRGGBB`
  ///
  /// Returns `true` if [hex] matches the pattern, otherwise `false`.
  static bool isValidHexColor(String hex) {
    final RegExp pattern = RegExp(hexPattern);
    return pattern.hasMatch(hex);
  }

  static String normalizeHex(String? input) {
    final String hex = input ?? defaultHexColor;
    return isValidHexColor(hex) ? hex.toUpperCase() : defaultHexColor;
  }
}
