# teno_debug

A set of debugging utilities for filtering and inspecting Dart [Logger](https://pub.dev/packages/logging) and [Bloc](https://pub.dev/packages/bloc) output.

## Features

- **Logger filtering** - Only print log messages from specified logger names, while always surfacing `SEVERE` errors.
- **Bloc filtering** - Observe lifecycle events (create, close, event, transition, error, done) for specified Bloc types.
- **Composite observer** - Combine multiple `BlocObserver` instances via `BlocObserverComposite`.
- **Detail mode** - Optionally log state changes and transition details for deeper inspection.

## Requirements

| Dependency | Minimum version |
|------------|----------------|
| Dart SDK   | 3.5.0          |
| logging    | 1.3.0          |
| bloc       | 9.2.0          |

## Getting started

```
dart pub add teno_debug
```

## Usage

Make sure you only enable debug logging in non-release builds to avoid exposing sensitive data.

```dart
import 'package:logging/logging.dart';
import 'package:bloc/bloc.dart';
import 'package:teno_debug/teno_debug.dart';

void main() {
  // Only log messages from 'Class1' and 'otherLoggerName' loggers
  debugLog(['Class1', 'otherLoggerName']);

  // Observe lifecycle events for SampleBloc only
  // Set details to true for state change and transition info
  debugBloc([SampleBloc], true);
}

class Class1 {
  static final log = Logger('Class1');

  void doWork() {
    log.info('doing work');
  }
}

class SampleEvent {}

class SampleBloc extends Bloc<SampleEvent, int> {
  SampleBloc() : super(0) {
    on<SampleEvent>((event, emit) => emit(state + 1));
  }
}
```

### Custom printer

Both `debugLog` and `debugBloc` accept an optional `printer` parameter if you want to replace the default `dart:developer` log output:

```dart
debugLog(['MyLogger'], (message, {error, level, name, sequenceNumber, stackTrace, time, zone}) {
  print('[$name] $message');
});
```

## Additional information

For bugs and feature requests, please file an issue at the [GitHub repository](https://github.com/hnvcam/teno_debug).
