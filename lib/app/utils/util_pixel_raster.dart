import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';

/// Utilities to rasterize vector primitives into a pixel-art [ModelCanvas].
///
/// This version implements an integer-only Bresenham line rasterizer. It
/// yields all touched pixel coordinates from origin to destiny (inclusive),
/// clamped to canvas bounds, and returns a **new** [ModelCanvas] with those
/// pixels written.
///
/// ### Why Bresenham?
/// - It picks the next pixel that **minimizes the error** to the ideal line.
/// - Works with integers only: fast and stable for pixel-art.
/// - Handles all octants (any slope, any direction).
///
/// ### Example
/// ### Example
/// ```dart
/// final ModelCanvas next = UtilPixelRaster.drawLine(
///   canvas: current,
///   origin: ModelPixel.fromCoord(0, 0, hexColor: '#000000'),
///   destiny: ModelPixel.fromCoord(1, 4, hexColor: '#000000'),
///   overwrite: true,
/// );
/// // The canvas now contains: (0,0), (0,1), (0,2), (1,3), (1,4)
/// ```
class UtilPixelRaster {
  /// Draws a straight line between [origin] and [destiny] using Bresenham and
  /// returns a **new** [ModelCanvas] with all the produced pixels written.
  ///
  /// - If [hexColorOverride] is provided, it overrides pixel colors; otherwise
  ///   [origin.hexColor] is used for all pixels.
  /// - When [overwrite] is `false`, existing pixels are respected.
  /// - Pixels outside canvas bounds are **ignored** (simple clipping).
  static ModelCanvas drawLine({
    required ModelCanvas canvas,
    required ModelPixel origin,
    required ModelPixel destiny,
    String? hexColorOverride,
    bool overwrite = true,
  }) {
    final String color = hexColorOverride ?? origin.hexColor;

    // 1) Mutable copy once (avoid N copies)
    final Map<String, ModelPixel> next = Map<String, ModelPixel>.of(
      canvas.pixels,
    );

    // 2) Integer endpoints
    int x0 = origin.x;
    int y0 = origin.y;
    final int x1 = destiny.x;
    final int y1 = destiny.y;

    // 3) Bresenham core
    final int dx = (x1 - x0).abs();
    final int dy = (y1 - y0).abs();
    final int sx = x0 < x1 ? 1 : -1;
    final int sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;

    while (true) {
      // Guard bounds (ignore out-of-canvas pixels)
      if (_inBounds(canvas, x0, y0)) {
        final String key = _key(x0, y0);
        if (overwrite || !next.containsKey(key)) {
          next[key] = ModelPixel.fromCoord(x0, y0, hexColor: color);
        }
      }

      if (x0 == x1 && y0 == y1) {
        break;
      }

      final int e2 = err << 1; // 2*err
      if (e2 > -dy) {
        err -= dy;
        x0 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y0 += sy;
      }
    }

    return canvas.copyWith(pixels: Map<String, ModelPixel>.unmodifiable(next));
  }

  static bool _inBounds(ModelCanvas c, int x, int y) =>
      x >= 0 && y >= 0 && x < c.width && y < c.height;

  static String _key(int x, int y) => '$x,$y';

  /// Returns the inclusive list of pixels for a Bresenham line, **without**
  /// modifying the canvas (pure computation).
  ///
  /// Out-of-bounds pixels will be clipped out by [clipToCanvasBounds]. If true,
  /// the result excludes pixels outside [canvas] size. If false, they are kept.
  static List<ModelPixel> rasterLinePixels({
    required ModelCanvas canvas,
    required ModelPixel origin,
    required ModelPixel destiny,
    String? hexColorOverride,
    bool clipToCanvasBounds = true,
  }) {
    final String color = hexColorOverride ?? origin.hexColor;
    int x0 = origin.x, y0 = origin.y;
    final int x1 = destiny.x, y1 = destiny.y;

    final int dx = (x1 - x0).abs();
    final int dy = (y1 - y0).abs();
    final int sx = x0 < x1 ? 1 : -1;
    final int sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;

    final List<ModelPixel> out = <ModelPixel>[];

    while (true) {
      if (!clipToCanvasBounds || _inBounds(canvas, x0, y0)) {
        out.add(ModelPixel.fromCoord(x0, y0, hexColor: color));
      }
      if (x0 == x1 && y0 == y1) {
        break;
      }

      final int e2 = err << 1;
      if (e2 > -dy) {
        err -= dy;
        x0 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y0 += sy;
      }
    }
    return out;
  }
}
