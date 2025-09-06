import 'dart:math';

import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype_domain.dart';

import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';
import '../../shared/util_color.dart';
import 'model_vector_bridge.dart';

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

  /// Returns the pixels of a rectangle defined by two opposite corners.
  /// If [fill] is true, fills the area. Otherwise draws the border with [stroke].
  static List<ModelPixel> rasterRectPixels({
    required ModelCanvas canvas,
    required ModelPixel p1,
    required ModelPixel p2,
    required String hexColor,
    bool fill = false,
    int stroke = 1,
  }) {
    final int minX = _clamp(0, canvas.width - 1, p1.x < p2.x ? p1.x : p2.x);
    final int maxX = _clamp(0, canvas.width - 1, p1.x > p2.x ? p1.x : p2.x);
    final int minY = _clamp(0, canvas.height - 1, p1.y < p2.y ? p1.y : p2.y);
    final int maxY = _clamp(0, canvas.height - 1, p1.y > p2.y ? p1.y : p2.y);
    final List<ModelPixel> out = <ModelPixel>[];
    if (minX > maxX || minY > maxY) {
      return <ModelPixel>[];
    }

    final Set<String> seen = <String>{};
    void add(int x, int y) {
      if (x < 0 || y < 0 || x >= canvas.width || y >= canvas.height) {
        return;
      }
      final ModelPixel px = ModelPixel.fromCoord(x, y, hexColor: hexColor);
      if (seen.add(px.keyForCanvas)) {
        out.add(px);
      }
    }

    final int w = (maxX - minX) + 1;
    final int h = (maxY - minY) + 1;

    if (fill || w <= 2 || h <= 2) {
      // FILL (o rectángulos demasiado pequeños para stroke interno)
      for (int y = minY; y <= maxY; y++) {
        for (int x = minX; x <= maxX; x++) {
          add(x, y);
        }
      }
      return out;
    }

    // STROKE: clamp thickness
    final int t = stroke < 1 ? 1 : stroke;
    final int tX = t > w ? w : t;
    final int tY = t > h ? h : t;

    // Tiras superior e inferior
    for (int y = minY; y < minY + tY; y++) {
      for (int x = minX; x <= maxX; x++) {
        add(x, y);
      }
    }
    for (int y = maxY - tY + 1; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        add(x, y);
      }
    }

    // Tiras izquierda y derecha (sin volver a pintar lo ya cubierto)
    for (int x = minX; x < minX + tX; x++) {
      for (int y = minY + tY; y <= maxY - tY; y++) {
        add(x, y);
      }
    }
    for (int x = maxX - tX + 1; x <= maxX; x++) {
      for (int y = minY + tY; y <= maxY - tY; y++) {
        add(x, y);
      }
    }

    return out;
  }

  /// Draws a rectangle into a new canvas snapshot.
  static ModelCanvas drawRect({
    required ModelCanvas canvas,
    required ModelPixel p1,
    required ModelPixel p2,
    String? hexColorOverride,
    bool fill = false,
    int stroke = 1,
    bool overwrite = true,
  }) {
    final String hex = UtilColor.normalizeHex(hexColorOverride ?? p1.hexColor);
    final List<ModelPixel> pixels = rasterRectPixels(
      canvas: canvas,
      p1: p1,
      p2: p2,
      hexColor: hex,
      fill: fill,
      stroke: stroke,
    );

    final Map<String, ModelPixel> m = Map<String, ModelPixel>.from(
      canvas.pixels,
    );
    for (final ModelPixel px in pixels) {
      final String k = px.keyForCanvas;
      if (overwrite || !m.containsKey(k)) {
        m[k] = px;
      }
    }
    return canvas.copyWith(pixels: Map<String, ModelPixel>.unmodifiable(m));
  }

  static int _clamp(int min, int max, int v) =>
      v < min ? min : (v > max ? max : v);

  /// Internal: bounds check.
  static bool _inside(ModelCanvas c, int x, int y) =>
      x >= 0 && y >= 0 && x < c.width && y < c.height;

  static void _setPx(Map<String, ModelPixel> acc, int x, int y, String hex) {
    final String k = '$x,$y';
    acc[k] = ModelPixel.fromCoord(x, y, hexColor: hex);
  }

  /// Returns integer distance rounded for circle radius from `center` to `p`.
  static int _radiusFromTwoPoints(ModelVector center, ModelVector p) {
    final int dx = (p.x - center.x).abs();
    final int dy = (p.y - center.y).abs();
    return sqrt(dx * dx + dy * dy).round();
  }

  /// Rasterize a circle (midpoint algorithm) as perimeter set.
  static List<ModelVector> _midpointCircle(int cx, int cy, int r) {
    final List<ModelVector> pts = <ModelVector>[];
    int x = r;
    int y = 0;
    int err = 1 - r;
    while (x >= y) {
      pts.addAll(<ModelVector>[
        defaultModelVector.fromXY(cx + x, cy + y),
        defaultModelVector.fromXY(cx + y, cy + x),
        defaultModelVector.fromXY(cx - y, cy + x),
        defaultModelVector.fromXY(cx - x, cy + y),
        defaultModelVector.fromXY(cx - x, cy - y),
        defaultModelVector.fromXY(cx - y, cy - x),
        defaultModelVector.fromXY(cx + y, cy - x),
        defaultModelVector.fromXY(cx + x, cy - y),
      ]);
      y++;
      if (err < 0) {
        err += 2 * y + 1;
      } else {
        x--;
        err += 2 * (y - x) + 1;
      }
    }
    return pts;
  }

  /// Rasterize a filled circle (horizontal spans).
  static Iterable<ModelVector> _filledCircleSpans(int cx, int cy, int r) sync* {
    int x = r;
    int y = 0;
    int err = 1 - r;
    while (x >= y) {
      // For each octant pair, emit horizontal spans
      for (int xx = cx - x; xx <= cx + x; xx++) {
        yield defaultModelVector.fromXY(xx, cy + y);
        yield defaultModelVector.fromXY(xx, cy - y);
      }
      for (int xx = cx - y; xx <= cx + y; xx++) {
        yield defaultModelVector.fromXY(xx, cy + x);
        yield defaultModelVector.fromXY(xx, cy - x);
      }

      y++;
      if (err < 0) {
        err += 2 * y + 1;
      } else {
        x--;
        err += 2 * (y - x) + 1;
      }
    }
  }

  /// Adds a rasterized circle to the canvas pixels list (returns new canvas).
  ///
  /// If [fill] is true, fills the circle; otherwise draws only the outline.
  /// [stroke] thickens the outline/fill border by drawing concentric rings.
  /// When [radius] <= 0 nothing is changed.
  static ModelCanvas drawCircle({
    required ModelCanvas canvas,
    required ModelVector center,
    required int radius,
    required String hexColor,
    bool fill = false,
    int stroke = 1,
    bool overwrite = true,
  }) {
    if (radius <= 0) {
      return canvas;
    }
    final Map<String, ModelPixel> acc = Map<String, ModelPixel>.from(
      canvas.pixels,
    );
    final int cx = center.x, cy = center.y;
    final String hex = UtilColor.normalizeHex(hexColor);

    if (fill) {
      // Fill once, then optionally accent border thickness by overlaying outlines
      for (final ModelVector p in _filledCircleSpans(cx, cy, radius)) {
        if (_inside(canvas, p.x, p.y)) {
          _setPx(acc, p.x, p.y, hex);
        }
      }
      for (int t = 0; t < stroke - 1; t++) {
        final int rr = radius + t + 1;
        for (final ModelVector p in _midpointCircle(cx, cy, rr)) {
          if (_inside(canvas, p.x, p.y)) {
            _setPx(acc, p.x, p.y, hex);
          }
        }
      }
    } else {
      for (int t = 0; t < stroke; t++) {
        final int rr = radius + t;
        for (final ModelVector p in _midpointCircle(cx, cy, rr)) {
          if (_inside(canvas, p.x, p.y)) {
            _setPx(acc, p.x, p.y, hex);
          }
        }
      }
    }

    return canvas.copyWith(pixels: Map<String, ModelPixel>.unmodifiable(acc));
  }

  /// Rasterize an ellipse outline (midpoint ellipse) centered at (cx,cy) with
  /// radii a (x-axis) and b (y-axis).
  static List<ModelVector> _midpointEllipse(int cx, int cy, int a, int b) {
    final List<ModelVector> pts = <ModelVector>[];
    int x = 0;
    int y = b;
    // Region 1
    final double a2 = (a * a).toDouble();
    final double b2 = (b * b).toDouble();
    double d1 = b2 - a2 * b + 0.25 * a2;
    while ((b2 * x) <= (a2 * y)) {
      pts.addAll(<ModelVector>[
        defaultModelVector.fromXY(cx + x, cy + y),
        defaultModelVector.fromXY(cx - x, cy + y),
        defaultModelVector.fromXY(cx - x, cy - y),
        defaultModelVector.fromXY(cx + x, cy - y),
      ]);
      if (d1 < 0) {
        x++;
        d1 += b2 * (2 * x + 1);
      } else {
        x++;
        y--;
        d1 += b2 * (2 * x + 1) + a2 * (-2 * y);
      }
    }
    // Region 2
    double d2 = b2 * (x + 0.5) * (x + 0.5) + a2 * (y - 1) * (y - 1) - a2 * b2;
    while (y >= 0) {
      pts.addAll(<ModelVector>[
        defaultModelVector.fromXY(cx + x, cy + y),
        defaultModelVector.fromXY(cx - x, cy + y),
        defaultModelVector.fromXY(cx - x, cy - y),
        defaultModelVector.fromXY(cx + x, cy - y),
      ]);
      if (d2 > 0) {
        y--;
        d2 += a2 * (-2 * y + 1);
      } else {
        y--;
        x++;
        d2 += b2 * (2 * x) + a2 * (-2 * y + 1);
      }
    }
    return pts;
  }

  /// Filled ellipse as vertical spans computed by solving y for each x column.
  static Iterable<ModelVector> _filledEllipseSpans(
    int cx,
    int cy,
    int a,
    int b,
  ) sync* {
    if (a <= 0 || b <= 0) {
      return;
    }
    for (int x = -a; x <= a; x++) {
      // y = b * sqrt(1 - (x^2 / a^2))
      final double t = 1.0 - (x * x) / (a * a);
      final int y = t <= 0 ? 0 : (b * sqrt(t)).round();
      for (int yy = -y; yy <= y; yy++) {
        yield defaultModelVector.fromXY(cx + x, cy + yy);
      }
    }
  }

  /// Adds a rasterized oval (ellipse) defined by opposite corners [p1] & [p2].
  ///
  /// If [fill] is true, fills the oval; otherwise draws only the outline.
  /// [stroke] thickens the outline by drawing additional perimeters outward.
  static ModelCanvas drawOvalCorners({
    required ModelCanvas canvas,
    required ModelVector p1,
    required ModelVector p2,
    required String hexColor,
    bool fill = false,
    int stroke = 1,
    bool overwrite = true,
  }) {
    final Map<String, ModelPixel> acc = Map<String, ModelPixel>.from(
      canvas.pixels,
    );
    final String hex = UtilColor.normalizeHex(hexColor);

    final int minX = min(p1.x, p2.x);
    final int maxX = max(p1.x, p2.x);
    final int minY = min(p1.y, p2.y);
    final int maxY = max(p1.y, p2.y);

    final int w = maxX - minX + 1;
    final int h = maxY - minY + 1;
    if (w <= 0 || h <= 0) {
      return canvas;
    }

    final int cx = (minX + maxX) ~/ 2;
    final int cy = (minY + maxY) ~/ 2;
    final int a = w ~/ 2; // radius x
    final int b = h ~/ 2; // radius y

    if (fill) {
      for (final ModelVector p in _filledEllipseSpans(cx, cy, a, b)) {
        if (_inside(canvas, p.x, p.y)) {
          _setPx(acc, p.x, p.y, hex);
        }
      }
      for (int t = 0; t < stroke - 1; t++) {
        for (final ModelVector p in _midpointEllipse(
          cx,
          cy,
          a + t + 1,
          b + t + 1,
        )) {
          if (_inside(canvas, p.x, p.y)) {
            _setPx(acc, p.x, p.y, hex);
          }
        }
      }
    } else {
      for (int t = 0; t < stroke; t++) {
        for (final ModelVector p in _midpointEllipse(cx, cy, a + t, b + t)) {
          if (_inside(canvas, p.x, p.y)) {
            _setPx(acc, p.x, p.y, hex);
          }
        }
      }
    }

    return canvas.copyWith(pixels: Map<String, ModelPixel>.unmodifiable(acc));
  }

  /// Convenience to preview circle from two points: center & edge.
  static List<ModelPixel> rasterCirclePixels({
    required ModelCanvas canvas,
    required ModelVector center,
    required ModelVector edge,
    required String hexColor,
    bool fill = false,
    int stroke = 1,
  }) {
    final int r = _radiusFromTwoPoints(center, edge);
    final ModelCanvas next = drawCircle(
      canvas: canvas,
      center: center,
      radius: r,
      hexColor: hexColor,
      fill: fill,
      stroke: stroke,
    );
    return next.pixels.values.toList();
  }

  /// Convenience to preview oval from two corners.
  static List<ModelPixel> rasterOvalPixels({
    required ModelCanvas canvas,
    required ModelVector p1,
    required ModelVector p2,
    required String hexColor,
    bool fill = false,
    int stroke = 1,
  }) {
    final ModelCanvas next = drawOvalCorners(
      canvas: canvas,
      p1: p1,
      p2: p2,
      hexColor: hexColor,
      fill: fill,
      stroke: stroke,
    );
    return next.pixels.values.toList();
  }

  static int getX(ModelVector modelVector) => modelVector.dx.round();
  static int getY(ModelVector modelVector) => modelVector.dy.round();
  static String keyFromModelVector(ModelVector modelVector) =>
      '${modelVector.dx},${modelVector.dy}';
  static ModelVector copyWithInts({
    required ModelVector modelVector,
    int? x,
    int? y,
  }) => ModelVector(
    (x ?? modelVector.dx).toDouble(),
    (y ?? modelVector.dy).toDouble(),
  );

  static ModelVector fromXY(int x, int y) =>
      ModelVector(x.toDouble(), y.toDouble());
}
