import 'package:flutter/foundation.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../shared/util_color.dart';

/// Keys for JSON serialization in [ModelPixel].
enum ModelPixelEnum { x, y, hexColor }

/// A pixel in the domain layer, defined by a 2D position and a hex color.
///
/// This model is immutable and suitable for persistence. It uses [ModelVector]
/// for coordinates and [UtilColor] to normalize and validate hex color values.
@immutable
class ModelPixel extends Model {
  /// Constructs a [ModelPixel] with the given [vector] position and [hexColor].
  ///
  /// [hexColor] is assumed to be a valid uppercase hex string (e.g. `#FF00FF`).
  const ModelPixel({required this.vector, required this.hexColor});

  /// Creates a [ModelPixel] from a JSON-like map.
  ///
  /// Reads the following keys from [json]:
  /// - `${ModelPixelEnum.x.name}`: x-coordinate as double.
  /// - `${ModelPixelEnum.y.name}`: y-coordinate as double.
  /// - `${ModelPixelEnum.hexColor.name}`: hex color string.
  ///
  /// If the provided hex is invalid or missing, falls back to [defaultHexColor].
  factory ModelPixel.fromJson(Map<String, dynamic> json) {
    final String jsonColor = UtilColor.normalizeHex(
      Utils.getStringFromDynamic(json[ModelPixelEnum.hexColor.name]),
    );

    return ModelPixel(
      vector: ModelVector(
        Utils.getDouble(json[ModelPixelEnum.x.name]),
        Utils.getDouble(json[ModelPixelEnum.y.name]),
      ),
      hexColor: jsonColor,
    );
  }

  /// Creates a [ModelPixel] from integer coordinates and a hex color.
  ///
  /// The [x] and [y] parameters become the pixel position. The provided
  /// [hexColor] is not validated here; use [ModelPixel.fromJson] to enforce
  /// normalization and defaulting.
  factory ModelPixel.fromCoord(int x, int y, {required String hexColor}) {
    return ModelPixel(
      vector: ModelVector(x.toDouble(), y.toDouble()),
      hexColor: hexColor,
    );
  }

  /// The 2D position of this pixel in logical units.
  final ModelVector vector;

  /// The hexadecimal color string of this pixel (uppercase, `#RRGGBB` or
  /// `#AARRGGBB`).
  final String hexColor;

  static String get defaultHexColor => UtilColor.defaultHexColor;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ModelPixelEnum.x.name: vector.dx,
      ModelPixelEnum.y.name: vector.dy,
      ModelPixelEnum.hexColor.name: hexColor,
    };
  }

  @override
  ModelPixel copyWith({ModelVector? vector, String? hexColor}) {
    return ModelPixel(
      vector: vector ?? this.vector,
      hexColor: hexColor ?? this.hexColor,
    );
  }

  /// Returns a copy of this pixel with optional new [vector] or [hexColor].
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ModelPixel &&
            other.vector == vector &&
            other.hexColor == hexColor);
  }

  /// Value equality: two pixels are equal if their [vector] and [hexColor]
  /// match.
  @override
  int get hashCode => Object.hash(vector, hexColor);

  /// The x-coordinate as an integer (rounded from [vector.dx]).
  int get x => vector.dx.round();

  /// The y-coordinate as an integer (rounded from [vector.dy]).
  int get y => vector.dy.round();

  /// A concise string representation for debugging: includes x, y, and color.
  @override
  String toString() => 'Pixel(x: $x, y: $y, color: $hexColor)';

  String get keyForCanvas {
    return '${vector.dx.round()},${vector.dy.round()}';
  }
}
