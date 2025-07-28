import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel/shared/util_color.dart';

void main() {
  group('UtilColor.colorToHex', () {
    test('converts opaque color correctly', () {
      expect(UtilColor.colorToHex(const Color(0xFF123456)), '#FF123456');
    });

    test('converts semi-transparent color correctly', () {
      expect(UtilColor.colorToHex(const Color(0x80123456)), '#80123456');
    });
  });

  group('UtilColor.hexToColor', () {
    test('parses #RRGGBB as opaque', () {
      final Color color = UtilColor.hexToColor('#123456');
      expect(color, equals(const Color(0xFF123456)));
    });

    test('parses #AARRGGBB correctly', () {
      final Color color = UtilColor.hexToColor('#80123456');
      expect(color, equals(const Color(0x80123456)));
    });

    test('throws FormatException on invalid format', () {
      expect(() => UtilColor.hexToColor('123456'), throwsFormatException);
      expect(() => UtilColor.hexToColor('#GG1122'), throwsFormatException);
      expect(() => UtilColor.hexToColor('#12345'), throwsFormatException);
    });
  });

  group('UtilColor.isValidHexColor', () {
    test('returns true for #RRGGBB', () {
      expect(UtilColor.isValidHexColor('#abcdef'), isTrue);
      expect(UtilColor.isValidHexColor('#ABCDEF'), isTrue);
    });

    test('returns true for #AARRGGBB', () {
      expect(UtilColor.isValidHexColor('#80123456'), isTrue);
    });

    test('returns false for missing #', () {
      expect(UtilColor.isValidHexColor('123456'), isFalse);
    });

    test('returns false for wrong length', () {
      expect(UtilColor.isValidHexColor('#12345'), isFalse);
      expect(UtilColor.isValidHexColor('#1234567'), isFalse);
    });

    test('returns false for non-hex chars', () {
      expect(UtilColor.isValidHexColor('#ZZZZZZ'), isFalse);
    });
  });
  group('Validación dinámica de hexPattern en UtilColor', () {
    final List<String> validHexColors = <String>[
      '#123456',
      '#abcdef',
      '#ABCDEF',
      '#80FF5722',
      '#FFFFFFFF',
      '#00000000',
    ];

    final List<String> invalidHexColors = <String>[
      '123456', // Falta #
      '#12345', // Longitud incorrecta
      '#1234567', // Longitud incorrecta
      '#ZZZZZZ', // Caracteres inválidos
      '#123456789', // Muy largo
      '', // Vacío
      '#', // Solo numeral
    ];

    test('Reconoce todos los formatos válidos', () {
      for (final String hex in validHexColors) {
        expect(
          UtilColor.isValidHexColor(hex),
          isTrue,
          reason: 'Falla en: $hex',
        );
      }
    });

    test('Rechaza todos los formatos inválidos', () {
      for (final String hex in invalidHexColors) {
        expect(
          UtilColor.isValidHexColor(hex),
          isFalse,
          reason: 'No debería ser válido: $hex',
        );
      }
    });

    test('Conversiones ida y vuelta (Color <-> Hex)', () {
      for (final String hex in validHexColors) {
        // Solo los que son válidos para convertir
        final Color color = UtilColor.hexToColor(hex);
        final String backToHex = UtilColor.colorToHex(color);
        // La conversión de ida y vuelta debe mantener el valor, ajustando alpha si hace falta
        if (hex.length == 7) {
          // #RRGGBB → #FFRRGGBB
          final String expected = '#FF${hex.substring(1).toUpperCase()}';
          expect(
            backToHex,
            expected,
            reason: 'Back to hex no es igual para $hex',
          );
        } else if (hex.length == 9) {
          expect(
            backToHex,
            hex.toUpperCase(),
            reason: 'Back to hex no es igual para $hex',
          );
        }
      }
    });
  });
}
