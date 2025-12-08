import 'dart:io';
import '../common/matrix2d.dart';

// https://adventofcode.com/2025/day/4

Matrix2D<bool> stringPlanToMatrix2D(String rawInput, {bool verbose = false}) {
  final lines = rawInput.split('\n').where((line) => line.trim().isNotEmpty);
  final List<List<bool>> matrix = [];
  for (final line in lines) {
    final row = line.split('').map((char) => char == '@').toList();
    matrix.add(row);
  }
  return Matrix2D<bool>(matrix, verbose: verbose);
}

class FloorPlan {
  final Matrix2D<bool> layout;
  final bool verbose;
  FloorPlan(this.layout, {this.verbose = false});

  Future<int> countAccessibleRolls({int maxOccupied = 4}) async {
    final Stream<List<bool>> neighbours = layout.neighbourhoodWalk(
      0,
      0,
      includeSelf: true,
    );
    int accessibleCount = 0;
    await for (final neigh in neighbours) {
      final currentCell = neigh[0];
      if (!currentCell) {
        // not a roll
        continue;
      }
      // neighbours + self (occupied by definition)
      final occupied = neigh.where((bool occupied) => occupied).toList().length;
      if (verbose) {
        print(
          '- Roll found with $occupied occupied - including self (max allowed $maxOccupied).',
        );
      }
      if (occupied < (maxOccupied + 1)) {
        accessibleCount += 1;
      }
    }
    if (verbose) {
      print('- Total accessible rolls: $accessibleCount');
    }
    return accessibleCount;
  }

  Future<int> removeAccessibleRolls({int maxOccupied = 4}) async {
    final Stream<((int, int), List<bool>)> neighbours = layout
        .neighbourhoodWalkIndexed(0, 0, includeSelf: true);

    int removedCount = 0;
    await for (final ((int row, int col), neigh) in neighbours) {
      final currentCell = neigh[0];
      if (!currentCell) {
        // not a roll
        continue;
      }
      // neighbours + self (occupied by definition)
      final occupied = neigh.where((bool occupied) => occupied).toList().length;
      if (verbose) {
        print(
          '- Roll at ($row, $col) found with $occupied occupied - including self (max allowed $maxOccupied).',
        );
      }
      if (occupied < (maxOccupied + 1)) {
        // remove roll
        layout[[row, col]] = false;
        removedCount += 1;
        if (verbose) {
          print('  - Roll at ($row, $col) removed.');
        }
      }
    }
    if (verbose) {
      print('- Total removed rolls: $removedCount');
    }
    return removedCount;
  }

  Future<int> removeAllAccessibleRolls({int maxOccupied = 4}) async {
    int totalRemoved = 0;
    int removedThisRound = 0;
    do {
      removedThisRound = await removeAccessibleRolls(maxOccupied: maxOccupied);
      totalRemoved += removedThisRound;
      if (verbose) {
        print(
          '- Removed $removedThisRound rolls this round, total removed so far: $totalRemoved.',
        );
      }
    } while (removedThisRound > 0);
    if (verbose) {
      print('- Total removed rolls after all rounds: $totalRemoved');
    }
    return totalRemoved;
  }
}

Future<void> test() async {
  print('Running tests for Day 4...');
  final String testInput = '''
..@@.@@@@.
@@@.@.@.@@
@@@@@.@.@@
@.@@@@..@.
@@.@@@@.@@
.@@@@@@@.@
.@.@.@.@@@
@.@@@.@@@@
.@@@@@@@@.
@.@.@@@.@.

''';

  final Matrix2D<bool> matrix = stringPlanToMatrix2D(testInput, verbose: true);
  final FloorPlan plan = FloorPlan(matrix, verbose: true);
  final int accessibleRolls = await plan.countAccessibleRolls();
  assert(accessibleRolls == 13);
  print('Test passed: Accessible rolls count is $accessibleRolls.');

  final int totalRemovedRolls = await plan.removeAllAccessibleRolls();
  assert(totalRemovedRolls == 43);
  print('Test passed: Total removed rolls count is $totalRemovedRolls.');

  print('All tests passed for Day 4.');
}

Future<void> dec_04(bool verbose) async {
  print('Day 4: Printing Department');
  await test();

  final String puzzleInputFilePath = './bin/resources/dec_04_input.txt';
  final String puzzleInput = await File(puzzleInputFilePath).readAsString();
  final Matrix2D<bool> matrix = stringPlanToMatrix2D(
    puzzleInput,
    verbose: verbose,
  );
  final FloorPlan plan = FloorPlan(matrix);
  final int accessibleRolls = await plan.countAccessibleRolls();
  print('Puzzle solved: Accessible rolls count is $accessibleRolls.');

  final int totalRemovedRolls = await plan.removeAllAccessibleRolls();
  print('Puzzle solved: Total removed rolls count is $totalRemovedRolls.');
}

Future<void> main() async {
  await dec_04(true);
}
