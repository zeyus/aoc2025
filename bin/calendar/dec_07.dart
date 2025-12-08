// https://adventofcode.com/2025/day/5

import 'dart:io';
import '../common/matrix2d.dart';

enum ManifoldSpace {
  beamStart,
  splitter,
  empty,
  beamPath,
  beamPathSplit,
  beamPathSplitLeft,
  beamPathSplitRight,
  terminated;

  @override
  String toString() {
    switch (this) {
      case ManifoldSpace.beamStart:
        return 'S';
      case ManifoldSpace.splitter:
        return '^';
      case ManifoldSpace.empty:
        return '.';
      case ManifoldSpace.beamPath:
        return '|';
      case ManifoldSpace.beamPathSplit:
        return '+';
      case ManifoldSpace.beamPathSplitLeft:
        return '/';
      case ManifoldSpace.beamPathSplitRight:
        return '\\';
      case ManifoldSpace.terminated:
        return 'X';
    }
  }
}

Matrix2D<ManifoldSpace> stringPlanToMatrix2D(
  String rawInput, {
  bool verbose = false,
}) {
  final lines = rawInput.split('\n').where((line) => line.trim().isNotEmpty);
  final List<List<ManifoldSpace>> matrix = [];
  for (final line in lines) {
    final row = line.split('').map((char) {
      switch (char) {
        case 'S':
          return ManifoldSpace.beamStart;
        case '^':
          return ManifoldSpace.splitter;
        case '.':
          return ManifoldSpace.empty;
        default:
          throw ArgumentError('Unknown character in input: $char');
      }
    }).toList();
    matrix.add(row);
  }
  return Matrix2D<ManifoldSpace>(matrix, verbose: verbose);
}

class Beam {
  final bool verbose;
  final ({int row, int col}) spawnPosition;
  final Beam? parent;
  final Projector projector;
  final List<Beam> _children = [];

  int _multiplier;

  set applyMultiplier(int value) {
    _multiplier += value;
    for (final child in _children) {
      child.applyMultiplier = value;
    }
  }

  int get multiplier => _multiplier;

  bool _split = false;
  bool get isSplit => _split;
  ({int row, int col}) _currentPosition;
  ({int row, int col}) get currentPosition => _currentPosition;

  List<Beam> get children => List<Beam>.unmodifiable(_children);

  ({int row, int col})? _endPosition;
  bool get terminated => _endPosition != null;
  ({int row, int col})? get endPosition => _endPosition;

  Beam(
    this.projector,
    this.spawnPosition, {
    this.parent,
    int multiplier = 1,
    this.verbose = false,
  }) : _currentPosition = spawnPosition,
       _multiplier = multiplier;

  (Beam?, Beam?) split(int row, int col, {bool existingPathStopsSplit = true}) {
    if (verbose) {
      print('- Beam at $spawnPosition is splitting.');
    }
    Beam? leftBeam;
    Beam? rightBeam;
    _endPosition = (row: row - 1, col: col);
    if (col > 0) {
      // check for existing path in new beam position
      if (existingPathStopsSplit &&
          projector.output[[row, col - 1]].first == ManifoldSpace.beamPath) {
        if (verbose) {
          print(
            '- Left beam at ($row, ${col - 1}) blocked by existing path; split aborted.',
          );
        }
        terminate();
      } else {
        leftBeam = Beam(
          projector,
          (row: row, col: col - 1),
          multiplier: _multiplier,
          verbose: verbose,
        );
        _children.add(leftBeam);
      }
    }
    if (col < projector.bounds.y) {
      // check for existing path in new beam position
      if (existingPathStopsSplit &&
          projector.output[[row, col + 1]].first == ManifoldSpace.beamPath) {
        if (verbose) {
          print(
            '- Right beam at ($row, ${col + 1}) blocked by existing path; split aborted.',
          );
        }
        terminate();
      } else {
        rightBeam = Beam(
          projector,
          (row: row, col: col + 1),
          multiplier: _multiplier,
          verbose: verbose,
        );
        _children.add(rightBeam);
      }
    }
    if (leftBeam != null || rightBeam != null) {
      _split = true;
    }
    return (leftBeam, rightBeam);
  }

