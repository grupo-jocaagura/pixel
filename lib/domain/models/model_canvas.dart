import 'package:flutter/foundation.dart';
import 'package:jocaagura_domain/jocaagura_domain.dart';

import 'model_pixel.dart';

/// Defines the keys for JSON serialization of [ModelCanvas].
enum ModelCanvasEnum { id, width, height, pixelSize, pixels }

const ModelCanvas defaultModelCanvas = ModelCanvas(
  id: 'default_app_canvas',
  width: 40,
  height: 40,
  pixelSize: 1.0,
  pixels: <String, ModelPixel>{},
);

/// Represents a persistible pixel-art canvas in the domain layer.
///
/// - [id]: optional identifier for the canvas document.
/// - [width], [height]: logical dimensions in number of pixels.
/// - [pixelSize]: business unit size of each pixel.
/// - [pixels]: list of active pixels with position and color.
@immutable
class ModelCanvas extends Model {
  const ModelCanvas({
    required this.width,
    required this.height,
    required this.pixelSize,
    required this.pixels,
    this.id = '',
  });

  /// Creates a [ModelCanvas] from a JSON map, using [Utils] for safe conversions.
  factory ModelCanvas.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawPixels = Utils.mapFromDynamic(
      json[ModelCanvasEnum.pixels.name],
    );
    final Map<String, ModelPixel> parsedPixels = <String, ModelPixel>{};

    for (final MapEntry<String, dynamic> entry in rawPixels.entries) {
      parsedPixels[entry.key] = ModelPixel.fromJson(
        Utils.mapFromDynamic(entry.value),
      );
    }

    return ModelCanvas(
      id: Utils.getStringFromDynamic(json[ModelCanvasEnum.id.name]),
      width: Utils.getIntegerFromDynamic(json[ModelCanvasEnum.width.name]),
      height: Utils.getIntegerFromDynamic(json[ModelCanvasEnum.height.name]),
      pixelSize: Utils.getDouble(json[ModelCanvasEnum.pixelSize.name]),
      pixels: Map<String, ModelPixel>.unmodifiable(parsedPixels),
    );
  }

  /// Optional canvas identifier for persistence.
  final String? id;

  /// Number of columns (logical width) of the canvas.
  final int width;

  /// Number of rows (logical height) of the canvas.
  final int height;

  /// Business unit size of each pixel in the canvas.
  final double pixelSize;

  /// Active pixels on the canvas.
  final Map<String, ModelPixel> pixels;

  /// Returns a new copy of this canvas with the given fields replaced.
  @override
  ModelCanvas copyWith({
    String? id,
    int? width,
    int? height,
    double? pixelSize,
    Map<String, ModelPixel>? pixels,
  }) {
    return ModelCanvas(
      id: id ?? this.id,
      width: width ?? this.width,
      height: height ?? this.height,
      pixelSize: pixelSize ?? this.pixelSize,
      pixels: pixels ?? this.pixels,
    );
  }

  /// Converts this [ModelCanvas] into a JSON map.
  ///
  /// Includes [id] if non-null.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) ModelCanvasEnum.id.name: id,
    ModelCanvasEnum.width.name: width,
    ModelCanvasEnum.height.name: height,
    ModelCanvasEnum.pixelSize.name: pixelSize,
    ModelCanvasEnum.pixels.name: pixels.map(
      (String key, ModelPixel pixel) =>
          MapEntry<String, Map<String, dynamic>>(key, pixel.toJson()),
    ),
  };

  /// Value equality for [ModelCanvas].
  ///
  /// Two canvases are equal if all fields and pixel data match.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ModelCanvas &&
        other.id == id &&
        other.width == width &&
        other.height == height &&
        other.pixelSize == pixelSize &&
        _mapEquals(other.pixels, pixels);
  }

  @override
  int get hashCode {
    return Object.hash(id, width, height, pixelSize, pixels);
  }

  /// Helper for deep equality of pixel maps.
  ///
  /// Returns true if both maps have identical keys and corresponding pixel values.
  bool _mapEquals(Map<String, ModelPixel> a, Map<String, ModelPixel> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final String key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    return 'ModelCanvas(id: $id, '
        'size: $width×$height @ $pixelSize, '
        'pixels: ${pixels.length})';
  }
}
