// https://adventofcode.com/2025/day/1

import 'dart:io';

class LockDial {
  /// Total positions on the dial
  final int positions;

  /// Current position of the dial (0 to positions - 1)
  /// Default starts at 50
  int currentPosition;

  /// The password is the number of times the dial points to 0
  int zeroCounter = 0;

  /// The part 2 password is any time the dial points to 0 (including passing)
  int zeroPassCounter = 0;

  int get zeroSum => zeroCounter + zeroPassCounter;

  final bool verbose;

  LockDial({
    this.positions = 100,
    this.currentPosition = 50,
    this.verbose = false,
  }) {
    currentPosition = currentPosition % positions;
    if (verbose) {
      print('- The dial starts at position $currentPosition');
    }
  }

  void _zeroCheck() {
    if (currentPosition == 0) {
      zeroCounter += 1;
    }
  }

  /// if steps is negative, it's counter-clockwise
  void _zeroPassCheck(int start, int steps) {
    int minZeros = (steps.abs() / positions).floor();
    zeroPassCounter += minZeros;

    if (start == 0) {
      return;
    }

    int remainingSteps = steps.abs() % positions;
    if (steps > 0 && remainingSteps > (positions - start)) {
      // Clockwise and passed zero
      zeroPassCounter += 1;
    } else if (steps < 0 && remainingSteps > start) {
      // Counter-clockwise and passed zero
      zeroPassCounter += 1;
    }
  }

  void rotateClockwise(int steps) {
    _zeroPassCheck(currentPosition, steps);
    currentPosition = (currentPosition + steps) % positions;

    if (verbose) {
      print('- The dial is rotated R$steps to point at $currentPosition');
    }
    _zeroCheck();
  }

  void rotateCounterClockwise(int steps) {
    _zeroPassCheck(currentPosition, -steps);
    currentPosition = (currentPosition - steps) % positions;

    if (verbose) {
      print('- The dial is rotated L$steps to point at $currentPosition');
    }
    _zeroCheck();
  }

  void parseInstruction(String instruction) {
    final direction = instruction[0];
    final steps = int.parse(instruction.substring(1));
    if (direction == 'R') {
      rotateClockwise(steps);
    } else if (direction == 'L') {
      rotateCounterClockwise(steps);
    } else {
      throw ArgumentError('Invalid instruction: $instruction');
    }
  }
}

void test() {
  final List<String> testInput = [
    'L68',
    'L30',
    'R48',
    'L5',
    'R60',
    'L55',
    'L1',
    'L99',
    'R14',
    'L82',
  ];
  final LockDial dial = LockDial();
  for (final instruction in testInput) {
    dial.parseInstruction(instruction);
  }
  assert(dial.zeroCounter == 3);
  print('Test passed: Password (zero counter) is ${dial.zeroCounter}');
  assert(dial.zeroSum == 6);
  print('Test passed: Part 2 Password (zero pass counter) is ${dial.zeroSum}');
}

Future<void> dec_01(bool verbose) async {
  print('Day 1: Rotary Lock');
  test();
  final String puzzleInputFilePath = './bin/resources/dec_01_input.txt';
  final List<String> puzzleInput = await File(
    puzzleInputFilePath,
  ).readAsLines();
  final LockDial dial = LockDial();
  for (final instruction in puzzleInput) {
    dial.parseInstruction(instruction);
  }
  print('Puzzle solved: Password (zero counter) is ${dial.zeroCounter}');

  print(
    'Puzzle solved: Part 2 Password (zero pass counter) is ${dial.zeroSum}',
  );
}

void main() async {
  await dec_01(true);
}
