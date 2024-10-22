This package is a set of utilities for inspecting on specified logger (dart logging) or bloc.

## Features

- Filtering Logger ('package:logging/logging.dart')
- Filtering Bloc ('package:bloc/bloc.dart')


## Getting started

```
dart pub add dev:teno_debug
```

## Usage

Please make sure that you don't log for sensitive data and check for right condition before calling these utilities
For ex: ```if (!kReleaseMode) { ... }```

```dart
void main() {
  debugLog(['Class1', 'otherLoggerName']);

  debugBloc([SampleBloc]);
}

class Class1 {
  static final log = Logger('Class1');
}

class SampleBloc extends Bloc {
  SampleBloc(super.initialState);
}
```

## Additional information

TODO: 
- Add tests
- More information
- Improvement
