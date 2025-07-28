import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel/domain/models/model_theme.dart';

void main() {
  group('ModelTheme.fromJson', () {
    const String nowIso = '2025-01-01T12:34:56.000Z';
    final DateTime now = DateTime.parse(nowIso);

    test('parses all fields correctly', () {
      final Map<String, String> json = <String, String>{
        'color': '#FF112233',
        'createdAt': nowIso,
        'description': 'Test theme',
      };
      final ModelTheme theme = ModelTheme.fromJson(json);

      expect(theme.color, equals(const Color(0xFF112233)));
      expect(theme.createdAt, equals(now));
      expect(theme.description, equals('Test theme'));
    });
  });

  group('ModelTheme.toJson', () {
    final DateTime now = DateTime.parse('2025-01-01T12:34:56.000Z');

    test('produces correct map', () {
      final ModelTheme theme = ModelTheme(
        color: const Color(0xFF112233),
        createdAt: now,
        description: 'Output test',
      );
      final Map<String, dynamic> json = theme.toJson();

      expect(json['color'], '#FF112233');
      expect(json['createdAt'], now.toIso8601String());
      expect(json['description'], 'Output test');
    });
  });

  group('ModelTheme.copyWith', () {
    final ModelTheme base = ModelTheme(
      color: const Color(0xFF112233),
      createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
      description: 'Base',
    );

    test('updates only specified fields', () {
      final ModelTheme updated = base.copyWith(
        color: const Color(0xFF445566),
        description: 'Updated',
      );

      expect(updated.color, equals(const Color(0xFF445566)));
      expect(updated.description, equals('Updated'));
      expect(updated.createdAt, equals(base.createdAt));
    });

    test('original remains unchanged', () {
      base.copyWith(description: 'New');
      expect(base.description, equals('Base'));
    });

    test('original remains description unchanged', () {
      final ModelTheme newTheme = base.copyWith();
      expect(newTheme.description, equals('Base'));
    });
  });
}