  int get splits {
    if (!isSplit || !terminated) {
      return 0;
    }
    int totalSplits = 1;
    for (final child in _children) {
      totalSplits += child.splits;
    }
    return totalSplits;
  }

  int get totalBeams {
    int total = 0;
    if (!terminated && !isSplit) {
      total += 1;
    }
    for (final child in _children) {
      total += child.totalBeams;
    }
    return total;
  }

  List<Beam> get edgeBeams {
    final List<Beam> edges = [];
    if (!isSplit && !terminated) {
      edges.add(this);
    } else {
      for (final child in _children) {
        edges.addAll(child.edgeBeams);
      }
    }
    return edges;
  }

  int get pathCountFromEdges {
    final edges = edgeBeams;
    int total = 0;
    if (verbose) {
      print('- Calculating path count from ${edges.length} edge beams.');
    }
    for (final edge in edges) {
      total += edge.multiplier;
      if (verbose) {
        print(
          '- Edge beam at ${edge.spawnPosition}, to: ${edge.currentPosition} contributes ${edge.multiplier} paths.',
        );
      }
    }
    return total;
  }

  void reset() {
    if (verbose) {
      print('- Resetting beam at $spawnPosition.');
    }
    _currentPosition = spawnPosition;
    _endPosition = null;
    _split = false;
    _children.clear();
  }

  void terminate() {
    if (verbose) {
      print('- Terminating beam at $spawnPosition.');
    }
    _endPosition = _currentPosition;
  }

  void retract() {
    if (terminated) {
      if (verbose) {
        print('- Beam at $spawnPosition is terminated; cannot retract.');
      }
      return;
    }
    _currentPosition = (
      row: _currentPosition.row - 1,
      col: _currentPosition.col,
    );
    if (verbose) {
      print('- Beam at $spawnPosition retracted to $_currentPosition.');
    }
  }

  void advance() {
    if (terminated) {
      if (verbose) {
        print('- Beam at $spawnPosition is terminated; cannot advance.');
      }
      return;
    }
    _currentPosition = (
      row: _currentPosition.row + 1,
      col: _currentPosition.col,
    );
    if (verbose) {
      print('- Beam at $spawnPosition advanced to $_currentPosition.');
    }
  }

  // is this beam active at given position
  bool operator [](({int row, int col}) position) {
    if (position.row < 0 ||
        position.row > projector.bounds.x ||
        position.col < 0 ||
        position.col > projector.bounds.y) {
      return false;
    }
    if (position.row < spawnPosition.row ||
        (_endPosition != null && position.row > _endPosition!.row)) {
      return false;
    }

    if (position.col != spawnPosition.col) {
      return false;
    }

    return true;
  }
}

class Projector {
  final Matrix2D<ManifoldSpace> layout;
  final bool verbose;
  late final Beam _root;
  late final ({int row, int col}) origin;
  late Matrix2D<ManifoldSpace> _output;
  Matrix2D<ManifoldSpace> get output => _output;
  late Matrix2D<Beam?> _beamTracker;
  Matrix2D<Beam?> get beamTracker => _beamTracker;

  Beam get root => _root;

  ({int x, int y}) get bounds => (x: layout.rows - 1, y: layout.cols - 1);
  Projector(this.layout, {this.verbose = false}) {
    _findOrigin();
    _root = Beam(this, origin, verbose: verbose);
    _output = layout.copy();
    _beamTracker = Matrix2D<Beam?>(
      null,
      rows: layout.rows,
      cols: layout.cols,
      verbose: verbose,
    );
  }

  void _findOrigin() {
    bool found = false;
    while (!found) {
      for (int col = 0; col < layout.cols; col++) {
        for (int row = 0; row < layout.rows; row++) {
          if (layout[[row, col]].first == ManifoldSpace.beamStart) {
            origin = (row: row, col: col);
            found = true;
            if (verbose) {
              print('- Found beam origin at $origin');
            }
            return;
          }
        }
      }
    }
    throw StateError('No beam origin found in layout.');
  }

