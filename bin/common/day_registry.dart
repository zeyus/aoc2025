// This is just a class for registering the days
// to load them in the main script.
import 'dart:async';

class DayRegistry {
  static final DayRegistry instance = DayRegistry._internal();

  /// The "main" function for each day is stored here.
  static final Map<int, Function> _days = {};

  /// Get a specific day
  static Function? getDay(int day) {
    return _days[day];
  }

  /// Register a day
  static void register(int day, FutureOr<void> Function(bool) dayFunction) {
    _days[day] = dayFunction;
  }

  static List<int> get registeredDays => _days.keys.toList();

  DayRegistry._internal();
}
