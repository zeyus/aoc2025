// https://adventofcode.com/2025/day/9
// I solved part 1 no problems, but I needed a bit of help with part 2
import 'dart:collection';
import 'dart:io';

class Vector2 {
  final num x;
  final num y;
  final bool verbose;

  Vector2(this.x, this.y, {this.verbose = false});

  num areaOf(Vector2 other) {
    final area = ((other.x - x).abs() + 1) * ((other.y - y).abs() + 1);
    return area;
  }

  num get manhattanDistance => x.abs() + y.abs();

  @override
  String toString() => '($x,$y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector2 && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class Edge {
  final Vector2 from;
  final Vector2 to;
  late final int _angle;
  late final bool _isVertical;

  int get angle => _angle;
  bool get isVertical => _isVertical;
  bool get isHorizontal => !_isVertical;
  // assimung clockwise, we can define an inside and outside
  int calcAngle() {
    if (_isVertical) {
      return to.y > from.y ? 90 : 270;
    } else {
      return to.x > from.x ? 0 : 180;
    }
  }

  bool calcVertical() {
    return from.x == to.x; // This can be wrong if it is 1 unit wide
  }

  num get maxX => from.x > to.x ? from.x : to.x;
  num get minX => from.x < to.x ? from.x : to.x;
  num get maxY => from.y > to.y ? from.y : to.y;
  num get minY => from.y < to.y ? from.y : to.y;

  Edge(this.from, this.to, {int? angle}) {
    if (angle != null) {
      _angle = angle;
      _isVertical = (angle == 90 || angle == 270);
    } else {
      _isVertical = calcVertical();
      _angle = calcAngle();
    }
  }

  bool containsPoint(Vector2 point, {bool inclusive = true}) {
    // For rectilinear (axis-aligned) edges, check if point is ON the line segment
    if (isHorizontal) {
      // Horizontal edge: y must match, x must be within range
      if (point.y != from.y) return false;
      final withinX = inclusive
          ? (point.x >= minX && point.x <= maxX)
          : (point.x > minX && point.x < maxX);
      return withinX;
    } else if (isVertical) {
      // Vertical edge: x must match, y must be within range
      if (point.x != from.x) return false;
      final withinY = inclusive
          ? (point.y >= minY && point.y <= maxY)
          : (point.y > minY && point.y < maxY);
      return withinY;
    } else {
      // For non-axis-aligned edges, use bounding box (fallback)
      final withinX = inclusive
          ? (point.x >= minX && point.x <= maxX)
          : (point.x > minX && point.x < maxX);
      final withinY = inclusive
          ? (point.y >= minY && point.y <= maxY)
          : (point.y > minY && point.y < maxY);
      return withinX && withinY;
    }
  }

  Vector2 intersect(Edge other) {
    final num x1 = from.x;
    final num y1 = from.y;
    final num x2 = to.x;
    final num y2 = to.y;

    final num x3 = other.from.x;
    final num y3 = other.from.y;
    final num x4 = other.to.x;
    final num y4 = other.to.y;

    final denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if (denom == 0) {
      // parallel lines
      return Vector2(double.nan, double.nan);
    }

    final px =
        ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) /
        denom;
    final py =
        ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) /
        denom;

    return Vector2(px, py);
  }

  @override
  String toString() => 'Edge(from: $from, to: $to)';
}

class Polygon {
  final List<Vector2> vertices;
  final List<Edge> edges = [];
  final Set<Vector2> _tracedEdges = {};
  final bool verbose;
  late final num xMin;
  late final num xMax;
  late final num yMin;
  late final num yMax;