  void reset() {
    if (verbose) {
      print('- Resetting projector and root beam.');
    }
    _root.reset();
    _output = layout.copy();
    _beamTracker = Matrix2D<Beam?>(
      null,
      rows: layout.rows,
      cols: layout.cols,
      verbose: verbose,
    );
  }

  Matrix2D<ManifoldSpace> project({bool existingPathStopsSplit = true}) {
    final List<Beam> activeBeams = [_root];
    _output[[origin.row, origin.col]] = ManifoldSpace.beamStart;
    _beamTracker[[origin.row, origin.col]] = _root;
    int rowCounter = 0;
    while (activeBeams.isNotEmpty) {
      print(
        '- Active beams count: ${activeBeams.length}, processing row $rowCounter',
      );
      rowCounter += 1;

      final List<Beam> newActiveBeams = [];
      for (final beam in activeBeams) {
        if (beam.terminated) {
          if (verbose) {
            print('- Beam at ${beam.spawnPosition} is terminated; skipping.');
          }
          continue;
        }
        beam.advance();
        final pos = beam.currentPosition;
        if (pos.row > bounds.y + 1) {
          if (verbose) {
            print('- Beam at ${beam.spawnPosition} has exited layout.');
          }
          continue;
        }
        final space = _output[[pos.row, pos.col]].first;
        switch (space) {
          case ManifoldSpace.empty:
            newActiveBeams.add(beam);
            _output[[pos.row, pos.col]] = ManifoldSpace.beamPath;
            _beamTracker[[pos.row, pos.col]] = beam;
            break;
          case ManifoldSpace.splitter:
            final (leftBeam, rightBeam) = beam.split(
              pos.row,
              pos.col,
              existingPathStopsSplit: false,
            );
            if (leftBeam != null) {
              if (_beamTracker[[
                            leftBeam.spawnPosition.row,
                            leftBeam.spawnPosition.col,
                          ]]
                          .first !=
                      null &&
                  existingPathStopsSplit) {
                if (verbose) {
                  print(
                    '- Left beam at ${leftBeam.spawnPosition} blocked by existing path; split aborted.',
                  );
                }
                leftBeam.terminate();
                // update multiplier of parent beam
                final existingBeam =
                    _beamTracker[[
                          leftBeam.spawnPosition.row,
                          leftBeam.spawnPosition.col,
                        ]]
                        .first!;
                existingBeam.applyMultiplier = leftBeam.multiplier;
              } else {
                newActiveBeams.add(leftBeam);
                _output[[
                      leftBeam.spawnPosition.row,
                      leftBeam.spawnPosition.col,
                    ]] =
                    ManifoldSpace.beamPath;
                _beamTracker[[
                      leftBeam.spawnPosition.row,
                      leftBeam.spawnPosition.col,
                    ]] =
                    leftBeam;
              }
            }
            if (rightBeam != null) {
              if (_beamTracker[[
                            rightBeam.spawnPosition.row,
                            rightBeam.spawnPosition.col,
                          ]]
                          .first !=
                      null &&
                  existingPathStopsSplit) {
                if (verbose) {
                  print(
                    '- Right beam at ${rightBeam.spawnPosition} blocked by existing path; split aborted.',
                  );
                }
                rightBeam.terminate();
                // update multiplier of parent beam
                final existingBeam =
                    _beamTracker[[
                          rightBeam.spawnPosition.row,
                          rightBeam.spawnPosition.col,
                        ]]
                        .first!;
                existingBeam.applyMultiplier = rightBeam.multiplier;
              } else {
                newActiveBeams.add(rightBeam);
                _output[[
                      rightBeam.spawnPosition.row,
                      rightBeam.spawnPosition.col,
                    ]] =
                    ManifoldSpace.beamPath;
                _beamTracker[[
                      rightBeam.spawnPosition.row,
                      rightBeam.spawnPosition.col,
                    ]] =
                    rightBeam;
              }
            }
            break;
          case ManifoldSpace.beamPath:
            if (!existingPathStopsSplit) {
              newActiveBeams.add(beam);
              break;
            }
            _beamTracker[[pos.row, pos.col]].first!.applyMultiplier =
                beam.multiplier;
            beam.retract();
            beam.terminate();
            if (verbose) {
              print(
                '- Beam at ${beam.spawnPosition} encountered existing path at $pos; terminating.',
              );
            }
            if (_output[[pos.row, pos.col]].first == ManifoldSpace.beamPath) {
              _output[[pos.row, pos.col]] = ManifoldSpace.terminated;
            }
            break;
          case ManifoldSpace.beamStart:
            throw StateError('Beam encountered another beam start at $pos.');
          default:
            throw StateError('Unexpected manifold space at $pos: $space');
        }
        if (beam.isSplit) {
          if (beam.children.length == 2) {
            _output[[pos.row - 1, pos.col]] = ManifoldSpace.beamPathSplit;
          } else if (beam.children.length == 1) {
            final child = beam.children.first;
            if (child.spawnPosition.col < beam.spawnPosition.col) {
              _output[[pos.row - 1, pos.col]] = ManifoldSpace.beamPathSplitLeft;
            } else {
              _output[[pos.row - 1, pos.col]] =
                  ManifoldSpace.beamPathSplitRight;
            }
          }
        }
      }
      activeBeams
        ..clear()
        ..addAll(newActiveBeams);
    }
    return _output;
  }
}

