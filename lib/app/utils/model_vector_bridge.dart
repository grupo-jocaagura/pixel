import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

extension ModelVectorIntView on ModelVector {
  int get x => dx.round();
  int get y => dy.round();
  String get key => '$x,$y';
  ModelVector copyWithInts({int? x, int? y}) =>
      ModelVector((x ?? this.x).toDouble(), (y ?? this.y).toDouble());
}

extension ModelVectorFactories on ModelVector {
  ModelVector fromXY(int x, int y) => ModelVector(x.toDouble(), y.toDouble());
}