  Polygon(this.vertices, {addEdges = true, this.verbose = false}) {
    num xmin = vertices.first.x;
    num xmax = vertices.first.x;
    num ymin = vertices.first.y;
    num ymax = vertices.first.y;

    for (int i = 0; i < vertices.length; i++) {
      if (vertices[i].x < xmin) {
        xmin = vertices[i].x;
      }
      if (vertices[i].x > xmax) {
        xmax = vertices[i].x;
      }
      if (vertices[i].y < ymin) {
        ymin = vertices[i].y;
      }
      if (vertices[i].y > ymax) {
        ymax = vertices[i].y;
      }
      if (addEdges) {
        edges.add(Edge(vertices[i], vertices[(i + 1) % vertices.length]));
      }
    }
    // Note: The closing edge from last to first is already added by the loop above
    // when i = length-1, via the modulo operation
    xMin = xmin;
    xMax = xmax;
    yMin = ymin;
    yMax = ymax;
  }

  Set<Vector2> traceEdges() {
    if (_tracedEdges.isNotEmpty) {
      return _tracedEdges;
    }

    final Queue<Vector2> tracedPoints = Queue<Vector2>();

    for (final edge in edges) {
      if (edge.isHorizontal) {
        final y = edge.from.y;
        final xStart = edge.minX;
        final xEnd = edge.maxX;
        for (num x = xStart; x <= xEnd; x++) {
          tracedPoints.add(Vector2(x, y));
        }
      } else if (edge.isVertical) {
        final x = edge.from.x;
        final yStart = edge.minY;
        final yEnd = edge.maxY;
        for (num y = yStart; y <= yEnd; y++) {
          tracedPoints.add(Vector2(x, y));
        }
      } else {
        throw StateError('Edge is neither horizontal nor vertical: $edge');
      }
    }
    _tracedEdges.addAll(tracedPoints);
    return _tracedEdges;
  }

  // Ray casting algorithm for point-in-polygon test
  // For rectilinear polygons (only horizontal and vertical edges)
  bool containsPoint(Vector2 point) {
    // Check if point lies on any edge (treat boundary points as inside)
    for (final edge in edges) {
      if (edge.containsPoint(point)) {
        return true;
      }
    }

    // Use the point coordinates directly (no offset)
    final testX = point.x;
    final testY = point.y;

    int crossings = 0;

    // Cast a ray from point to the right (increasing x)
    for (final edge in edges) {
      // Skip horizontal edges (parallel to ray)
      if (edge.isHorizontal) continue;

      // Check if the vertical edge crosses the ray
      // Use half-open interval [minY, maxY) to handle boundaries correctly
      final bool yInRange = (edge.minY <= testY && testY < edge.maxY);

      // Edge must be strictly to the right of the point
      if (yInRange && edge.from.x > testX) {
        crossings++;
      }
    }

    // Odd number of crossings means inside
    return crossings % 2 == 1;
  }

  Future<bool> containsRectangle(
    Rectangle rectangle, {
    Vector2? cornerA,
    Vector2? cornerB,
  }) async {
    // Check if all four corners are inside the polygon
    for (final point in rectangle.vertices) {
      if (!containsPoint(point)) {
        if (verbose) {
          print('- Rectangle point $point is outside polygon.');
        }
        return false;
      }
    }

    // Check if any polygon vertices are strictly inside the rectangle
    // (This would mean the polygon boundary intrudes into the rectangle)
    // Exclude the two vertices that define the rectangle corners
    for (final vertex in vertices) {
      // Skip the two red tiles that define this rectangle
      if (cornerA != null && vertex == cornerA) continue;
      if (cornerB != null && vertex == cornerB) continue;

      if (rectangle.containsPointStrictly(vertex)) {
        if (verbose) {
          print('- Polygon vertex $vertex is inside rectangle.');
        }
        return false;
      }
    }

    // Check if any polygon edges intersect rectangle edges
    for (final rectEdge in rectangle.edges) {
      for (final polyEdge in edges) {
        final intersection = rectEdge.intersect(polyEdge);
        if (!intersection.x.isNaN && !intersection.y.isNaN) {
          // Intersection must be strictly inside BOTH edges (not at endpoints)
          if (rectEdge.containsPoint(intersection, inclusive: false) &&
              polyEdge.containsPoint(intersection, inclusive: false)) {
            if (verbose) {
              print(
                '- Rectangle edge $rectEdge intersects polygon edge $polyEdge '
                'at point $intersection.',
              );
            }
            return false;
          }
        }
      }
    }

    if (verbose) {
      print('- Rectangle is fully contained within polygon.');
    }
    return true;
  }
}

