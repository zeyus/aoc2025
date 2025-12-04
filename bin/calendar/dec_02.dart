// https://adventofcode.com/2025/day/2

import 'dart:io';

class IDValidator {
  final String rawInput;
  final List<List<String>> inputPairs = [];
  final List<int> invalidIDs = [];
  final bool verbose;

  int get invalidCount => invalidIDs.length;
  int get invalidSum => invalidIDs.fold(0, (sum, id) => sum + id);

  IDValidator(this.rawInput, {this.verbose = false}) {
    final lines = rawInput.split(',');
    if (verbose) {
      print('- Processing ${lines.length} ID ranges.');
    }
    for (var line in lines) {
      final parts = line.split('-');
      if (parts.length != 2) {
        throw FormatException('Invalid ID range: $line');
      }
      parts[0] = parts[0].trim();
      parts[1] = parts[1].trim();
      inputPairs.add(parts);
      int start = int.parse(parts[0]);
      int end = int.parse(parts[1]);
      if (verbose) {
        print('- Checking IDs from $start to $end');
      }
      for (int id = start; id <= end; id++) {
        if (!_isValid(id.toString())) {
          invalidIDs.add(id);
        }
      }
    }
    if (verbose) {
      print('- Parsed ${inputPairs.length} ID ranges.');
    }
  }

  bool _isValid(String id) {
    // if it is an odd length, it is valid
    // becaus it cannot be a repeated pair
    if (id.length % 2 > 1) {
      if (verbose) {
        print('  - ID $id is valid (odd length).');
      }
      return true;
    }
    // check for repeated pairs
    final int pairLength = id.length ~/ 2;
    final String firstHalf = id.substring(0, pairLength);
    final String secondHalf = id.substring(pairLength);
    if (firstHalf == secondHalf) {
      if (verbose) {
        print('  - ID $id is invalid (repeated pair).');
      }
      return false;
    }
    return true;
  }
}

class Part2IDValidator extends IDValidator {
  Part2IDValidator(super.rawInput, {super.verbose = false});

  @override
  bool _isValid(String id) {
    if (!super._isValid(id)) {
      return false;
    }
    // Additional check for part 2, must not be any repeating sequence
    final int length = id.length;

    for (int seqLength = 1; seqLength <= length ~/ 2; seqLength++) {
      if (length % seqLength != 0) {
        continue; // only check lengths that divide evenly
      }
      final int numSequences = length ~/ seqLength;
      bool allMatch = true;
      final String firstSeq = id.substring(0, seqLength);
      for (int i = 1; i < numSequences; i++) {
        final String nextSeq = id.substring(i * seqLength, (i + 1) * seqLength);
        if (nextSeq != firstSeq) {
          allMatch = false;
          break;
        }
      }
      if (allMatch) {
        if (verbose) {
          print(
            '  - ID $id is invalid (repeating sequence of length $seqLength).',
          );
        }
        return false;
      }
    }
    return true;
  }
}

void test() {
  final String testInput =
      '11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124';
  final IDValidator validator = IDValidator(testInput, verbose: true);
  assert(validator.invalidSum == 1227775554);
  print('Test passed: Sum of invalid IDs is ${validator.invalidSum}');

  final Part2IDValidator part2Validator = Part2IDValidator(
    testInput,
    verbose: true,
  );
  assert(part2Validator.invalidSum == 4174379265);
  print(
    'Test passed: Part 2 Sum of invalid IDs is ${part2Validator.invalidSum}',
  );
}

Future<void> dec_02(bool verbose) async {
  test();
  // Placeholder for Day 2 implementation.
  print('Day 2: ID Validator');
  final String puzzleInputFilePath = './bin/resources/dec_02_input.txt';
  final String puzzleInput = await File(puzzleInputFilePath).readAsString();
  final IDValidator validator = IDValidator(puzzleInput, verbose: verbose);
  print('Puzzle solved: Sum of invalid IDs is ${validator.invalidSum}');
  final Part2IDValidator part2Validator = Part2IDValidator(
    puzzleInput,
    verbose: verbose,
  );
  print(
    'Puzzle solved: Part 2 Sum of invalid IDs is ${part2Validator.invalidSum}',
  );
}

Future<void> main() async {
  await dec_02(true);
}
