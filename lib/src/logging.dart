import 'dart:async';
import 'dart:developer';

import 'package:logging/logging.dart';

/// Call this method before any other classes, right after the main() method to start logg filtering
/// When using with Flutter, recommend to check for debugging
/// ```
/// if (!kReleaseMode) {
/// 	debugLog(['loggerName1', 'loggerName2']);
/// }
/// ```
void debugLog(
    [List<String> loggerNames = const [],
    void Function(String,
            {Object? error,
            int level,
            String name,
            int? sequenceNumber,
            StackTrace? stackTrace,
            DateTime? time,
            Zone? zone})
        printer = simplifiedLog]) {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((event) {
    if (loggerNames.isEmpty || (event.level < Level.SEVERE && !loggerNames.contains(event.loggerName))) {
      return;
    }
    printer(event.message,
        name: event.loggerName,
        error: event.error,
        level: event.level.value,
        sequenceNumber: event.sequenceNumber,
        stackTrace: event.stackTrace,
        time: event.time,
        zone: event.zone);
  });
}

const _reset = '\x1B[0m';
const _darkYellow = '\x1B[38;5;178m'; // dark/golden yellow
const _red = '\x1B[31m';
const _dim = '\x1B[2m';

final _levelLabels = {
  0: 'ALL',
  300: 'FINEST',
  400: 'FINER',
  500: 'FINE',
  700: 'CONFIG',
  800: 'INFO',
  900: 'WARNING',
  1000: 'SEVERE',
  1200: 'SHOUT',
  2000: 'OFF',
};

void simplifiedLog(String message,
    {Object? error,
    int level = 0,
    String name = '',
    int? sequenceNumber,
    StackTrace? stackTrace,
    DateTime? time,
    Zone? zone}) {
  final label = _levelLabels[level] ?? 'LVL$level';
  final namePart = name.isNotEmpty ? '$_darkYellow[$name]$_reset ' : '';

  String line = '$label $namePart$message';

  if (error != null) {
    line += '\n${_red}ERROR:$_reset $namePart$error';
  }
  if (stackTrace != null) {
    line += '\n$_dim$stackTrace$_reset';
  }

  // Writes to stdout (console + Android logcat).
  // Note: Android logcat does not interpret ANSI escapes,
  // so coloring only renders in terminal consoles.
  print(line);

  // Also write to VM service / DevTools "Logging" view
  log(message, name: name, error: error, stackTrace: stackTrace, time: time, zone: zone, sequenceNumber: sequenceNumber, level: level);
}
