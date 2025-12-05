import 'dart:io';

// https://adventofcode.com/2025/day/4

class Matrix2D<T> {
  final List<List<T>> data = [];
  late final int rows;
  late final int cols;
  final bool wrapping;
  final bool verbose;

  /// infers row and col size if not provided
  Matrix2D(
    List<List<T>>? matrix, {
    int? rows,
    int? cols,
    this.wrapping = false,
    this.verbose = false,
  }) {
    if (matrix != null) {
      if (rows != null) {
        this.rows = rows;
      } else {
        this.rows = matrix.length;
      }
      if (cols != null) {
        this.cols = cols;
      } else {
        this.cols = matrix[0].length;
      }
    } else {
      if (rows == null || cols == null) {
        throw ArgumentError(
          'Either matrix or both rows and cols must be provided.',
        );
      }
      this.rows = rows;
      this.cols = cols;
    }
    if (matrix != null) {
      if (matrix.length != this.rows) {
        throw ArgumentError(
          'Provided matrix row count does not match specified rows.',
        );
      }
      for (var row in matrix) {
        if (row.length != this.cols) {
          throw ArgumentError(
            'Provided matrix column count does not match specified cols.',
          );
        }
        data.add(List<T>.from(row));
      }
    } else {
      for (int r = 0; r < this.rows; r++) {
        data.add(List<T>.filled(this.cols, null as T));
      }
    }
  }

  List<T> operator [](List<dynamic> args) {
    if (args.isEmpty) {
      throw ArgumentError('No indices provided for matrix access.');
    }
    if (args.length == 1) {
      int row = args[0];
      return data[row];
    }
    if (args.length == 2) {
      int row = args[0];
      int col = args[1];
      return [data[row][col]];
    }
    throw ArgumentError('Too many indices provided for matrix access.');
  }

  void operator []=(List<dynamic> args, T value) {
    if (args.isEmpty) {
      throw ArgumentError('No indices provided for matrix assignment.');
    }
    if (args.length == 1) {
      int row = args[0];
      data[row] = List<T>.filled(cols, value);
      return;
    }
    if (args.length == 2) {
      int row = args[0];
      int col = args[1];
      data[row][col] = value;
      return;
    }
    throw ArgumentError('Too many indices provided for matrix assignment.');
  }

  List<T> neighbours(
    int row,
    int col, {
    bool includeDiagonals = true,
    bool includeSelf = false,
  }) {
    final List<T> neigh = [];
    final directions = [
      if (includeSelf) [0, 0], // self
      [-1, 0], // up
      [1, 0], // down
      [0, -1], // left
      [0, 1], // right
      if (includeDiagonals) ...[
        [-1, -1], // up-left
        [-1, 1], // up-right
        [1, -1], // down-left
        [1, 1], // down-right
      ],
    ];
    if (verbose) {
      print(
        '- Getting neighbours for ($row, $col), includeDiagonals: $includeDiagonals, includeSelf: $includeSelf',
      );
    }
    for (var dir in directions) {
      int newRow = row + dir[0];
      int newCol = col + dir[1];
      if (wrapping) {
        newRow = (newRow + rows) % rows;
        newCol = (newCol + cols) % cols;
      }
      if (newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols) {
        neigh.add(data[newRow][newCol]);
      }
    }
    return neigh;
  }

  Stream<List<T>> neighbourhoodWalk(
    int startRow,
    int startCol, {
    bool includeDiagonals = true,
    bool includeSelf = false,
  }) async* {
    final visited = <String>{};
    final queue = <List<int>>[];
    queue.add([startRow, startCol]);
    visited.add('$startRow,$startCol');
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final row = current[0];
      final col = current[1];
      yield neighbours(
        row,
        col,
        includeDiagonals: includeDiagonals,
        includeSelf: includeSelf,
      );
      for (var dir in [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
        [-1, -1],
        [-1, 1],
        [1, -1],
        [1, 1],
      ]) {
        int newRow = row + dir[0];
        int newCol = col + dir[1];
        if (wrapping) {
          newRow = (newRow + rows) % rows;
          newCol = (newCol + cols) % cols;
        }
        final key = '$newRow,$newCol';
        if (newRow >= 0 &&
            newRow < rows &&
            newCol >= 0 &&
            newCol < cols &&
            !visited.contains(key)) {
          visited.add(key);
          queue.add([newRow, newCol]);
        }
      }
    }
  }

  Stream<((int, int), List<T>)> neighbourhoodWalkIndexed(
    int startRow,
    int startCol, {
    bool includeDiagonals = true,
    bool includeSelf = false,
  }) async* {
    final visited = <String>{};
    final queue = <List<int>>[];
    queue.add([startRow, startCol]);
    visited.add('$startRow,$startCol');
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final row = current[0];
      final col = current[1];
      yield (
        (row, col),
        neighbours(
          row,
          col,
          includeDiagonals: includeDiagonals,
          includeSelf: includeSelf,
        ),
      );
      for (var dir in [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
        [-1, -1],
        [-1, 1],
        [1, -1],
        [1, 1],
      ]) {
        int newRow = row + dir[0];
        int newCol = col + dir[1];
        if (wrapping) {
          newRow = (newRow + rows) % rows;
          newCol = (newCol + cols) % cols;
        }
        final key = '$newRow,$newCol';
        if (newRow >= 0 &&
            newRow < rows &&
            newCol >= 0 &&
            newCol < cols &&
            !visited.contains(key)) {
          visited.add(key);
          queue.add([newRow, newCol]);
        }
      }
    }
  }

  List<T> flatten() {
    final List<T> flatList = [];
    for (var row in data) {
      flatList.addAll(row);
    }
    return flatList;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var row in data) {
      buffer.writeln(row);
    }
    return buffer.toString();
  }
}

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
