// https://adventofcode.com/2025/day/6

import 'dart:io';
import '../common/matrix2d.dart';

enum Operation {
  add(symbol: '+'),
  multiply(symbol: '*');

  final String symbol;

  const Operation({required this.symbol});

  @override
  String toString() => symbol;

  static Operation fromSymbol(String symbol) {
    for (var op in Operation.values) {
      if (op.symbol == symbol) {
        return op;
      }
    }
    throw ArgumentError('Invalid operation symbol: $symbol');
  }

  num apply(num a, num b) {
    switch (this) {
      case Operation.add:
        return a + b;
      case Operation.multiply:
        return a * b;
    }
  }

  num applyToList(List<num?> numbers) {
    num? result = numbers.firstWhere((n) => n != null);
    if (result == null) {
      throw ArgumentError('No non-null numbers to apply operation on.');
    }
    for (var number in numbers.skip(1)) {
      if (number != null) {
        result = apply(result!, number);
      }
    }
    return result!;
  }

  num applyToRTLList(List<List<String?>> rtlDigits, {bool verbose = false}) {
    int nDigits = rtlDigits.first.length;
    final List<String?> intermediate = List.filled(nDigits, null);

    for (int digitIndex = 0; digitIndex < nDigits; digitIndex++) {
      for (final digitList in rtlDigits) {
        if (digitList[digitIndex] == null) {
          continue;
        }
        intermediate[digitIndex] = intermediate[digitIndex] == null
            ? digitList[digitIndex]
            : intermediate[digitIndex]! + digitList[digitIndex]!;
      }
    }
    if (verbose) {
      print(
        '- Intermediate RTL digits after applying operation: $intermediate',
      );
    }
    // Convert to number
    final List<num> values = intermediate
        .where((intermediateDigit) => intermediateDigit != null)
        .map((digitStr) => num.parse(digitStr!))
        .toList();
    final result = applyToList(values);
    return result;
  }
}

(Matrix2D<int>, List<Operation>) parseMathSheet(
  String rawInput, {
  bool verbose = false,
}) {
  final lines = rawInput.split('\n').where((line) => line.trim().isNotEmpty);
  final List<List<int>> matrix = [];
  for (final line in lines) {
    if (line == lines.last) {
      final row = line
          .trim()
          .split(RegExp(r'\s+'))
          .map((opStr) => Operation.fromSymbol(opStr))
          .toList();
      return (Matrix2D<int>(matrix, verbose: verbose), row);
    }
    final row = line
        .trim()
        .split(RegExp(r'\s+'))
        .map((numStr) => int.parse(numStr))
        .toList();
    matrix.add(row);
  }
  throw ArgumentError('Input does not contain operation row.');
}

(Matrix2D<List<String?>>, List<Operation>) parseMathSheetPart2(
  String rawInput, {
  bool verbose = false,
}) {
  final lines = rawInput.split('\n').where((line) => line.trim().isNotEmpty);
  final List<List<List<String?>>> matrix = [];
  List<int> colStartIndices = [];
  final String lastLine = lines.last;
  // Calculate indices from operator column
  for (int i = 0; i < lastLine.length; i++) {
    final char = lastLine[i];
    if (char.trim().isNotEmpty) {
      colStartIndices.add(i);
    }
  }
  for (final line in lines) {
    if (line == lastLine) {
      final row = line
          .trim()
          .split(RegExp(r'\s+'))
          .map((opStr) => Operation.fromSymbol(opStr))
          .toList();
      return (Matrix2D<List<String?>>(matrix, verbose: verbose), row);
    }
    final List<List<String?>> rowValues = [];
    for (int colIndex = 0; colIndex < colStartIndices.length; colIndex++) {
      final startIdx = colStartIndices[colIndex];
      final endIdx = colIndex + 1 < colStartIndices.length
          ? colStartIndices[colIndex + 1] - 1
          : line.length;
      final numStr = line.substring(startIdx, endIdx);
      rowValues.add(
        numStr
            .split('')
            .map((numStr) => numStr == ' ' ? null : numStr)
            .toList()
            .reversed
            .toList(),
      );
    }
    matrix.add(rowValues);
  }
  throw ArgumentError('Input does not contain operation row.');
}

Future<void> test() async {
  final String testInput = '''
123 328  51 64 
 45 64  387 23 
  6 98  215 314
*   +   *   + 
  ''';

  final (matrix, operations) = parseMathSheet(testInput, verbose: true);
  print('Parsed matrix:');
  print(matrix);
  print('Parsed operations: $operations');
  final matrixT = matrix.transpose();
  int rowIndex = 0;
  num results = 0;
  await for (final row in matrixT.iterRows()) {
    final operation = operations[rowIndex];
    final result = operation.applyToList(row);
    print(
      'Row ${rowIndex + 1} with operation $operation gives result: $result',
    );
    results += result;
    rowIndex += 1;
  }
  assert(results == 4277556);
  print('Result $results matches expected value.');

  // Part 2 test
  final (matrix2, operations2) = parseMathSheetPart2(testInput, verbose: true);

  print('Parsed operations for part 2: $operations2');
  final matrix2T = matrix2.transpose();
  print('Parsed matrix (T) for part 2:');
  print(matrix2T);
  rowIndex = 0;
  num results2 = 0;
  await for (final row in matrix2T.iterRows()) {
    final operation = operations2[rowIndex];
    final result = operation.applyToRTLList(row, verbose: true);
    print(
      'Row ${rowIndex + 1} with operation $operation gives result: $result',
    );
    results2 += result;
    rowIndex += 1;
  }
  assert(results2 == 3263827);
  print('Result $results2 matches expected value.');
  print('All tests passed for Day 6.');
}

Future<void> dec_06(bool verbose) async {
  test();
  // Placeholder for Day 6 implementation.
  print('Day 6: Trash Compactor');
  final String puzzleInputFilePath = './bin/resources/dec_06_input.txt';
  final String rawInput = await File(puzzleInputFilePath).readAsString();
  final (matrix, operations) = parseMathSheet(rawInput, verbose: verbose);

  // Get results by applying operations to each column
  final matrixT = matrix.transpose();
  int rowIndex = 0;
  num results = 0;
  await for (final row in matrixT.iterRows()) {
    final operation = operations[rowIndex];
    final result = operation.applyToList(row);
    if (verbose) {
      print(
        'Row ${rowIndex + 1} with operation $operation gives result: $result',
      );
    }
    results += result;
    rowIndex += 1;
  }
  print('Total result: $results');

  // Part 2
  final (matrix2, operations2) = parseMathSheetPart2(
    rawInput,
    verbose: verbose,
  );
  final matrix2T = matrix2.transpose();
  rowIndex = 0;
  num results2 = 0;
  await for (final row in matrix2T.iterRows()) {
    final operation = operations2[rowIndex];
    final result = operation.applyToRTLList(row, verbose: verbose);
    if (verbose) {
      print(
        'Row ${rowIndex + 1} with operation $operation gives result: $result',
      );
    }
    results2 += result;
    rowIndex += 1;
  }
  print('Total result for part 2: $results2');
}

Future<void> main() async {
  await dec_06(true);
}
