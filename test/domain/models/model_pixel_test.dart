import 'package:flutter_test/flutter_test.dart';
import 'package:jocaagura_domain/jocaagura_domain.dart';
import 'package:pixel/domain/models/model_pixel.dart';

void main() {
  group('ModelPixel.fromJson', () {
    test('parses valid data correctly', () {
      final Map<String, Object> json = <String, Object>{
        'x': 3.5,
        'y': 7.2,
        'hexColor': '#AaBbCc',
      };
      final ModelPixel pixel = ModelPixel.fromJson(json);
      expect(pixel.vector.dx, equals(3.5));
      expect(pixel.vector.dy, equals(7.2));
      expect(pixel.hexColor, equals('#AABBCC')); // normalized uppercase
    });

    test('falls back to defaultHexColor on invalid hex', () {
      final Map<String, Object> json = <String, Object>{
        'x': 1.0,
        'y': 2.0,
        'hexColor': 'not-a-color',
      };
      final ModelPixel pixel = ModelPixel.fromJson(json);
      expect(pixel.hexColor, equals(ModelPixel.defaultHexColor));
    });

    test('uses defaultHexColor if hex missing', () {
      final Map<String, double> json = <String, double>{'x': 0.0, 'y': 0.0};
      final ModelPixel pixel = ModelPixel.fromJson(json);
      expect(pixel.hexColor, equals(ModelPixel.defaultHexColor));
    });
  });

  group('ModelPixel.fromCoord', () {
    test('creates pixel with correct int coords and hex', () {
      final ModelPixel pixel = ModelPixel.fromCoord(5, 9, hexColor: '#123456');
      expect(pixel.vector.dx, equals(5.0));
      expect(pixel.vector.dy, equals(9.0));
      expect(pixel.hexColor, equals('#123456'));
    });
  });

  group('ModelPixel.toJson', () {
    test('round-trip JSON retains original values', () {
      final ModelPixel original = ModelPixel.fromCoord(
        2,
        4,
        hexColor: '#ABCDEF',
      );
      final Map<String, dynamic> json = original.toJson();
      final ModelPixel rebuilt = ModelPixel.fromJson(json);

      expect(rebuilt, equals(original));
    });
  });

  group('copyWith', () {
    final ModelPixel base = ModelPixel.fromCoord(1, 1, hexColor: '#FFAABB');

    test('updates only specified fields', () {
      final ModelPixel updated = base.copyWith(
        vector: const ModelVector(9.0, 9.0),
      );
      expect(updated.vector.dx, equals(9.0));
      expect(updated.vector.dy, equals(9.0));
      expect(updated.hexColor, equals(base.hexColor));
    });

    test('original remains unchanged', () {
      base.copyWith(hexColor: '#112233');
      expect(base.hexColor, equals('#FFAABB'));
    });
  });

  group('Equality & hashCode', () {
    final ModelPixel a = ModelPixel.fromCoord(3, 3, hexColor: '#ABC123');
    final ModelPixel b = ModelPixel.fromCoord(3, 3, hexColor: '#ABC123');
    final ModelPixel c = ModelPixel.fromCoord(3, 3, hexColor: '#000000');

    test('identical content are equal', () {
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different hexColor yields inequality', () {
      expect(a == c, isFalse);
    });
  });

  group('Getters x & y', () {
    test('x returns rounded dx', () {
      // simulate fractional vector
      const ModelPixel p = ModelPixel(
        vector: ModelVector(4.4, 7.9),
        hexColor: '#FFFFFF',
      );
      expect(p.x, equals(4));
      expect(p.y, equals(8));
    });
  });

  group('toString', () {
    test('contains x, y and hexColor', () {
      final ModelPixel pixel = ModelPixel.fromCoord(0, 1, hexColor: '#123456');
      final String s = pixel.toString();
      expect(s, contains('x: 0'));
      expect(s, contains('y: 1'));
      expect(s, contains('color: #123456'));
    });
  });
}
