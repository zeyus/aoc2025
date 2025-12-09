// https://adventofcode.com/2025/day/8
import 'dart:collection';
import 'dart:io';
import 'dart:math';

class Vector3D {
  final int x;
  final int y;
  final int z;

  Vector3D(this.x, this.y, this.z);

  factory Vector3D.fromString(String raw) {
    final parts = raw.split(',').map((e) => e.trim()).toList();
    if (parts.length != 3) {
      throw FormatException('Invalid vector string: $raw');
    }
    return Vector3D(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  String toString() => '($x, $y, $z)';

  double distance(Vector3D other) {
    final dx = pow((other.x - x).toDouble(), 2);
    final dy = pow((other.y - y).toDouble(), 2);
    final dz = pow((other.z - z).toDouble(), 2);
    return sqrt(dx + dy + dz);
  }

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  operator ==(Object other) {
    if (other is! Vector3D) {
      return false;
    }
    return x == other.x && y == other.y && z == other.z;
  }
}

class JunctionBox {
  final Vector3D _position;
  Vector3D get position => _position;
  final bool verbose;
  late Circuit _circuit;
  final Set<Wire> _wires = {};
  final Set<Wire> _backWires = {};

  JunctionBox(this._position, {this.verbose = false})
    : _circuit = Circuit(verbose: verbose) {
    _circuit.addJunction(this);
  }

  double distance(JunctionBox other) {
    return position.distance(other.position);
  }

  bool connectsTo(JunctionBox other) {
    return _circuit == other._circuit;
  }

  // returns the last connected (i.e. the one that joins the other circuit),
  // or null if already connected
  JunctionBox? connectTo(JunctionBox other) {
    if (_circuit == other._circuit) {
      if (verbose) {
        print(
          '- Junction at $_position already connected to ${other.position} in the same circuit.',
        );
      }
      // already connected
      return null;
    }
    JunctionBox connectedBox;
    if (_circuit.junctionCount >= other._circuit.junctionCount) {
      for (final junction in other._circuit.drain()) {
        _circuit.addJunction(junction);
        junction._circuit = _circuit;
      }
      connectedBox = other;
      if (verbose) {
        print(
          '- Merged circuit of junction at ${other.position} into circuit of junction at $_position.',
        );
      }
    } else {
      // merge this circuit into other's one
      for (final junction in _circuit.drain()) {
        other._circuit.addJunction(junction);
        junction._circuit = other._circuit;
      }
      _circuit = other._circuit;
      connectedBox = this;
      if (verbose) {
        print(
          '- Merged circuit of junction at $_position into circuit of junction at ${other.position}.',
        );
      }
    }

    final wire = Wire(this, other, verbose: verbose);
    _wires.add(wire);
    other._backWires.add(wire);
    if (verbose) {
      print('- Junction at $_position connected to ${other.position}.');
    }
    return connectedBox;
  }

  @override
  operator ==(Object other) {
    if (other is! JunctionBox) {
      return false;
    }
    return hashCode == other.hashCode;
  }

  @override
  int get hashCode => _position.hashCode;

  @override
  String toString() =>
      "JunctionBox at $_position with ${_wires.length + _backWires.length} connections";
}

class Playground {
  final bool verbose;
  final Map<(JunctionBox, JunctionBox), double> _distanceCache = {};
  final Set<JunctionBox> _junctions = {};
  final Queue<(JunctionBox a, JunctionBox b)> _lastConnected =
      Queue<(JunctionBox a, JunctionBox b)>();

  List<(JunctionBox a, JunctionBox b)> lastConnectedBoxes(
    int n, {
    bool reverse = false,
  }) {
    final List<(JunctionBox a, JunctionBox b)> boxes = _lastConnected.toList();
    if (reverse) {
      return boxes.reversed.take(n).toList();
    }
    return boxes.take(n).toList();
  }

  Playground({this.verbose = false});

  void addJunction(JunctionBox junction) {
    _junctions.add(junction);
    if (verbose) {
      print('- Added junction at ${junction.position}.');
    }
  }

  void addJunctions(Iterable<JunctionBox> junctions) {
    for (final junction in junctions) {
      addJunction(junction);
    }
  }

  double _getDistance(JunctionBox a, JunctionBox b) {
    final key = (
      a.position.x < b.position.x ? a : b,
      a.position.x < b.position.x ? b : a,
    );
    if (_distanceCache.containsKey(key)) {
      return _distanceCache[key]!;
    }
    final distance = a.distance(b);
    _distanceCache[key] = distance;
    return distance;
  }

  List<(JunctionBox, JunctionBox, double)> allDistances() {
    final List<(JunctionBox, JunctionBox, double)> distances = [];
    final junctionList = _junctions.toList();
    for (int i = 0; i < junctionList.length; i++) {
      for (int j = i + 1; j < junctionList.length; j++) {
        final a = junctionList[i];
        final b = junctionList[j];
        final distance = _getDistance(a, b);
        distances.add((a, b, distance));
      }
    }
    return distances;
  }

  Set<Circuit> connectShortestPairs({
    int? n,
    int lastN = 2,
    bool ignoreConnected = false,
  }) {
    final allDistancesList = allDistances();
    allDistancesList.sort((a, b) => a.$3.compareTo(b.$3));
    int pairsConnected = 0;
    int i = 0;
    final Set<Circuit> connectedCircuits = {};
    n ??= allDistancesList.length;
    while (pairsConnected < n) {
      if (i >= allDistancesList.length) {
        if (verbose) {
          print('- No more pairs to connect.');
        }
        break;
      }
      final (a, b, distance) = allDistancesList[i];
      if (a.connectsTo(b)) {
        if (verbose) {
          print(
            '- Junctions at ${a.position} and ${b.position} are already connected; skipping.',
          );
        }
        i++;
        if (!ignoreConnected) {
          pairsConnected++;
        }
        continue;
      }
      final JunctionBox? connectedBox = a.connectTo(b);
      if (connectedBox != null) {
        _lastConnected.addLast((a, b));
        if (_lastConnected.length > lastN) {
          _lastConnected.removeFirst();
        }
      }
      connectedCircuits.add(a._circuit);
      pairsConnected++;
      i++;
      if (verbose) {
        print(
          '- Connected junctions at ${a.position} and ${b.position} with distance $distance.',
        );
      }
    }
    return connectedCircuits.where((circuit) => !circuit.isDrained).toSet();
  }
}

class Wire {
  late final JunctionBox from;
  late final JunctionBox to;
  final bool verbose;

  Wire(JunctionBox from, JunctionBox to, {this.verbose = false}) {
    // Keep sorted by x position to simplify comparisons
    this.from = from.position.x < to.position.x ? from : to;
    this.to = from.position.x < to.position.x ? to : from;
    if (verbose) {
      print(
        '- Created wire from ${this.from.position} to ${this.to.position}.',
      );
    }
  }
}

class Circuit {
  final bool verbose;
  final Set<JunctionBox> _junctions = {};
  bool _drained = false;
  bool get isDrained => _drained;
  Circuit({this.verbose = false});

  void addJunction(JunctionBox junction) {
    _junctions.add(junction);
    if (verbose) {
      print('- Circuit added junction at ${junction.position}.');
    }
  }

  List<JunctionBox> drain() {
    final List<JunctionBox> junctions = _junctions.toList();
    _junctions.clear();
    if (verbose) {
      print('- Circuit drained all junctions.');
    }
    _drained = true;
    return junctions;
  }

  void addJunctions(Iterable<JunctionBox> junctions) {
    for (final junction in junctions) {
      addJunction(junction);
    }
  }

  bool containsJunction(JunctionBox junction) {
    return _junctions.contains(junction);
  }

  int get junctionCount => _junctions.length;
}

Set<JunctionBox> parseVectors(String rawInput, {bool verbose = false}) {
  final lines = rawInput.split('\n').where((line) => line.trim().isNotEmpty);
  final Set<JunctionBox> vectors = {};
  for (final line in lines) {
    final vector = JunctionBox(Vector3D.fromString(line), verbose: verbose);
    if (verbose) {
      print('- Parsed vector: $vector');
    }
    vectors.add(vector);
  }
  return vectors;
}

extension CircuitSetExtension on Set<Circuit> {
  List<Circuit> longest(int n) {
    final sortedCircuits = toList()
      ..sort((a, b) => b.junctionCount.compareTo(a.junctionCount));
    return sortedCircuits.take(n).toList();
  }
}

extension CircuitListExtension on List<Circuit> {
  num multiplyJunctionCounts() {
    num product = 1;
    for (final circuit in this) {
      product *= circuit.junctionCount;
    }
    return product;
  }
}

Future<void> test() async {
  print('Running tests for Day 8...');
  final String testInput = '''
162,817,812
57,618,57
906,360,560
592,479,940
352,342,300
466,668,158
542,29,236
431,825,988
739,650,466
52,470,668
216,146,977
819,987,18
117,168,530
805,96,715
346,949,466
970,615,88
941,993,340
862,61,35
984,92,344
425,690,689
''';
  final vectors = parseVectors(testInput, verbose: true);
  assert(vectors.length == 20);
  print('- Parsed ${vectors.length} vectors.');
  assert(
    vectors.first.toString() ==
        'JunctionBox at (162, 817, 812) with 0 connections',
  );
  print(
    '- First vector string representation is correct ${vectors.first.position.toString()}.',
  );

  final Vector3D v1 = Vector3D(0, 0, 0);
  // 3-4-0 triangle = 5 distance
  final Vector3D v2 = Vector3D(3, 4, 0);
  final distance = v1.distance(v2);
  assert(distance == 5.0);
  print('- Distance calculation is correct: $distance.');

  // all distances
  final playground = Playground(verbose: true);
  playground.addJunctions(vectors);
  final allDistances = playground.allDistances();
  assert(allDistances.isNotEmpty);
  print('- Calculated all pairwise distances: ${allDistances.length}.');
  // sort from shortest to longest
  allDistances.sort((a, b) => a.$3.compareTo(b.$3));
  // show top 5 shortest distances
  print('- Top 5 shortest distances:');
  for (int i = 0; i < 5 && i < allDistances.length; i++) {
    final (a, b, dist) = allDistances[i];
    print('  - Distance between ${a.position} and ${b.position}: $dist');
  }

  // connect shortest 10 pairs
  final connectedCircuits = playground.connectShortestPairs(n: 10);
  assert(connectedCircuits.isNotEmpty);
  print(
    '- Connected shortest 10 pairs into circuits: ${connectedCircuits.length} circuits formed.',
  );
  // get top 3 longest circuits
  final longestCircuits = connectedCircuits.longest(3);
  assert(longestCircuits.length == 3);
  print('- Top 3 longest circuits:');
  for (int i = 0; i < longestCircuits.length; i++) {
    final circuit = longestCircuits[i];
    print('  - Circuit ${i + 1} with ${circuit.junctionCount} junctions.');
  }
  final junctionProduct = longestCircuits.multiplyJunctionCounts();
  print(
    '- Product of junction counts in top 3 longest circuits: $junctionProduct.',
  );
  assert(junctionProduct == 40);

  // Print total number of circuits formed
  final Set<Circuit> circuits = {};
  for (final junction in vectors) {
    circuits.add(junction._circuit);
  }
  print('- Total circuits formed: ${circuits.length}.');
  assert(circuits.length == 11);

  for (final circuit in circuits) {
    print('- Circuit with ${circuit.junctionCount} junctions:');
    for (final junction in circuit._junctions) {
      print('  - Junction at ${junction.position}');
    }
  }

  // Now connect all pairs
  final vectors2 = parseVectors(testInput, verbose: true);
  final playground2 = Playground(verbose: true);
  playground2.addJunctions(vectors2);
  final allConnectedCircuits = playground2.connectShortestPairs();
  print(
    '- Connected all remaining pairs into circuits: ${allConnectedCircuits.length} circuits formed.',
  );
  // get last 2 connected boxes
  final lastConnected = playground2.lastConnectedBoxes(2, reverse: true);
  print('- Last 2 connected junction boxes:');
  for (final box in lastConnected) {
    print('  - Junction at ${box.$1.position} connected to ${box.$2.position}');
  }

  assert(
    lastConnected.first.$1.position.x * lastConnected.first.$2.position.x ==
        216 * 117,
  );

  print(
    '- X product of last connected junctions: '
    '${lastConnected.first.$1.position.x * lastConnected.first.$2.position.x}',
  );

  print('All tests passed for Day 8.');
}

Future<void> dec_08(bool verbose) async {
  print('Day 8: Playground');
  await test();

  final String puzzleInputFilePath = './bin/resources/dec_08_input.txt';
  final String rawInput = await File(puzzleInputFilePath).readAsString();
  final vectors = parseVectors(rawInput, verbose: verbose);
  if (verbose) {
    print('- Parsed ${vectors.length} vectors from input.');
  }
  final playground = Playground(verbose: verbose);
  playground.addJunctions(vectors);
  final connectedCircuits = playground.connectShortestPairs(n: 1000);
  if (verbose) {
    print(
      '- Connected shortest 1000 pairs into circuits: ${connectedCircuits.length} circuits formed.',
    );
  }
  final longestCircuits = connectedCircuits.longest(3);
  if (verbose) {
    print('- Top 3 longest circuits:');
    for (int i = 0; i < longestCircuits.length; i++) {
      final circuit = longestCircuits[i];
      print('  - Circuit ${i + 1} with ${circuit.junctionCount} junctions.');
    }
  }
  final junctionProduct = longestCircuits.multiplyJunctionCounts();
  print(
    '- Product of junction counts in top 3 longest circuits: $junctionProduct.',
  );

  // Now connect all pairs
  final vectors2 = parseVectors(rawInput, verbose: verbose);
  final playground2 = Playground(verbose: verbose);
  playground2.addJunctions(vectors2);
  final allConnectedCircuits = playground2.connectShortestPairs();
  if (verbose) {
    print(
      '- Connected all remaining pairs into circuits: ${allConnectedCircuits.length} circuits formed.',
    );
  }
  final lastConnected = playground2.lastConnectedBoxes(2, reverse: true);
  print('- Last 2 connected junction boxes:');
  for (final box in lastConnected) {
    print('  - Junction at ${box.$1.position} connected to ${box.$2.position}');
  }

  print(
    '- X product of last connected junctions: '
    '${lastConnected.first.$1.position.x * lastConnected.first.$2.position.x}',
  );
}

Future<void> main() async {
  await dec_08(true);
}
