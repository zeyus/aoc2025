// https://adventofcode.com/2025/day/10

import 'dart:io';

class PriorityQueue<E> {
  final List<E> _items = [];
  final int Function(E, E) _comparator;

  PriorityQueue(this._comparator);

  void add(E item) {
    _items.add(item);
    _bubbleUp(_items.length - 1);
  }

  E removeFirst() {
    if (_items.isEmpty) throw StateError('Queue is empty');
    final result = _items[0];
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      _bubbleDown(0);
    }
    return result;
  }

  bool get isNotEmpty => _items.isNotEmpty;
  bool get isEmpty => _items.isEmpty;

  void _bubbleUp(int index) {
    while (index > 0) {
      final parentIndex = (index - 1) ~/ 2;
      if (_comparator(_items[index], _items[parentIndex]) >= 0) break;
      final temp = _items[index];
      _items[index] = _items[parentIndex];
      _items[parentIndex] = temp;
      index = parentIndex;
    }
  }

  void _bubbleDown(int index) {
    while (true) {
      final leftChild = 2 * index + 1;
      final rightChild = 2 * index + 2;
      var smallest = index;

      if (leftChild < _items.length &&
          _comparator(_items[leftChild], _items[smallest]) < 0) {
        smallest = leftChild;
      }
      if (rightChild < _items.length &&
          _comparator(_items[rightChild], _items[smallest]) < 0) {
        smallest = rightChild;
      }
      if (smallest == index) break;

      final temp = _items[index];
      _items[index] = _items[smallest];
      _items[smallest] = temp;
      index = smallest;
    }
  }
}

typedef SwitchQueueItem = ({
  List<int> sequence,
  List<int> state,
  List<int> availableSwitches,
  int stateSum,
  int depth,
});

class LightBank {
  final int size;
  int _lightState = 0;
  final List<int> _joltages;
  final int targetState;

  int get lightState => _lightState;

  LightBank(this.size, this.targetState, this._joltages) {
    if (_joltages.length != size) {
      throw ArgumentError(
        'Joltages length must match the size of the LightBank.',
      );
    }
  }

  bool isLightOn(int index) {
    return (_lightState & (1 << index)) != 0;
  }

  void toggleLight(int index) {
    _lightState ^= (1 << index);
  }

  void toggleLights(int mask) {
    _lightState ^= mask;
  }

  void reset() {
    _lightState = 0;
  }

  bool get isReady => _lightState == targetState;

  @override
  String toString() {
    return 'Lightbank(state ($_lightState): ${_lightState.toRadixString(2).padLeft(size, '0')}, target ($targetState): ${targetState.toRadixString(2).padLeft(size, '0')}, joltages: $_joltages)';
  }
}

class JoltOMeter {
  final List<int> _targetJoltages;
  final List<int> _currentJoltages;
  List<int> get targetJoltages => List<int>.unmodifiable(_targetJoltages);

  JoltOMeter(this._targetJoltages)
    : _currentJoltages = List<int>.filled(
        _targetJoltages.length,
        0,
        growable: false,
      );

  void incrementJoltage(int index) {
    _currentJoltages[index]++;
    if (_currentJoltages[index] > _targetJoltages[index]) {
      throw StateError(
        'Joltage at index $index exceeded target joltage of ${_targetJoltages[index]}',
      );
    }
  }

  void incrementJoltages(List<int> indices) {
    for (final index in indices) {
      _currentJoltages[index]++;
    }
  }

  void reset() {
    for (int i = 0; i < _currentJoltages.length; i++) {
      _currentJoltages[i] = 0;
    }
  }

  void restoreState(List<int> state) {
    for (int i = 0; i < state.length; i++) {
      _currentJoltages[i] = state[i];
    }
  }

  List<int> get currentJoltages => List<int>.unmodifiable(_currentJoltages);