Future<void> test() async {
  print('Running tests for Day 7...');
  final String testInput = '''
.......S.......
...............
.......^.......
...............
......^.^......
...............
.....^.^.^.....
...............
....^.^...^....
...............
...^.^...^.^...
...............
..^...^.....^..
...............
.^.^.^.^.^...^.
...............
''';

  final layout = stringPlanToMatrix2D(testInput, verbose: true);
  print('- Layout loaded with ${layout.rows} rows and ${layout.cols} cols.');
  final projector = Projector(layout, verbose: true);
  final projectedOutput = projector.project();
  print('Projected output:');
  for (var row in projectedOutput.data) {
    print(row.map((space) => space.toString()).join(''));
  }
  final int totalSplits = projector.root.splits;
  print('Total beam splits: $totalSplits');
  assert(totalSplits == 21);

  final int totalBeams = projector.root.totalBeams;
  print('Total beams created: $totalBeams');
  assert(totalBeams == 9);

  final beamTracker = projector.beamTracker;
  print('Beam Tracker:');
  for (var r = 0; r < beamTracker.rows; r++) {
    final rowStr = [];
    for (var c = 0; c < beamTracker.cols; c++) {
      final beam = beamTracker[[r, c]].first;
      if (beam != null) {
        rowStr.add(beam.multiplier.toString());
      } else {
        rowStr.add('.');
      }
    }
    print(rowStr.join(''));
  }

  final int edgecount = projector.root.edgeBeams.length;
  print('Total edge beams: $edgecount');
  assert(edgecount == 9);

  final int pathCountFromEdges = projector.root.pathCountFromEdges;
  print('Total beam path count from edges: $pathCountFromEdges');
  assert(pathCountFromEdges == 40);

  print('All tests passed for Day 7.');
}

Future<void> dec_07(bool verbose) async {
  print('Day 7: Laboratories');
  await test();

  final String puzzleInputFilePath = './bin/resources/dec_07_input.txt';
  final String puzzleInput = await File(puzzleInputFilePath).readAsString();
  final layout = stringPlanToMatrix2D(puzzleInput, verbose: verbose);
  final projector = Projector(layout, verbose: verbose);
  final projectedOutput = projector.project();
  print('Projected output:');
  for (var row in projectedOutput.data) {
    print(row.map((space) => space.toString()).join(''));
  }
  final int totalSplits = projector.root.splits;
  print('Total beam splits: $totalSplits');
  final int totalBeams = projector.root.totalBeams;
  print('Total beams created: $totalBeams.');
  final int possiblePaths = projector.root.pathCountFromEdges;
  print('Total possible beam paths: $possiblePaths.');
}

Future<void> main() async {
  await dec_07(true);
}
