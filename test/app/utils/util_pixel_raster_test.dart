import 'package:flutter_test/flutter_test.dart';
import 'package:pixel/app/utils/util_pixel_raster.dart';
import 'package:pixel/domain/models/model_canvas.dart';
import 'package:pixel/domain/models/model_pixel.dart';

void main() {
  const ModelCanvas base = ModelCanvas(
    id: defaultModelCanvasId,
    width: 8,
    height: 8,
    pixelSize: 1,
    pixels: <String, ModelPixel>{},
  );

  test('Vertical line (0,0) -> (0,5)', () {
    final ModelCanvas m = UtilPixelRaster.drawLine(
      canvas: base,
      origin: ModelPixel.fromCoord(0, 0, hexColor: '#000000'),
      destiny: ModelPixel.fromCoord(0, 5, hexColor: '#000000'),
    );
    expect(m.pixels.length, 6);
    for (int y = 0; y <= 5; y++) {
      expect(m.pixels.containsKey('0,$y'), true);
    }
  });

  test('Horizontal line (0,0) -> (5,0)', () {
    final ModelCanvas m = UtilPixelRaster.drawLine(
      canvas: base,
      origin: ModelPixel.fromCoord(0, 0, hexColor: '#FF0000'),
      destiny: ModelPixel.fromCoord(5, 0, hexColor: '#FF0000'),
    );
    expect(m.pixels.length, 6);
    for (int x = 0; x <= 5; x++) {
      expect(m.pixels.containsKey('$x,0'), true);
    }
  });

  test('Diagonal 45° (0,0) -> (3,3)', () {
    final ModelCanvas m = UtilPixelRaster.drawLine(
      canvas: base,
      origin: ModelPixel.fromCoord(0, 0, hexColor: '#00FF00'),
      destiny: ModelPixel.fromCoord(3, 3, hexColor: '#00FF00'),
    );
    expect(m.pixels.length, 4);
    expect(m.pixels.keys.toSet(), <String>{'0,0', '1,1', '2,2', '3,3'});
  });
}
