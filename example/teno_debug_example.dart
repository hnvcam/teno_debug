import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:teno_debug/teno_debug.dart';

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
