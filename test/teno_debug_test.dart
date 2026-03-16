import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:teno_debug/teno_debug.dart';

// Test helpers

class _LogEntry {
  final String message;
  final String name;
  final Object? error;
  final StackTrace? stackTrace;

  _LogEntry(this.message, {this.name = '', this.error, this.stackTrace});
}

List<_LogEntry> _capturedLogs = [];

void _capturingPrinter(String message,
    {Object? error,
    int level = 0,
    String name = '',
    int? sequenceNumber,
    StackTrace? stackTrace,
    DateTime? time,
    Zone? zone}) {
  _capturedLogs
      .add(_LogEntry(message, name: name, error: error, stackTrace: stackTrace));
}

// Test bloc infrastructure

abstract class CounterEvent {}

class Increment extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
  }
}

class _MockBlocObserver implements BlocObserver {
  final List<String> calls = [];

  @override
  void onChange(BlocBase bloc, Change change) => calls.add('onChange');
  @override
  void onClose(BlocBase bloc) => calls.add('onClose');
  @override
  void onCreate(BlocBase bloc) => calls.add('onCreate');
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) =>
      calls.add('onError');
  @override
  void onEvent(Bloc bloc, Object? event) => calls.add('onEvent');
  @override
  void onTransition(Bloc bloc, Transition transition) =>
      calls.add('onTransition');
  @override
  void onDone(Bloc bloc, Object? event,
          [Object? error, StackTrace? stackTrace]) =>
      calls.add('onDone');
}

