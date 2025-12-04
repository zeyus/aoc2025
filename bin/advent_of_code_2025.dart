import 'package:args/args.dart';
import 'calendar/days.dart';

const String version = '0.0.1';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addOption(
      'day',
      abbr: 'd',
      help: 'Specify the day to run (1-14).',
      allowed: List<String>.generate(14, (index) => '${index + 1}'),
      mandatory: true,
    )
    ..addFlag(
      'list',
      abbr: 'l',
      negatable: false,
      help: 'List all implemented days.',
    )
    ..addFlag('version', negatable: false, help: 'Print the tool version.');
}

void printUsage(ArgParser argParser) {
  print('Usage: dart advent_of_code_2025.dart [options]');
  print(argParser.usage);
}

void main(List<String> arguments) {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);
    bool verbose = false;

    // Process the parsed arguments.
    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }
    if (results.flag('version')) {
      print('advent_of_code_2025 version: $version');
      return;
    }
    if (results.flag('verbose')) {
      verbose = true;
    }
    if (!registered) {
      print('No days have been registered. Exiting.');
      return;
    }
    if (results.flag('list')) {
      final days = DayRegistry.registeredDays;
      if (days.isEmpty) {
        print('No days have been implemented yet.');
      } else {
        print('Implemented days: ${days.join(', ')}');
      }
      return;
    }

    final int day = int.parse(results.option('day')!);
    final Function? dayFunction = DayRegistry.getDay(day);
    if (dayFunction == null) {
      print('Day $day is not implemented yet.');
      return;
    }
    if (verbose) {
      print('Running Day $day...');
    }
    dayFunction(verbose);
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e.message);
    print('');
    printUsage(argParser);
  }
}
