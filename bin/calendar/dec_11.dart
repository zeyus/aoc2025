// https://adventofcode.com/2025/day/11

import 'dart:async';
import 'dart:collection';
import 'dart:io';

extension LinkedListCloneExtention on LinkedList<Wire> {
  LinkedList<Wire> clone() {
    final clonedList = LinkedList<Wire>();
    for (final entry in this) {
      clonedList.add(entry.clone());
    }
    return clonedList;
  }
}

class Packet {
  final LinkedList<Wire> _path;
  final Set<Socket> _visitedSockets;
  final Socket _startSocket;
  int _flags;
  bool _terminated = false;
  bool get isTerminated => _terminated;

  List<Socket> get path =>
      [_startSocket] + _path.map((wire) => wire.to).toList();

  Packet({
    required Socket start,
    LinkedList<Wire>? path,
    Set<Socket>? visitedSockets,
    int flags = 0,
  }) : _startSocket = start,
       _path = path ?? LinkedList<Wire>(),
       _visitedSockets = visitedSockets ?? {},
       _flags = flags {
    if (!_visitedSockets.contains(start)) {
      _visitedSockets.add(start);
    }
  }

  bool traverse(Wire wire) {
    if (_visitedSockets.contains(wire.to)) {
      // Already visited this socket, avoid loop
      return false;
    }
    _path.add(wire.clone());
    _visitedSockets.add(wire.to);
    return true;
  }

  int get flags => _flags;

  void flag() {
    _flags++;
  }

  void terminate() {
    if (!_terminated) {
      _terminated = true;
      PacketTracer.packetTerminated.add(this);
    }
  }

  Packet clone() {
    final packet = Packet(
      start: _startSocket,
      path: _path.clone(),
      visitedSockets: Set<Socket>.from(_visitedSockets),
      flags: _flags,
    );
    PacketTracer.packetCloned.add(packet);
    return packet;
  }
}

final class Wire with LinkedListEntry<Wire> {
  final Socket from;
  final Socket to;

  Wire(this.from, this.to);

  bool transmit(Packet packet) {
    if (packet.isTerminated) {
      return false;
    }
    final forwardedPacket = packet.clone();
    if (forwardedPacket.traverse(this)) {
      // Enqueue instead of immediately receiving
      PacketTracer.enqueuePacket(forwardedPacket, to);
      return true;
    }
    forwardedPacket.terminate();
    return false;
  }

  Wire clone() {
    return Wire(from, to);
  }
}

class Socket {
  final String name;
  final List<Wire> inputs = [];
  final List<Wire> outputs = [];
  bool _flagged = false;
  final StreamController<Packet> _controller =
      StreamController<Packet>.broadcast();
  Stream<Packet> get stream => _controller.stream;
  static int _packetProcessCount = 0;

  Socket(this.name) {
    stream.listen((packet) async {
      // Forward the packet to all output wires
      if (outputs.isEmpty) {
        // No outputs, terminate the packet
        packet.terminate();
      } else {
        send(packet);
      }

      // Periodically yield to event loop to allow timers to fire
      // This prevents microtask starvation while minimizing overhead
      _packetProcessCount++;
      if (_packetProcessCount % 100 == 0) {
        await Future.delayed(Duration.zero);
      }
    });
  }

  void flag() {
    _flagged = true;
  }

  void connectTo(Socket other) {
    final wire = Wire(this, other);
    outputs.add(wire);
    other.inputs.add(wire);
  }

  void send(Packet packet) {
    if (_flagged) {
      packet.flag();
    }
    for (final wire in outputs) {
      wire.transmit(packet);
    }
    packet.terminate();
  }

  void receive(Packet packet) {
    _controller.add(packet);
  }

  @override
  String toString() => 'Socket($name)';
}

class PacketQueueEntry {
  final Packet packet;
  final Socket socket;

  PacketQueueEntry(this.packet, this.socket);
}

class PacketTracer {
  static StreamController<Packet> packetCloned =
      StreamController<Packet>.broadcast();
  static StreamController<Packet> packetTerminated =
      StreamController<Packet>.broadcast();
  static Queue<PacketQueueEntry> packetQueue = Queue<PacketQueueEntry>();

