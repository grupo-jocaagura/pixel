import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/models/model_pixel.dart';

/// Tool selector for previewing draw commands.
enum DrawTool { line, rect /*, circle, oval*/ }

/// Immutable state for the preview bloc.
@immutable
class StatePreview {
  const StatePreview({
    required this.tool,
    required this.showCoords,
    required this.fill,
    required this.stroke,
    required this.origin,
    required this.destiny,
    required this.previewPixels,
  });

  final DrawTool tool;
  final bool showCoords;
  final bool fill;
  final int stroke;

  /// For line: origin/destiny.
  /// For rect: opposite corners (p1=origin, p2=destiny).
  final Point<int>? origin;
  final Point<int>? destiny;

  final List<ModelPixel> previewPixels;

  bool get hasSelection => tool == DrawTool.line
      ? (origin != null && destiny != null)
      : (origin != null && destiny != null);

  StatePreview copyWith({
    DrawTool? tool,
    bool? showCoords,
    bool? fill,
    int? stroke,
    Point<int>? origin,
    Point<int>? destiny,
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
