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

  Matrix2D<T> copy() {
    final List<List<T>> newData = [];
    for (var row in data) {
      newData.add(List<T>.from(row));
    }
    return Matrix2D<T>(newData, wrapping: wrapping, verbose: verbose);
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

  List<T> getRow(int rowIndex) {
    return data[rowIndex];
  }

  List<T> getCol(int colIndex) {
    final List<T> col = [];
    for (var row in data) {
      col.add(row[colIndex]);
    }
    return col;
  }

  Matrix2D<T> transpose() {
    final List<List<T>> transposedData = [];
    for (int c = 0; c < cols; c++) {
      final List<T> newRow = [];
      for (int r = 0; r < rows; r++) {
        newRow.add(data[r][c]);
      }
      transposedData.add(newRow);
    }
    return Matrix2D<T>(transposedData, wrapping: wrapping, verbose: verbose);
  }

  Stream<List<T>> iterRows() async* {
    for (var row in data) {
      yield row;
    }
  }

  Stream<List<T>> iterCols() async* {
    for (int c = 0; c < cols; c++) {
      yield getCol(c);
    }
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
