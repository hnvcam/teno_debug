import 'dart:async';
// ignore: depend_on_referenced_packages
import 'package:bloc/bloc.dart';

import '../teno_debug.dart';

void debugBloc(
    [List<Type> filters = const [],
    bool details = false,
    void Function(String,
            {Object? error,
            int level,
            String name,
            int? sequenceNumber,
            StackTrace? stackTrace,
            DateTime? time,
            Zone? zone})
        printer = simplifiedLog]) {
  final blocObserverComposite = BlocObserverComposite();
  blocObserverComposite.addBlocObserver(BlocDebugger(filters, details, printer));
  Bloc.observer = blocObserverComposite;
}

class BlocObserverComposite implements BlocObserver {
  final List<BlocObserver> observers = [];

  BlocObserverComposite();

  void addBlocObserver(BlocObserver observer) {
    observers.add(observer);
  }

  void removeBlocObserver(BlocObserver blocObserver) {
    observers.remove(blocObserver);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    for (var element in observers) {
      element.onChange(bloc, change);
    }
  }

  @override
  void onClose(BlocBase bloc) {
    for (var element in observers) {
      element.onClose(bloc);
    }
  }

  @override
  void onCreate(BlocBase bloc) {
    for (var element in observers) {
      element.onCreate(bloc);
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    for (var element in observers) {
      element.onError(bloc, error, stackTrace);
    }
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    for (var element in observers) {
      element.onEvent(bloc, event);
    }
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    for (var element in observers) {
      element.onTransition(bloc, transition);
    }
  }
}

class BlocDebugger implements BlocObserver {
  final List<Type> filters;
  final bool details;
  final void Function(String,
      {Object? error,
      int level,
      String name,
      int? sequenceNumber,
      StackTrace? stackTrace,
      DateTime? time,
      Zone? zone}) printer;

  const BlocDebugger(this.filters, this.details, this.printer);

  bool _showLog(BlocBase<dynamic> bloc) => filters.contains(bloc.runtimeType);

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    if (!details || !_showLog(bloc)) return;
    printer('state changed:\n\tFrom: ${change.currentState} \n\tTo: ${change.nextState}',
        name: bloc.runtimeType.toString()); // Covered by onTransition
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    if (!_showLog(bloc)) return;
    printer('closed', name: bloc.runtimeType.toString());
  }

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    if (!_showLog(bloc)) return;
    printer('created', name: bloc.runtimeType.toString());
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    printer(error.toString(), error: error, stackTrace: stackTrace, name: bloc.runtimeType.toString());
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    if (!_showLog(bloc)) return;
    printer("received ${event.runtimeType}${details ? ': ${event.toString()}' : ''}",
        name: bloc.runtimeType.toString());
  }

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    if (!details || !_showLog(bloc)) return;
    printer(
        'transitioning by ${transition.event.runtimeType}:\n\tFrom: ${transition.currentState} \n\tTo: ${transition.nextState}',
        name: bloc.runtimeType.toString());
  }
}