  bool get isReady {
    for (int i = 0; i < _targetJoltages.length; i++) {
      if (_targetJoltages[i] != _currentJoltages[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    return 'JoltOMeter(target joltages: $_targetJoltages, current joltages: $_currentJoltages)';
  }
}

class ToggleSwitch {
  final int _lightMask;
  final LightBank lightBank;
  final JoltOMeter joltOMeter;
  final List<int> connectedLights;

  ToggleSwitch(this.lightBank, List<int> connectedLights, this.joltOMeter)
    : _lightMask = connectedLights.fold(
        0,
        (mask, index) => mask | (1 << index),
      ),
      connectedLights = List<int>.unmodifiable(connectedLights);

  int press() {
    lightBank.toggleLights(_lightMask);
    return lightBank.lightState;
  }

  List<int> press2() {
    joltOMeter.incrementJoltages(connectedLights);
    return joltOMeter.currentJoltages;
  }

  String targetStateString() {
    final buffer = StringBuffer();
    for (int i = 0; i < lightBank.size; i++) {
      buffer.write(lightBank.isLightOn(i) ? '#' : '.');
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return 'ToggleSwitch(connectedLights: $connectedLights, lightMask: ${_lightMask.toRadixString(2).padLeft(lightBank.size, '0')})';
  }
}

class Machine {
  final LightBank lightBank;
  final JoltOMeter joltOMeter;
  final List<ToggleSwitch> switches;
  final int machineId;
  String get targetStateString => lightBank.targetState
      .toRadixString(2)
      .padLeft(lightBank.size, '0')
      .split('')
      .reversed
      .join()
      .replaceAll('0', '.')
      .replaceAll('1', '#');
  String get currentStateString {
    final buffer = StringBuffer();
    for (int i = 0; i < lightBank.size; i++) {
      buffer.write(lightBank.isLightOn(i) ? '#' : '.');
    }
    return buffer.toString();
  }

  Machine(this.machineId, this.lightBank, this.switches, this.joltOMeter);

  List<int> leastPresses({
    int maxDepth = 5,
    int currentDepth = 0,
    int currentState = 0,
    List<int> sequence = const [],
  }) {
    if (currentState == lightBank.targetState) {
      return sequence;
    }
    if (currentDepth >= maxDepth) {
      return [];
    }
    final List<int> bestResult = [];
    int shortestLength = maxDepth + 1;
    for (int i = 0; i < switches.length; i++) {
      if (shortestLength <= currentDepth + 1) {
        break;
      }
      final nextState = currentState ^ switches[i]._lightMask;
      final result = leastPresses(
        maxDepth: maxDepth,
        currentDepth: currentDepth + 1,
        currentState: nextState,
        sequence: [...sequence, i],
      );
      if (result.isNotEmpty && result.length < shortestLength) {
        bestResult.clear();
        bestResult.addAll(result);
        shortestLength = result.length;
      }
    }
    return bestResult;
  }

  @pragma('vm:unsafe:no-bounds-checks')
  List<int> _sortSwitchesByEffectiveness(
    List<int> state,
    Map<int, Set<int>> switchesForLight, {
    int topN = 2,
  }) {
    final effectiveness = <int, int>{};
    final Set<int> blacklist = {};
    for (final lightIndex in switchesForLight.keys) {
      if (state[lightIndex] <= 0) {
        blacklist.addAll(switchesForLight[lightIndex]!);
        continue;
      }
      for (final switchIndex in switchesForLight[lightIndex]!) {
        if (blacklist.contains(switchIndex)) {
          continue;
        }
        effectiveness[switchIndex] = (effectiveness[switchIndex] ?? 0) + 1;
      }
    }
    effectiveness.removeWhere((key, value) => blacklist.contains(key));
    final sortedSwitches = effectiveness.keys.toList();
    // effectiveness sort descending
    sortedSwitches.sort(
      (a, b) => effectiveness[b]!.compareTo(effectiveness[a]!),
    );
    return sortedSwitches.length > topN
        ? sortedSwitches.sublist(0, topN)
        : sortedSwitches;
  }

  @pragma('vm:unsafe:no-bounds-checks')
  String _stateToKey(List<int> state) {
    return state.join(',');
  }

  @pragma('vm:unsafe:no-bounds-checks')
  List<int> _greedySolution() {
    final currentJoltages = List<int>.from(joltOMeter.targetJoltages);
    final sequence = <int>[];
    final Map<int, Set<int>> switchesForLight = {};
    for (int i = 0; i < switches.length; i++) {
      for (final lightIndex in switches[i].connectedLights) {
        switchesForLight.putIfAbsent(lightIndex, () => <int>{}).add(i);
      }
    }

    int iterations = 0;
    while (iterations < 1000) {
      iterations++;
      bool allZero = currentJoltages.every((j) => j == 0);
      if (allZero) break;

      // Find best switch using effectiveness scoring
      int bestSwitch = -1;
      int bestScore = -1;

      for (int i = 0; i < switches.length; i++) {
        bool valid = true;
        int score = 0;
        for (final lightIndex in switches[i].connectedLights) {
          if (currentJoltages[lightIndex] <= 0) {
            valid = false;
            break;
          }
          score += currentJoltages[lightIndex];
        }
        if (valid && score > bestScore) {
          bestScore = score;
          bestSwitch = i;
        }
      }

      if (bestSwitch == -1) break;

      // Apply switch
      for (final lightIndex in switches[bestSwitch].connectedLights) {
        currentJoltages[lightIndex]--;
      }
      sequence.add(bestSwitch);
    }

    // Verify solution
    bool allZero = currentJoltages.every((j) => j == 0);
    return allZero ? sequence : [];
  }

  @pragma('vm:unsafe:no-bounds-checks')
  List<int> leastPresses2({
    int maxLength = 5,
    int topN = 2,
    bool useGreedyHint = true,
  }) {
    // Try greedy first to get upper bound
    if (useGreedyHint) {
      final greedySolution = _greedySolution();
      if (greedySolution.isNotEmpty && greedySolution.length < maxLength) {
        maxLength = greedySolution.length;
      }
    }

    final queue = PriorityQueue<SwitchQueueItem>((a, b) {
      // closer to zero
      final stateCmp = a.stateSum.compareTo(b.stateSum);
      if (stateCmp != 0) return stateCmp;
      // shorter
      return a.depth.compareTo(b.depth);
    });
    final List<int> initialJoltages = joltOMeter.targetJoltages.toList(
      growable: false,
    );
    final Map<int, Set<int>> switchesForLight = {};
    for (int i = 0; i < switches.length; i++) {
      for (final lightIndex in switches[i].connectedLights) {
        switchesForLight.putIfAbsent(lightIndex, () => <int>{}).add(i);
      }
    }

    final Set<String> visited = {};
    final String initialKey = _stateToKey(initialJoltages);
    visited.add(initialKey);

    queue.add((
      sequence: [],
      state: initialJoltages,
      availableSwitches: List<int>.unmodifiable(
        _sortSwitchesByEffectiveness(
          initialJoltages,
          switchesForLight,
          topN: topN,
        ),
      ),
      stateSum: initialJoltages.reduce((a, b) => a + b),
      depth: 0,
    ));

    while (queue.isNotEmpty) {
      final currentSequence = queue.removeFirst();
      int depth = currentSequence.depth;

      if (depth >= maxLength) {
        continue;
      }
      for (final i in currentSequence.availableSwitches) {
        int stateSum = currentSequence.stateSum;
        final nextState = List<int>.from(
          currentSequence.state,
          growable: false,
        );
        bool belowZero = false;
        for (final index in switches[i].connectedLights) {
          int newValue = --nextState[index];

          if (newValue < 0) {
            belowZero = true;
            break;
          }
          stateSum--;
        }
        if (stateSum == 0) {
          return [...currentSequence.sequence, i];
        }
        if (belowZero) {
          continue;
        }

        // Skip if we've already visited this state
        final String stateKey = _stateToKey(nextState);
        if (visited.contains(stateKey)) {
          continue;
        }
        visited.add(stateKey);

        queue.add((
          sequence: [...currentSequence.sequence, i],
          state: nextState,
          availableSwitches: _sortSwitchesByEffectiveness(
            nextState,
            switchesForLight,
            topN: topN,
          ),
          stateSum: stateSum,
          depth: depth + 1,
        ));
      }
    }
    return [];
  }

  void pressSwitch2(int switchIndex) {
    switches[switchIndex].press2();
  }

  void pressSwitch(int switchIndex) {
    switches[switchIndex].press();
  }
}

Iterable<Machine> parseInput(String rawInput) sync* {
  final lines = rawInput.trim().split('\n');
  int machineId = 0;
  for (final line in lines) {
    final List<ToggleSwitch> switches = [];
    final parts = line.split(' ');
    final targetState = parts[0]
        .substring(1, parts[0].length - 1)
        .split('')
        .reversed
        .map((c) => c == '#' ? 1 : 0)
        .reduce((acc, bit) => (acc << 1) | bit);

    final switchTargets = <List<int>>[];
    for (int i = 1; i < parts.length - 1; i++) {
      final switchTarget = parts[i].substring(1, parts[i].length - 1);
      final connectedLights = switchTarget
          .split(',')
          .map((s) => int.parse(s))
          .toList(growable: false);
      switchTargets.add(connectedLights);
    }
    final lightJoltages = parts.last
        .substring(1, parts.last.length - 1)
        .split(',')
        .map((s) => int.parse(s))
        .toList(growable: false);
    final lightBank = LightBank(
      lightJoltages.length,
      targetState,
      lightJoltages,
    );
    final joltOMeter = JoltOMeter(lightJoltages);
    for (final connectedLights in switchTargets) {
      switches.add(ToggleSwitch(lightBank, connectedLights, joltOMeter));
    }
    yield Machine(machineId++, lightBank, switches, joltOMeter);
  }
}

Future<void> test() async {
  print('Running tests for Day 10...');
  final String testInput = '''
[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
''';

  final machines = parseInput(testInput);
  final machine1 = machines.elementAt(0);
  machine1.pressSwitch(4);

  machine1.pressSwitch(5);
  assert(machine1.currentStateString == '.##.');
  assert(machine1.lightBank.isReady);
  print(
    '- Machine 1 passed (current state: ${machine1.currentStateString}, target state: ${machine1.targetStateString}, isReady: ${machine1.lightBank.isReady})',
  );
  print(machine1.lightBank);

  final machine2 = machines.elementAt(1);
  machine2.pressSwitch(2);
  machine2.pressSwitch(3);

  machine2.pressSwitch(4);
  assert(machine2.currentStateString == '...#.');
  assert(machine2.lightBank.isReady);
  print(
    '- Machine 2 passed (current state: ${machine2.currentStateString}, target state: ${machine2.targetStateString}, isReady: ${machine2.lightBank.isReady})',
  );
  print(machine2.lightBank);

  final machine3 = machines.elementAt(2);
  machine3.pressSwitch(1);
  machine3.pressSwitch(2);

  assert(machine3.currentStateString == '.###.#');
  assert(machine3.lightBank.isReady);
  print(
    '- Machine 3 passed (current state: ${machine3.currentStateString}, target state: ${machine3.targetStateString}, isReady: ${machine3.lightBank.isReady})',
  );
  print(machine3.lightBank);
  int totalSwitchesPressed = 0;
  for (final machine in machines) {
    machine.lightBank.reset();
    final presses = machine.leastPresses(maxDepth: 10);
    for (final switchIndex in presses) {
      machine.pressSwitch(switchIndex);
    }
    totalSwitchesPressed += presses.length;
    assert(machine.lightBank.isReady);
    print(
      '- Machine solved with least presses: ${presses.length} (sequence: ${presses.map((i) => i.toString()).join(', ')})',
    );
  }

  assert(totalSwitchesPressed == 7);
  print('- Total switches pressed across all machines: $totalSwitchesPressed');

  // test JoltOMeter
  final joltOMeter = JoltOMeter([3, 1, 1, 2]);
  joltOMeter.incrementJoltage(0);
  joltOMeter.incrementJoltages([0, 1, 2, 3]);
  joltOMeter.incrementJoltage(0);
  assert(!joltOMeter.isReady);
  print(
    '- JoltOMeter intermediate state: $joltOMeter (isReady: ${joltOMeter.isReady})',
  );
  joltOMeter.incrementJoltage(3);
  assert(joltOMeter.isReady);
  print(
    '- JoltOMeter test passed: $joltOMeter (isReady: ${joltOMeter.isReady})',
  );

  // calculate least jolatage presses for machine 0
  final machine = machines.first;
  machine.joltOMeter.reset();
  final presses = machine.leastPresses2(maxLength: 11, topN: 2);
  machine.joltOMeter.reset();
  for (final switchIndex in presses) {
    machine.switches[switchIndex].press2();
  }
  assert(machine.joltOMeter.isReady);
  final expectedSequence = [0, 1, 1, 1, 3, 3, 3, 4, 5, 5];
  print(
    '- Machine least joltages presses: ${presses.length} (sequence: ${presses.map((i) => i.toString()).join(', ')})',
  );
  assert(presses.length == expectedSequence.length);
  machine.joltOMeter.reset();
  for (int i = 0; i < presses.length; i++) {
    assert(presses[i] == expectedSequence[i]);
    machine.switches[presses[i]].press2();
  }
  assert(machine.joltOMeter.isReady);
  print(
    '- Machine joltOMeter is ready after least presses: ${machine.joltOMeter.isReady}',
  );
  print('- Target sequence: ${expectedSequence.join(', ')}');
  print('All tests passed for Day 10.');
}

Future<void> dec_10(bool verbose) async {
  print('Day 5: Factory');
  await test();
  final String input = await File(
    'bin/resources/dec_10_input.txt',
  ).readAsString();
  final machines = parseInput(input).toList();
  int totalSwitchesPressed = 0;
  final Map<int, int> results = {};
  int startDepth = 2;
  final int maxDepth = 250;
  for (int depth = startDepth; depth <= maxDepth; depth += 10) {
    if (results.length == machines.length) {
      print('- All machines solved, stopping search.');
      break;
    }
    print('- Trying to solve machines with max depth $depth');
    print('- Solved so far: ${results.length} of ${machines.length}');
    for (final Machine machine in machines) {
      if (results.containsKey(machine.machineId)) {
        continue;
      }
      machine.lightBank.reset();
      final presses = machine.leastPresses(maxDepth: depth);

      if (presses.isNotEmpty) {
        print(
          '  - Machine #${machine.machineId} solved with least presses: ${presses.length} (sequence: ${presses.map((i) => i.toString()).join(', ')})',
        );
        results[machine.machineId] = presses.length;
        totalSwitchesPressed += presses.length;
        continue;
      }
    }
  }

  print('- Total switches pressed across all machines: $totalSwitchesPressed');
  if (results.length < machines.length) {
    final unsolved = [];
    for (final Machine machine in machines) {
      if (!results.containsKey(machine.machineId)) {
        unsolved.add(machine.machineId);
      }
    }
    print('Unsolved machine IDs: $unsolved');
  } else {
    print('All machines solved successfully.');
  }
  print('- Recalculating total switches pressed...');
  totalSwitchesPressed = results.values.fold(0, (sum, v) => sum + v);
  print('- Total switches pressed across all machines: $totalSwitchesPressed');

  // Part 2
  print('Starting Part 2: JoltOMeter');
  totalSwitchesPressed = 0;
  results.clear();

  for (final Machine machine in machines) {
    if (results.length == machines.length) {
      print('- All machines solved, stopping search.');
      break;
    }
    if (results.containsKey(machine.machineId)) {
      print('- Machine #${machine.machineId} already solved, skipping.');
      continue;
    }
    startDepth =
        2 * machine.joltOMeter.targetJoltages.reduce((a, b) => a > b ? a : b);
    final int topN = 3;
    print(
      '- Solving machine #${machine.machineId} with starting depth: $startDepth and topN: $topN',
    );
    for (int depth = startDepth; depth <= maxDepth; depth++) {
      print(
        '- Trying to solve machine #${machine.machineId} with current depth: $depth',
      );
      print('- Solved so far: ${results.length} of ${machines.length}');
      machine.joltOMeter.reset();
      final presses = machine.leastPresses2(maxLength: depth, topN: topN);

      if (presses.isNotEmpty) {
        print(
          '  - Machine #${machine.machineId} solved with least presses: ${presses.length} (sequence: ${presses.map((i) => i.toString()).join(', ')})',
        );
        results[machine.machineId] = presses.length;
        totalSwitchesPressed += presses.length;
        break;
      }
    }
  }
  print(
    '- Total joltages increments across all machines: $totalSwitchesPressed',
  );
  if (results.length < machines.length) {
    final unsolved = [];
    for (final Machine machine in machines) {
      if (!results.containsKey(machine.machineId)) {
        unsolved.add(machine.machineId);
      }
    }
    print('Unsolved machine IDs: $unsolved');
  } else {
    print('All machines solved successfully.');
  }
  print('- Recalculating total joltages increments...');
  totalSwitchesPressed = results.values.fold(0, (sum, v) => sum + v);
  print(
    '- Total joltages increments across all machines: $totalSwitchesPressed',
  );
}

Future<void> main() async {
  await dec_10(true);
}
