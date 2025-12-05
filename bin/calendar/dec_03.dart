import 'dart:io';

// https://adventofcode.com/2025/day/3
class BatteryBank {
  final List<int> batteries;
  final bool verbose;

  BatteryBank(this.batteries, {this.verbose = false});

  /// Get the top N batteries by capacity, but it has to end up with the highest
  /// combined capacity, where combined isn't the sum of the batteries, but the
  /// two numbers formed by concatenating the battery capacities.
  List<int> topN(int n) {
    if (n <= 0 || n > batteries.length) {
      throw ArgumentError('Invalid number of batteries requested: $n');
    }

    List<int> selected = [];
    int remaining = n;
    int startIndex = 0;

    while (remaining > 0) {
      int maxIndex = startIndex;
      for (int i = startIndex; i <= batteries.length - remaining; i++) {
        if (batteries[i] > batteries[maxIndex]) {
          maxIndex = i;
        }
      }
      selected.add(batteries[maxIndex]);
      startIndex = maxIndex + 1;
      remaining -= 1;
    }

    if (verbose) {
      print('- Top $n batteries selected: $selected');
    }

    return selected;
  }

  int capacity(int n) {
    final topBatteries = topN(n);
    final int totalCapacity = int.parse(
      topBatteries.map((b) => b.toString()).join(),
    );
    if (verbose) {
      print('- Capacity with top $n batteries: $totalCapacity');
    }
    return totalCapacity;
  }
}

extension TotalCapacity on List<BatteryBank> {
  int totalCapacity(int n) {
    int total = 0;
    for (final bank in this) {
      total += bank.capacity(n);
    }
    return total;
  }
}

// Async generator to get battery bank row string from raw input
Stream<List<int>> batteryBankRows(String rawInput) async* {
  final lines = rawInput.split('\n');
  for (final line in lines) {
    final value = line.trim();
    if (value.isEmpty) {
      continue;
    }
    final batteries = value.split('').map(int.parse).toList();
    yield batteries;
  }
}

Future<void> test() async {
  final String testInput = '''
987654321111111
811111111111119
234234234234278
818181911112111
  ''';

  final Stream<List<int>> rows = batteryBankRows(testInput);
  final List<BatteryBank> banks = [];
  await for (final batteries in rows) {
    banks.add(BatteryBank(batteries, verbose: true));
  }
  assert(banks.length == 4);
  print('Test passed: Parsed ${banks.length} battery banks.');
  assert(banks[0].capacity(2) == 98);
  print(
    'Test passed: Bank 1 capacity for top 2 batteries is ${banks[0].capacity(2)}.',
  );
  assert(banks[1].capacity(2) == 89);
  print(
    'Test passed: Bank 2 capacity for top 2 batteries is ${banks[1].capacity(2)}.',
  );
  assert(banks[2].capacity(2) == 78);
  print(
    'Test passed: Bank 3 capacity for top 2 batteries is ${banks[2].capacity(2)}.',
  );
  assert(banks[3].capacity(2) == 92);
  print(
    'Test passed: Bank 4 capacity for top 2 batteries is ${banks[3].capacity(2)}.',
  );
  final int total = banks.totalCapacity(2);
  assert(total == 357);
  print('Test passed: Total capacity for all banks (top 2) is $total.');

  // part 2, top 12
  final int totalPart2 = banks.totalCapacity(12);
  assert(totalPart2 == 3121910778619);
  print('Test passed: Total capacity for all banks (top 12) is $totalPart2.');
}

Future<void> dec_03(bool verbose) async {
  print('Day 3: Battery Banks');
  await test();
  final String puzzleInputFilePath = './bin/resources/dec_03_input.txt';
  final String puzzleInput = await File(puzzleInputFilePath).readAsString();
  final Stream<List<int>> rows = batteryBankRows(puzzleInput);
  final List<BatteryBank> banks = [];
  await for (final batteries in rows) {
    banks.add(BatteryBank(batteries, verbose: verbose));
  }
  final int total = banks.totalCapacity(2);
  print('Puzzle solved: Total capacity of all banks (top 2) is $total.');

  final int totalPart2 = banks.totalCapacity(12);
  print('Puzzle solved: Total capacity of all banks (top 12) is $totalPart2.');
}

Future<void> main() async {
  await dec_03(true);
}
