// https://adventofcode.com/2025/day/5

import 'dart:io';

/// inclusive range
class Range {
  final int start;
  final int end;

  Range(this.start, this.end);

  bool overlaps(Range other) {
    return start <= other.end && end >= other.start;
  }

  Range? intersection(Range other) {
    if (!overlaps(other)) {
      return null;
    }
    final int newStart = start > other.start ? start : other.start;
    final int newEnd = end < other.end ? end : other.end;
    return Range(newStart, newEnd);
  }

  bool contains(int value) {
    return value >= start && value <= end;
  }

  Set<int> toIntSet() {
    return {for (int i = start; i <= end; i++) i};
  }
}

extension RangeListExtensions on List<Range> {
  Set<int> toIntSet() {
    final Set<int> allValues = {};
    for (final range in this) {
      allValues.addAll(range.toIntSet());
    }
    return allValues;
  }

  List<Range> reduceOverlaps() {
    if (isEmpty) {
      return [];
    }
    final List<Range> sortedRanges = List<Range>.from(this)
      ..sort((a, b) => a.start.compareTo(b.start));
    final List<Range> reduced = [];
    Range current = sortedRanges[0];
    for (int i = 1; i < sortedRanges.length; i++) {
      final Range next = sortedRanges[i];
      if (current.overlaps(next) || current.end + 1 == next.start) {
        current = Range(
          current.start,
          current.end > next.end ? current.end : next.end,
        );
      } else {
        reduced.add(current);
        current = next;
      }
    }
    reduced.add(current);
    return reduced;
  }

  int get lazyLength {
    final reduced = reduceOverlaps();
    int total = 0;
    for (final range in reduced) {
      total += (range.end - range.start + 1);
    }
    return total;
  }
}

class Cafeteria {
  final List<Range> freshFoodRanges;
  final Set<int> foodItems;
  final bool verbose;

  Cafeteria(
    this.freshFoodRanges,
    Iterable<int> foodItems, {
    this.verbose = false,
  }) : foodItems = foodItems.toSet() {
    if (verbose) {
      print(
        '- Cafeteria initialized with ${freshFoodRanges.length} fresh food ranges and ${this.foodItems.length} food items.',
      );
    }
  }

  Set<int> get freshFood {
    return freshFoodRanges.toIntSet().intersection(foodItems);
  }

  Set<int> get freshFoodLazy {
    final Set<int> fresh = {};
    for (final item in foodItems) {
      for (final range in freshFoodRanges) {
        if (range.contains(item)) {
          fresh.add(item);
          break;
        }
      }
    }
    return fresh;
  }

  int get freshFoodLazyCount {
    return freshFoodLazy.length;
  }

  int get freshItemsCount {
    return freshFood.length;
  }
}

(List<Range>, Set<int>) parseMenu(
  String rawInput, {
  bool verbose = false,
  includeFood = true,
}) {
  final lines = rawInput.trim().split('\n');
  final List<Range> ranges = [];
  int i = 0;
  // parse ranges
  for (; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) {
      i++;
      break;
    }
    final parts = line.split('-');
    if (parts.length != 2) {
      throw FormatException('Invalid range: $line');
    }
    final start = int.parse(parts[0].trim());
    final end = int.parse(parts[1].trim());
    if (verbose) {
      print('- Parsed range: $start to $end');
    }
    ranges.add(Range(start, end));
  }
  // parse food items
  final Set<int> foodItems = {};
  if (!includeFood) {
    return (ranges, foodItems);
  }
  for (; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) {
      continue;
    }
    final item = int.parse(line);
    foodItems.add(item);
  }
  return (ranges, foodItems);
}

Future<void> test() async {
  print('Running tests for Day 5...');
  final String testInput = '''
3-5
10-14
16-20
12-18

1
5
8
11
17
32
''';

  final (ranges, foodItems) = parseMenu(testInput, verbose: true);
  final Cafeteria cafeteria = Cafeteria(ranges, foodItems, verbose: true);
  final int freshCount = cafeteria.freshItemsCount;
  assert(freshCount == 3);
  print('Test passed: Fresh food items count is $freshCount.');
  final int freshCountLazy = cafeteria.freshFoodLazyCount;
  assert(freshCountLazy == 3);
  print('Test passed: (Lazy) Fresh food items count is $freshCountLazy.');
  print('Fresh food items: ${cafeteria.freshFood}');

  // part 2, count total items in ranges
  final totalRange = ranges.lazyLength;
  assert(totalRange == 14);
  print('Test passed: Total food items in ranges is $totalRange.');
  print('All tests passed for Day 5.');
}

Future<void> dec_05(bool verbose) async {
  print('Day 5: Cafeteria');
  await test();
  final String puzzleInputFilePath = './bin/resources/dec_05_input.txt';
  final String puzzleInput = await File(puzzleInputFilePath).readAsString();
  final (ranges, foodItems) = parseMenu(puzzleInput, verbose: verbose);
  final Cafeteria cafeteria = Cafeteria(ranges, foodItems, verbose: verbose);
  final int freshCount = cafeteria.freshFoodLazyCount;
  print('Puzzle solved: Fresh food items count is $freshCount.');

  final totalRange = ranges.lazyLength;
  print('Puzzle solved: Total food items in ranges is $totalRange.');
}

Future<void> main() async {
  await dec_05(true);
}
