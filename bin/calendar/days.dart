library;

import '../common/day_registry.dart';
import 'dec_01.dart';
import 'dec_02.dart';
import 'dec_03.dart';
import 'dec_04.dart';
import 'dec_05.dart';
import 'dec_06.dart';
import 'dec_07.dart';
import 'dec_08.dart';
export '../common/day_registry.dart';

bool registerDays() {
  DayRegistry.register(1, dec_01);
  DayRegistry.register(2, dec_02);
  DayRegistry.register(3, dec_03);
  DayRegistry.register(4, dec_04);
  DayRegistry.register(5, dec_05);
  DayRegistry.register(6, dec_06);
  DayRegistry.register(7, dec_07);
  DayRegistry.register(8, dec_08);
  return true;
}

// Register all days when this library is imported.
final registered = registerDays();