extension PointLength on List<Edge> {
  num get pointLength {
    num total = 0;
    for (final edge in this) {
      if (edge.isHorizontal) {
        total += (edge.to.x - edge.from.x).abs();
      } else if (edge.isVertical) {
        total += (edge.to.y - edge.from.y).abs();
      } else {
        throw StateError('Edge is neither horizontal nor vertical: $edge');
      }
    }
    return total;
  }
}

class Rectangle extends Polygon {
  Edge get topEdge => edges[0];
  Edge get bottomEdge => edges[2];
  Edge get leftEdge => edges[3];
  Edge get rightEdge => edges[1];
  Vector2 get topLeft => vertices[0];
  Vector2 get topRight => vertices[1];
  Vector2 get bottomRight => vertices[2];
  Vector2 get bottomLeft => vertices[3];

  // Accept any two opposing corners, always return "same" rectangle
  Rectangle(Vector2 a, Vector2 b, {super.verbose = false})
    : super([
        Vector2(a.x < b.x ? a.x : b.x, a.y < b.y ? a.y : b.y),
        Vector2(a.x > b.x ? a.x : b.x, a.y < b.y ? a.y : b.y),
        Vector2(a.x > b.x ? a.x : b.x, a.y > b.y ? a.y : b.y),
        Vector2(a.x < b.x ? a.x : b.x, a.y > b.y ? a.y : b.y),
      ], addEdges: false) {
    edges.addAll([
      Edge(
        Vector2(vertices[0].x, vertices[0].y),
        Vector2(vertices[1].x, vertices[1].y),
        angle: 0,
      ),
      Edge(
        Vector2(vertices[1].x, vertices[1].y),
        Vector2(vertices[2].x, vertices[2].y),
        angle: 90,
      ),
      Edge(
        Vector2(vertices[2].x, vertices[2].y),
        Vector2(vertices[3].x, vertices[3].y),
        angle: 180,
      ),
      Edge(
        Vector2(vertices[3].x, vertices[3].y),
        Vector2(vertices[0].x, vertices[0].y),
        angle: 270,
      ),
    ]);
  }

  num get area =>
      (rightEdge.from.x - leftEdge.from.x + 1) *
      (bottomEdge.from.y - topEdge.from.y + 1);

  bool containsPointStrictly(Vector2 point) {
    return point.x > topLeft.x &&
        point.x < topRight.x &&
        point.y > topLeft.y &&
        point.y < bottomLeft.y;
  }
}

class FloorPlan {
  final List<Vector2> _redTiles = [];
  final Map<(Vector2, Vector2), num> _areaCache = {};
  final Map<(Vector2, Vector2), num> _bounded = {};
  Polygon? _boundingPolygon;
  final bool verbose;

  FloorPlan({this.verbose = false});

  Future<Map<(Vector2, Vector2), num>> get areas async =>
      _areaCache.isEmpty ? await _computeAreas() : _areaCache;
  Map<(Vector2, Vector2), num> get boundedAreas => _bounded;
  Polygon get boundingPolygon => _computePolygon();

  void addRedTile(num row, num col) {
    _redTiles.add(Vector2(row, col));
    if (verbose) {
      print('- Added red tile at ($row, $col).');
    }
  }

  Polygon _computePolygon() {
    if (verbose) {
      print('- Computing bounding polygon for red tiles...');
    }
    if (_boundingPolygon != null) {
      return _boundingPolygon!;
    }

    _boundingPolygon = Polygon(List.unmodifiable(_redTiles), verbose: verbose);
    if (verbose) {
      print('- Bounding polygon vertices: ${_boundingPolygon!.vertices}');
    }
    return _boundingPolygon!;
  }

