import 'dart:ui';

import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../shared/util_color.dart';

/// Represents a theme with a single color, creation date, and description.
///
/// Uses [UtilColor] for hex conversion when serializing/deserializing.
///
/// Example:
/// ```dart
/// final Map<String, dynamic> json = {
///   'color': '#FF6200EE',
///   'createdAt': '2025-01-01T00:00:00.000Z',
///   'description': 'Primary theme color',
///};
/// final ModelTheme theme = ModelTheme.fromJson(json);
/// final Map<String, dynamic> output = theme.toJson();
/// // output['color'] == '#FF6200EE'
/// ```
class ModelTheme extends Model {
  const ModelTheme({
    required this.color,
    required this.createdAt,
    required this.description,
  });

  /// Creates a [ModelTheme] from a JSON-like map.
  factory ModelTheme.fromJson(Map<String, dynamic> json) {
    final String hexColor = Utils.getStringFromDynamic(json['color']);
    final Color color = UtilColor.hexToColor(hexColor);

    return ModelTheme(
      color: color,
      createdAt: DateUtils.dateTimeFromDynamic(json['createdAt']),
      description: Utils.getStringFromDynamic(json['description']),
    );
  }

  /// The primary color of the theme.
  final Color color;

  /// The creation timestamp of the theme.
  final DateTime createdAt;

  /// A short description of the theme.
  final String description;

  @override
  ModelTheme copyWith({
    Color? color,
    DateTime? createdAt,
    String? description,
  }) {
    return ModelTheme(
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'color': UtilColor.colorToHex(color),
      'createdAt': createdAt.toIso8601String(),
      'description': description,
    };
  }
}