void main() {
  group('debugLog', () {
    setUp(() {
      _capturedLogs = [];
      Logger.root.level = Level.ALL;
      Logger.root.clearListeners();
    });

    test('logs messages from specified loggers', () {
      debugLog(['TestLogger'], _capturingPrinter);
      final logger = Logger('TestLogger');
      logger.info('hello');

      expect(_capturedLogs, hasLength(1));
      expect(_capturedLogs.first.message, 'hello');
      expect(_capturedLogs.first.name, 'TestLogger');
    });

    test('filters out messages from non-specified loggers', () {
      debugLog(['AllowedLogger'], _capturingPrinter);
      final logger = Logger('OtherLogger');
      logger.info('should be filtered');

      expect(_capturedLogs, isEmpty);
    });

    test('always logs SEVERE regardless of filter', () {
      debugLog(['AllowedLogger'], _capturingPrinter);
      final logger = Logger('OtherLogger');
      logger.severe('critical error');

      expect(_capturedLogs, hasLength(1));
      expect(_capturedLogs.first.message, 'critical error');
    });

    test('skips all loggers when filter list is empty', () {
      debugLog([], _capturingPrinter);
      final logger = Logger('AnyLogger');
      logger.info('should be skipped');

      expect(_capturedLogs, isEmpty);
    });

    test('passes error and stackTrace to printer', () {
      debugLog(['TestLogger'], _capturingPrinter);
      final logger = Logger('TestLogger');
      final error = Exception('test error');
      final stack = StackTrace.current;
      logger.severe('fail', error, stack);

      expect(_capturedLogs, hasLength(1));
      expect(_capturedLogs.first.error, error);
      expect(_capturedLogs.first.stackTrace, stack);
    });
  });

  group('BlocObserverComposite', () {
    late BlocObserverComposite composite;
    late _MockBlocObserver observer1;
    late _MockBlocObserver observer2;

    setUp(() {
      composite = BlocObserverComposite();
      observer1 = _MockBlocObserver();
      observer2 = _MockBlocObserver();
      composite.addBlocObserver(observer1);
      composite.addBlocObserver(observer2);
    });

    test('delegates onCreate to all observers', () {
      final bloc = CounterBloc();
      composite.onCreate(bloc);
      expect(observer1.calls, contains('onCreate'));
      expect(observer2.calls, contains('onCreate'));
      bloc.close();
    });

    test('delegates onClose to all observers', () {
      final bloc = CounterBloc();
      composite.onClose(bloc);
      expect(observer1.calls, contains('onClose'));
      expect(observer2.calls, contains('onClose'));
      bloc.close();
    });

    test('delegates onChange to all observers', () {
      final bloc = CounterBloc();
      composite.onChange(bloc, const Change(currentState: 0, nextState: 1));
      expect(observer1.calls, contains('onChange'));
      expect(observer2.calls, contains('onChange'));
      bloc.close();
    });

    test('delegates onError to all observers', () {
      final bloc = CounterBloc();
      composite.onError(bloc, 'error', StackTrace.empty);
      expect(observer1.calls, contains('onError'));
      expect(observer2.calls, contains('onError'));
      bloc.close();
    });

    test('delegates onEvent to all observers', () {
      final bloc = CounterBloc();
      composite.onEvent(bloc, Increment());
      expect(observer1.calls, contains('onEvent'));
      expect(observer2.calls, contains('onEvent'));
      bloc.close();
    });

    test('delegates onTransition to all observers', () {
      final bloc = CounterBloc();
      composite.onTransition(
          bloc,
          Transition(
              currentState: 0, event: Increment(), nextState: 1));
      expect(observer1.calls, contains('onTransition'));
      expect(observer2.calls, contains('onTransition'));
      bloc.close();
    });

    test('delegates onDone to all observers', () {
      final bloc = CounterBloc();
      composite.onDone(bloc, Increment());
      expect(observer1.calls, contains('onDone'));
      expect(observer2.calls, contains('onDone'));
      bloc.close();
    });

    test('removeBlocObserver stops delegation', () {
      composite.removeBlocObserver(observer2);
      final bloc = CounterBloc();
      composite.onCreate(bloc);
      expect(observer1.calls, contains('onCreate'));
      expect(observer2.calls, isEmpty);
      bloc.close();
    });
  });

  group('BlocDebugger', () {
    setUp(() => _capturedLogs = []);

    test('logs onCreate for filtered bloc type', () {
      final debugger = BlocDebugger([CounterBloc], false, _capturingPrinter);
      final bloc = CounterBloc();
      debugger.onCreate(bloc);

      expect(_capturedLogs, hasLength(1));
      expect(_capturedLogs.first.message, 'created');
      expect(_capturedLogs.first.name, 'CounterBloc');
      bloc.close();
    });

    test('skips onCreate for non-filtered bloc type', () {
      final debugger = BlocDebugger([], false, _capturingPrinter);
      final bloc = CounterBloc();
      debugger.onCreate(bloc);

      expect(_capturedLogs, isEmpty);
      bloc.close();
    });

    test('logs onClose for filtered bloc type', () {
      final debugger = BlocDebugger([CounterBloc], false, _capturingPrinter);
      final bloc = CounterBloc();
      debugger.onClose(bloc);

      expect(_capturedLogs, hasLength(1));
      expect(_capturedLogs.first.message, 'closed');
      bloc.close();
    });

    test('logs onEvent without details', () {
      final debugger = BlocDebugger([CounterBloc], false, _capturingPrinter);
      final bloc = CounterBloc();
      debugger.onEvent(bloc, Increment());

      expect(_capturedLogs, hasLength(1));
      expect(_capturedLogs.first.message, 'received Increment');
      bloc.close();
    });

    test('logs onEvent with details', () {
      final debugger = BlocDebugger([CounterBloc], true, _capturingPrinter);
      final bloc = CounterBloc();
      final event = Increment();
      debugger.onEvent(bloc, event);

      expect(_capturedLogs, hasLength(1));
      expect(_capturedLogs.first.message,
          contains('received Increment'));
      expect(_capturedLogs.first.message,
          contains(event.toString()));
      bloc.close();
    });

    test('logs onError always (regardless of filter)', () {
      final debugger = BlocDebugger([], false, _capturingPrinter);
      final bloc = CounterBloc();
      final error = Exception('boom');
      final stack = StackTrace.current;
      debugger.onError(bloc, error, stack);

      expect(_capturedLogs, hasLength(1));
      expect(_capturedLogs.first.error, error);
      expect(_capturedLogs.first.stackTrace, stack);
      bloc.close();
    });

    test('skips onChange when details is false', () {
      final debugger = BlocDebugger([CounterBloc], false, _capturingPrinter);
      final bloc = CounterBloc();
      debugger.onChange(bloc, const Change(currentState: 0, nextState: 1));

      expect(_capturedLogs, isEmpty);
      bloc.close();
    });

    test('logs onChange when details is true and bloc is filtered', () {
      final debugger = BlocDebugger([CounterBloc], true, _capturingPrinter);
      final bloc = CounterBloc();
      debugger.onChange(bloc, const Change(currentState: 0, nextState: 1));

      expect(_capturedLogs, hasLength(1));
      expect(_capturedLogs.first.message, contains('state changed'));
      expect(_capturedLogs.first.message, contains('From: 0'));
      expect(_capturedLogs.first.message, contains('To: 1'));
      bloc.close();
    });

    test('skips onTransition when details is false', () {
      final debugger = BlocDebugger([CounterBloc], false, _capturingPrinter);
      final bloc = CounterBloc();
      debugger.onTransition(
          bloc,
          Transition(
              currentState: 0, event: Increment(), nextState: 1));

      expect(_capturedLogs, isEmpty);
      bloc.close();
    });

    test('logs onTransition when details is true and bloc is filtered', () {
      final debugger = BlocDebugger([CounterBloc], true, _capturingPrinter);
      final bloc = CounterBloc();
      debugger.onTransition(
          bloc,
          Transition(
              currentState: 0, event: Increment(), nextState: 1));

      expect(_capturedLogs, hasLength(1));
      expect(_capturedLogs.first.message, contains('transitioning by Increment'));
      expect(_capturedLogs.first.message, contains('From: 0'));
      expect(_capturedLogs.first.message, contains('To: 1'));
      bloc.close();
    });

    test('logs onDone for filtered bloc type', () {
      final debugger = BlocDebugger([CounterBloc], false, _capturingPrinter);
      final bloc = CounterBloc();
      debugger.onDone(bloc, Increment());

      expect(_capturedLogs, hasLength(1));
      expect(_capturedLogs.first.message, 'event Increment completed');
      bloc.close();
    });

    test('logs onDone with error', () {
      final debugger = BlocDebugger([CounterBloc], false, _capturingPrinter);
      final bloc = CounterBloc();
      final error = Exception('fail');
      final stack = StackTrace.current;
      debugger.onDone(bloc, Increment(), error, stack);

      expect(_capturedLogs, hasLength(1));
      expect(_capturedLogs.first.message, 'event Increment completed with error');
      expect(_capturedLogs.first.error, error);
      expect(_capturedLogs.first.stackTrace, stack);
      bloc.close();
    });

    test('skips onDone for non-filtered bloc type', () {
      final debugger = BlocDebugger([], false, _capturingPrinter);
      final bloc = CounterBloc();
      debugger.onDone(bloc, Increment());

      expect(_capturedLogs, isEmpty);
      bloc.close();
    });
  });

  group('debugBloc', () {
    test('sets Bloc.observer to BlocObserverComposite', () {
      debugBloc([CounterBloc], false, _capturingPrinter);
      expect(Bloc.observer, isA<BlocObserverComposite>());
    });

    test('integrates with actual bloc lifecycle', () async {
      _capturedLogs = [];
      debugBloc([CounterBloc], true, _capturingPrinter);

      final bloc = CounterBloc();
      bloc.add(Increment());
      await Future<void>.delayed(Duration.zero);
      await bloc.close();

      final messages = _capturedLogs.map((l) => l.message).toList();
      expect(messages, contains('created'));
      expect(messages, contains(contains('received Increment')));
      expect(messages, contains('closed'));
    });
  });
}