  Future<Map<(Vector2, Vector2), num>> _computeAreas() async {
    if (verbose) {
      print('- Computing areas between all pairs of red tiles...');
    }
    final boundingPolygon = _computePolygon();
    final int totalPairs = _redTiles.length * (_redTiles.length - 1) ~/ 2;
    int pairCount = 0;
    for (final tileA in _redTiles) {
      for (final tileB in _redTiles) {
        pairCount++;
        if (pairCount % 1000 == 1) {
          print('- Processing pair $pairCount of $totalPairs...');
        }

        if (tileA == tileB) {
          continue;
        }
        final key = tileA.manhattanDistance <= tileB.manhattanDistance
            ? (tileA, tileB)
            : (tileB, tileA);
        if (!_areaCache.containsKey(key)) {
          final area = tileA.areaOf(tileB);
          _areaCache[key] = area;
          final rectangle = Rectangle(tileA, tileB, verbose: verbose);
          if (await boundingPolygon.containsRectangle(
            rectangle,
            cornerA: tileA,
            cornerB: tileB,
          )) {
            if (verbose) {
              print('- Area between $tileA and $tileB is bounded. area: $area');
            }
            _bounded[key] = area;
          } else {
            if (verbose) {
              print(
                '- Area between $tileA and $tileB is unbounded. area: $area',
              );
            }
          }
        }
      }
    }
    return _areaCache;
  }

  void addRedTiles(Iterable<Vector2> tiles) {
    for (final tile in tiles) {
      addRedTile(tile.x, tile.y);
    }
  }
}

FloorPlan stringVectorListToFloorPlan(String input, {bool verbose = false}) {
  final FloorPlan plan = FloorPlan(verbose: verbose);
  final lines = input.trim().split('\n');
  for (final line in lines) {
    final parts = line.split(',');
    if (parts.length != 2) {
      throw FormatException('Invalid coordinate format: $line');
    }
    final row = int.parse(parts[0].trim());
    final col = int.parse(parts[1].trim());
    plan.addRedTile(row, col);
  }
  return plan;
}

// https://adventofcode.com/2025/day/9
Future<void> test() async {
  print('Running tests for Day 9...');
  final String testInput = '''
7,1
11,1
11,7
9,7
9,5
2,5
2,3
7,3
''';

  final FloorPlan plan = stringVectorListToFloorPlan(testInput, verbose: true);

  assert(plan._redTiles.length == 8);
  assert(plan._redTiles.contains(Vector2(7, 1)));
  assert(plan._redTiles.contains(Vector2(7, 3)));
  assert(!plan._redTiles.contains(Vector2(0, 0)));

  print('- Total red tiles parsed: ${plan._redTiles.length}, expected: 8.');

  final areas = await plan.areas;
  final largestArea = areas.values.reduce((a, b) => a > b ? a : b);
  assert(largestArea == 50);
  print('- Largest area between red tiles: $largestArea, expected: 50.');

  final boundedAreas = plan.boundedAreas;
  final largestBoundedArea = boundedAreas.values.reduce(
    (a, b) => a > b ? a : b,
  );
  assert(largestBoundedArea == 24);
  print(
    '- Largest bounded area between red tiles: $largestBoundedArea, expected: 24.',
  );
  print('All tests passed for Day 9.');
}

Future<void> dec_09(bool verbose) async {
  print('Day 9: Movie Theater');
  await test();
  final String puzzleInputFilePath = './bin/resources/dec_09_input.txt';
  final String rawInput = await File(puzzleInputFilePath).readAsString();
  final FloorPlan plan = stringVectorListToFloorPlan(
    rawInput,
    verbose: verbose,
  );
  final areas = await plan.areas;
  final largestArea = areas.values.reduce((a, b) => a > b ? a : b);
  print('- Largest area between red tiles: $largestArea.');
  final boundedAreas = plan.boundedAreas;
  final largestBoundedArea = boundedAreas.values.reduce(
    (a, b) => a > b ? a : b,
  );
  print('- Largest bounded area between red tiles: $largestBoundedArea.');
}

Future<void> main() async {
  await dec_09(false);
}
