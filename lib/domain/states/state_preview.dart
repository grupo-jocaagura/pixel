import 'package:flutter/foundation.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../domain/models/model_pixel.dart';

/// Tool selector for previewing draw commands.
enum DrawTool { line, rect, circle, oval }

/// Keys for JSON (opcional pero útil para estabilidad).
enum _PreviewKey {
  tool,
  showCoords,
  fill,
  stroke,
  originX,
  originY,
  destinyX,
  destinyY,
}

/// Immutable, serializable preview state.
@immutable
class StatePreview extends Model {
  const StatePreview({
    required this.tool,
    required this.showCoords,
    required this.fill,
    required this.stroke,
    required this.origin,
    required this.destiny,
    required this.previewPixels,
  });
  factory StatePreview.fromJson(Map<String, dynamic> json) {
    final String toolStr = Utils.getStringFromDynamic(
      json[_PreviewKey.tool.name],
    );
    final DrawTool tool = DrawTool.values.firstWhere(
      (DrawTool e) => e.name == toolStr,
      orElse: () => DrawTool.line,
    );
    final double ox = Utils.getDouble(json[_PreviewKey.originX.name]);
    final double oy = Utils.getDouble(json[_PreviewKey.originY.name]);
    final double dx = Utils.getDouble(json[_PreviewKey.destinyX.name]);
    final double dy = Utils.getDouble(json[_PreviewKey.destinyY.name]);

    return StatePreview(
      tool: tool,
      showCoords: Utils.getBoolFromDynamic(json[_PreviewKey.showCoords.name]),
      fill: Utils.getBoolFromDynamic(json[_PreviewKey.fill.name]),
      stroke: Utils.getIntegerFromDynamic(json[_PreviewKey.stroke.name] ?? '1'),
      origin: ModelVector(ox, oy),
      destiny: ModelVector(dx, dy),
      previewPixels: const <ModelPixel>[],
    );
  }

  final DrawTool tool;
  final bool showCoords;
  final bool fill;
  final int stroke;

  /// origin/destiny como ModelVector (int-friendly vía extension).
  final ModelVector? origin;
  final ModelVector? destiny;

  /// DERIVED (no se serializa).
  final List<ModelPixel> previewPixels;

  bool get hasSelection {
    switch (tool) {
      case DrawTool.line:
      case DrawTool.rect:
      case DrawTool.circle:
      case DrawTool.oval:
        return origin != null && destiny != null;
    }
  }

  @override
  StatePreview copyWith({
    DrawTool? tool,
    bool? showCoords,
    bool? fill,
    int? stroke,
    ModelVector? origin,
    ModelVector? destiny,
    List<ModelPixel>? previewPixels,
    bool clearOrigin = false,
    bool clearDestiny = false,
  }) {
    return StatePreview(
      tool: tool ?? this.tool,
      showCoords: showCoords ?? this.showCoords,
      fill: fill ?? this.fill,
      stroke: stroke ?? this.stroke,
      origin: clearOrigin ? null : (origin ?? this.origin),
      destiny: clearDestiny ? null : (destiny ?? this.destiny),
      previewPixels: previewPixels ?? this.previewPixels,
    );
  }

  /// Serializa SOLO lo necesario para rehidratar. `previewPixels` es derivado.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    _PreviewKey.tool.name: tool.name,
    _PreviewKey.showCoords.name: showCoords,
    _PreviewKey.fill.name: fill,
    _PreviewKey.stroke.name: stroke,
    _PreviewKey.originX.name: origin?.dx,
    _PreviewKey.originY.name: origin?.dy,
    _PreviewKey.destinyX.name: destiny?.dx,
    _PreviewKey.destinyY.name: destiny?.dy,
  };

  /// Value equality
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatePreview &&
          other.tool == tool &&
          other.showCoords == showCoords &&
          other.fill == fill &&
          other.stroke == stroke &&
          other.origin == origin &&
          other.destiny == destiny &&
          listEquals(other.previewPixels, previewPixels);

  @override
  int get hashCode => Object.hash(
    tool,
    showCoords,
    fill,
    stroke,
    origin,
    destiny,
    Object.hashAll(previewPixels),
  );

  static const StatePreview initial = StatePreview(
    tool: DrawTool.line,
    showCoords: true,
    fill: false,
    stroke: 1,
    origin: null,
    destiny: null,
    previewPixels: <ModelPixel>[],
  );
}
