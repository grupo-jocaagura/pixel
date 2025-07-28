import 'package:flutter_test/flutter_test.dart';
import 'package:pixel/domain/models/model_canvas.dart';
import 'package:pixel/domain/models/model_pixel.dart';

void main() {
  // Helpers
  final Map<String, ModelPixel> samplePixels = <String, ModelPixel>{
    '0,0': ModelPixel.fromJson(const <String, dynamic>{
      'x': 0.0,
      'y': 0.0,
      'hexColor': '#FF0000',
    }),
    '1,2': ModelPixel.fromJson(const <String, dynamic>{
      'x': 1.0,
      'y': 2.0,
      'hexColor': '#00FF00',
    }),
  };

  group('ModelCanvas.fromJson', () {
    test('builds correctly with all fields', () {
      final Map<String, Object> json = <String, Object>{
        'id': 'canvas1',
        'width': 10,
        'height': 5,
        'pixelSize': 2.5,
        'pixels': <String, Map<String, Object>>{
          '0,0': <String, Object>{'x': 0.0, 'y': 0.0, 'hexColor': '#FF0000'},
          '1,2': <String, Object>{'x': 1.0, 'y': 2.0, 'hexColor': '#00FF00'},
        },
      };
      final ModelCanvas canvas = ModelCanvas.fromJson(json);

      expect(canvas.id, 'canvas1');
      expect(canvas.width, 10);
      expect(canvas.height, 5);
      expect(canvas.pixelSize, 2.5);
      expect(canvas.pixels, samplePixels);
    });

    test('builds correctly when id is missing', () {
      final Map<String, Object> json = <String, Object>{
        'width': 4,
        'height': 4,
        'pixelSize': 1.0,
        'pixels': <String, dynamic>{},
      };
      final ModelCanvas canvas = ModelCanvas.fromJson(json);

      expect(canvas.id, isEmpty);
      expect(canvas.width, 4);
      expect(canvas.height, 4);
      expect(canvas.pixelSize, 1.0);
      expect(canvas.pixels, isEmpty);
    });
  });

  group('ModelCanvas.toJson', () {
    test('produces map matching fromJson input', () {
      final ModelCanvas canvas = ModelCanvas(
        id: 'c2',
        width: 3,
        height: 3,
        pixelSize: 1.0,
        pixels: samplePixels,
      );
      final Map<String, dynamic> json = canvas.toJson();
      final ModelCanvas rebuilt = ModelCanvas.fromJson(json);

      expect(rebuilt, canvas);
    });
  });

  group('Round-trip JSON', () {
    test('fromJson(toJson(x)) == x', () {
      final ModelCanvas original = ModelCanvas(
        id: 'round',
        width: 2,
        height: 2,
        pixelSize: 1.5,
        pixels: samplePixels,
      );
      final ModelCanvas round = ModelCanvas.fromJson(original.toJson());
      expect(round, original);
    });
  });

  group('copyWith', () {
    final ModelCanvas base = ModelCanvas(
      id: 'base',
      width: 5,
      height: 5,
      pixelSize: 1.0,
      pixels: samplePixels,
    );

    test('updates only specified fields', () {
      final ModelCanvas modified = base.copyWith(width: 10, id: 'newId');
      expect(modified.id, 'newId');
      expect(modified.width, 10);
      expect(modified.height, base.height);
      expect(modified.pixelSize, base.pixelSize);
      expect(modified.pixels, base.pixels);
    });

    test('original remains unchanged', () {
      base.copyWith(width: 8);
      expect(base.width, 5);
      expect(base.id, 'base');
    });
  });

  group('Equality & hashCode', () {
    final ModelCanvas a = ModelCanvas(
      id: 'eq',
      width: 2,
      height: 2,
      pixelSize: 1.0,
      pixels: samplePixels,
    );
    final ModelCanvas b = ModelCanvas(
      id: 'eq',
      width: 2,
      height: 2,
      pixelSize: 1.0,
      pixels: samplePixels,
    );
    final ModelCanvas c = ModelCanvas(
      id: 'diff',
      width: 2,
      height: 2,
      pixelSize: 1.0,
      pixels: samplePixels,
    );

    test('identical content are equal', () {
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different id yields inequality', () {
      expect(a == c, isFalse);
    });

    test('different pixels yields inequality', () {
      final ModelCanvas d = a.copyWith(pixels: <String, ModelPixel>{});
      expect(a == d, isFalse);
    });
  });

  group('toString', () {
    test('contains key info', () {
      final ModelCanvas canvas = ModelCanvas(
        id: 'str',
        width: 3,
        height: 4,
        pixelSize: 2.0,
        pixels: samplePixels,
      );
      final String text = canvas.toString();
      expect(text, contains('ModelCanvas'));
      expect(text, contains('id: str'));
      expect(text, contains('3×4'));
      expect(text, contains('pixels: 2'));
    });
  });
}