  static Stream<Packet> get onPacketCloned => packetCloned.stream;
  static Stream<Packet> get onPacketTerminated => packetTerminated.stream;

  static void reset() {
    packetCloned.close();
    packetTerminated.close();
    packetCloned = StreamController<Packet>.broadcast();
    packetTerminated = StreamController<Packet>.broadcast();
    packetQueue.clear();
  }

  static void enqueuePacket(Packet packet, Socket socket) {
    packetQueue.add(PacketQueueEntry(packet, socket));
  }
}

class Reactor {
  final Map<String, Socket> sockets = {};
  final bool verbose;
  bool _processingQueue = false;

  Reactor({this.verbose = false});

  Socket getOrCreateSocket(String name) {
    return sockets.putIfAbsent(name, () => Socket(name));
  }

  void addConnection(String fromName, String toName) {
    final fromSocket = getOrCreateSocket(fromName);
    final toSocket = getOrCreateSocket(toName);
    fromSocket.connectTo(toSocket);
  }

  void resetFlags() {
    for (final socket in sockets.values) {
      socket._flagged = false;
    }
  }

  Future<void> _processPacketQueue() async {
    const int batchSize = 1000; // Process packets in batches

    while (_processingQueue) {
      if (PacketTracer.packetQueue.isEmpty) {
        await Future.delayed(Duration(milliseconds: 1));
        continue;
      }

      // Process a batch
      int processed = 0;
      while (PacketTracer.packetQueue.isNotEmpty && processed < batchSize) {
        final entry = PacketTracer.packetQueue.removeFirst();
        entry.socket.receive(entry.packet);
        processed++;
      }

      // Yield to event loop after each batch to allow timers to fire
      await Future.delayed(Duration.zero);
    }
  }

  Future<Set<Packet>> trace(
    String start,
    String destination, {
    List<String> requiredStops = const [],
    int timeoutSeconds = 5,
  }) async {
    // Reset PacketTracer to clear any state from previous runs
    PacketTracer.reset();
    // Reset socket flags from previous runs
    resetFlags();

    final startSocket = sockets[start];
    final destinationSocket = sockets[destination];
    if (startSocket == null || destinationSocket == null) {
      print('Invalid start or destination socket.');
      return {};
    }
    int allPacketsCount = 1; // Start with initial packet
    int terminatedPacketsCount = 0;
    final Set<Packet> targetPackets = {};
    final initialPacket = Packet(start: startSocket);
    final Completer<void> completer = Completer<void>();

    if (requiredStops.isNotEmpty) {
      for (final stop in requiredStops) {
        final socket = sockets[stop];
        if (socket == null) {
          print('Invalid required stop socket: $stop');
          return {};
        }
        socket.flag();
      }
    }
    final int requiredFlags = requiredStops.length;
    // Set up listener for cloned and terminated packets
    final subscriptionCloned = PacketTracer.onPacketCloned.listen((packet) {
      if (verbose) {
        print('Packet cloned: ${packet.path.map((s) => s.name).join(' -> ')}');
      }
      allPacketsCount++;
    });
    final subscriptionTerminated = PacketTracer.onPacketTerminated.listen((
      packet,
    ) {
      if (verbose) {
        print(
          'Packet terminated: ${packet.path.map((s) => s.name).join(' -> ')}',
        );
      }
      terminatedPacketsCount++;

      // There was too much pressure without yielding to the event loop
      if (allPacketsCount == terminatedPacketsCount && !completer.isCompleted) {
        Future(() {
          if (allPacketsCount == terminatedPacketsCount &&
              !completer.isCompleted) {
            completer.complete();
          }
        });
      }
    });
    final subscriptionDestination = destinationSocket.stream.listen((packet) {
      if (verbose) {
        print(
          'Packet reached destination: ${packet.path.map((s) => s.name).join(' -> ')}',
        );
      }
      packet.terminate();
      if (packet.flags >= requiredFlags) {
        targetPackets.add(packet);
      }
    });

    // Start the queue processor in the background
    _processingQueue = true;
    final queueProcessor = _processPacketQueue();

    // Start tracing
    startSocket.receive(initialPacket);
    try {
      await completer.future.timeout(Duration(seconds: timeoutSeconds));
    } on TimeoutException {
      print('Tracing timed out after $timeoutSeconds seconds.');
      print('Total packets: $allPacketsCount');
      print('Terminated packets: $terminatedPacketsCount');
      print('Active packets: ${allPacketsCount - terminatedPacketsCount}');
    } finally {
      // Stop the queue processor
      _processingQueue = false;
      await queueProcessor;

      await subscriptionCloned.cancel();
      await subscriptionTerminated.cancel();
      await subscriptionDestination.cancel();
    }
    return targetPackets;
  }
}

