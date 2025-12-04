library;

import '../common/day_registry.dart';
import 'dec_01.dart';
import 'dec_02.dart';
import 'dec_03.dart';
export '../common/day_registry.dart';

bool registerDays() {
  DayRegistry.register(1, dec_01);
  DayRegistry.register(2, dec_02);
  DayRegistry.register(3, dec_03);
  return true;
}

// Register all days when this library is imported.
final registered = registerDays();
