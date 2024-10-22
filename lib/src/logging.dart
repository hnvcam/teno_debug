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

void simplifiedLog(String message,
    {Object? error,
    int level = 0,
    String name = '',
    int? sequenceNumber,
    StackTrace? stackTrace,
    DateTime? time,
    Zone? zone}) {
  log(message, name: name);
}