Reactor buildReactorFromInput(String input, {bool verbose = false}) {
  final reactor = Reactor(verbose: verbose);
  final lines = input.trim().split('\n');
  for (final line in lines) {
    final parts = line.split(':');
    final fromName = parts[0].trim();
    final toNames = parts[1].trim().split(' ');
    for (final toName in toNames) {
      reactor.addConnection(fromName, toName.trim());
    }
  }
  return reactor;
}

Future<void> test() async {
  print('Running tests for Day 11...');
  final String testInput = '''
aaa: you hhh
you: bbb ccc
bbb: ddd eee
ccc: ddd eee fff
ddd: ggg
eee: out
fff: out
ggg: out
hhh: ccc fff iii
iii: out
''';

  final reactor = buildReactorFromInput(testInput, verbose: true);
  final Set<Packet> packets = await reactor.trace(
    'you',
    'out',
    timeoutSeconds: 2,
  );
  assert(packets.length == 5);
  print('Packets reaching destination: ${packets.length}');
  for (final packet in packets) {
    print('Packet path: ${packet.path.map((s) => s.name).join(' -> ')}');
  }

  final String testInputPt2 = '''
svr: aaa bbb
aaa: fft
fft: ccc
bbb: tty
tty: ccc
ccc: ddd eee
ddd: hub
hub: fff
eee: dac
dac: fff
fff: ggg hhh
ggg: out
hhh: out
''';

  final reactorPt2 = buildReactorFromInput(testInputPt2, verbose: true);
  final Set<Packet> packetsPt2 = await reactorPt2.trace(
    'svr',
    'out',
    requiredStops: ['fft', 'dac'],
    timeoutSeconds: 2,
  );

  assert(packetsPt2.length == 2);
  print(
    'Packets reaching destination with required stops: ${packetsPt2.length}',
  );
  for (final packet in packetsPt2) {
    print('Packet path: ${packet.path.map((s) => s.name).join(' -> ')}');
  }

  print('All tests passed for Day 11.');
}

Future<void> dec_11(bool verbose) async {
  print('Day 11: Reactor');
  await test();

  print("===== Running with puzzle input =====");
  print("=====================================");
  print("============= Part 1 ================");
  final File inputFile = File('bin/resources/dec_11_input.txt');
  final String rawInput = await inputFile.readAsString();
  final reactor = buildReactorFromInput(rawInput, verbose: verbose);
  final Set<Packet> packets = await reactor.trace(
    'you',
    'out',
    timeoutSeconds: 10,
  );
  if (verbose) {
    print("Packet paths reaching destination:");
    for (final packet in packets) {
      print('Packet path: ${packet.path.map((s) => s.name).join(' -> ')}');
    }
  }

  print('Packets from (you) reaching destination (out): ${packets.length}');

  packets.clear();

  print("============= Part 2 ================");
  // final reactor2 = buildReactorFromInput(rawInput, verbose: verbose);

  // part 2
  final Set<Packet> packetsPt2 = await reactor.trace(
    'svr',
    'out',
    requiredStops: ['fft', 'dac'],
    timeoutSeconds: 1200,
  );
  if (verbose) {
    print("Packet paths reaching destination with required stops:");
    for (final packet in packetsPt2) {
      print('Packet path: ${packet.path.map((s) => s.name).join(' -> ')}');
    }
  }
  print(
    'Packets from (svr) reaching destination (out) with required stops (fft, dac): ${packetsPt2.length}',
  );

  print('Day 11 completed.');
}

Future<void> main() async {
  await dec_11(true);
}
