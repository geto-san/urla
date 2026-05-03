import 'dart:math' as math;

/// Immutable 2D geometric point used throughout the perception pipeline.
class Point {

  final double x;
  final double y;

  const Point(this.x, this.y);

  factory Point.fromInt(int x, int y) {
    return Point(x.toDouble(), y.toDouble());
  }

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }

  /// Euclidean distance
  double distanceTo(Point other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Midpoint
  Point midpoint(Point other) {
    return Point(
      (x + other.x) / 2,
      (y + other.y) / 2,
    );
  }

  /// Vector magnitude
  double get magnitude => math.sqrt(x * x + y * y);

  /// Safe normalization
  Point normalize() {
    final mag = magnitude;

    if (mag == 0) {
      return const Point(0, 0);
    }

    return Point(x / mag, y / mag);
  }

  /// Scale vector
  Point scale(double sx, double sy) {
    return Point(x * sx, y * sy);
  }

  /// Vector addition
  Point operator +(Point other) {
    return Point(x + other.x, y + other.y);
  }

  /// Vector subtraction
  Point operator -(Point other) {
    return Point(x - other.x, y - other.y);
  }

  @override
  String toString() => 'Point(x:$x,y:$y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}