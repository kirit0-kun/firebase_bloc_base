import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:worker_manager/worker_manager.dart';

import '../../../../firebase_bloc_base.dart';
import 'base_working_bloc.dart';

export 'working_state.dart';

abstract class MultiConverterBloc<Input, Output>
    extends BaseWorkingBloc<Input, Output> {
  final debounceMilliseconds = Duration(milliseconds: 100);

  Output currentData;

  StreamSubscription subscription;
  Cancelable<Output> _cancelable;

  List<Stream<BaseProviderState>> get sources => [];

  final _eventsSubject = BehaviorSubject<List<BaseProviderState>>();
  StreamSink<List<BaseProviderState>> get eventSink => _eventsSubject.sink;
  Stream<List<BaseProviderState>> get eventStream =>
      _eventsSubject.shareValue();

  MultiConverterBloc() : super() {
    subscription = convertStream(eventStream)
        .doOnData((event) {
          emitLoading();
          _cancelable?.cancel();
          _cancelable = null;
        })
        //.asBroadcastStream(onCancel: (sub) => sub.cancel())
        .where(shouldProcessEvents)
        .throttleTime(debounceMilliseconds, trailing: true)
        .listen(
          _handler,
          onError: (e, s) {
            print(e);
            print(s);
            print(this);
            try {
              emitError(e.message);
            } catch (_) {
              emitError('An unexpected error occurred');
            }
          },
        );
    if (sources?.isNotEmpty ?? false) {
      CombineLatestStream<BaseProviderState, List<BaseProviderState>>(
              sources, (a) => a)
          ?.asBroadcastStream(onCancel: (sub) => sub.cancel())
          ?.pipe(eventSink);
    }
  }

  Stream<List<BaseProviderState>> convertStream(
          Stream<List<BaseProviderState>> input) =>
      input;

  Input combineSources(List<BaseProviderState> events);

  Future<Output> convert(Input input);

  bool shouldProcessEvents(List<BaseProviderState<dynamic>> event) {
    return true;
  }

  Cancelable<Output> _work(Input input) {
    final result = convert(input);
    if (result is Cancelable<Output>) {
      return result;
    } else {
      final completer = Completer<Output>();
      completer.complete(result);
      return Cancelable(completer, () {
        // if (!completer.isCompleted) {
        //   completer.completeError(CanceledError());
        // }
      });
    }
  }

  void handleData(Output data) {}

  void _handler(List<BaseProviderState> events) async {
    _cancelable?.cancel();
    _cancelable = null;
    if (events.any((event) => event is BaseLoadingState)) {
      emitLoading();
    } else if (events.every((event) => event is BaseLoadedState)) {
      try {
        final data = combineSources(events);
        final cancelable = _work(data);
        _cancelable = cancelable;
        final newData = await cancelable;
        currentData = newData;
        handleData(newData);
        emitLoaded();
      } catch (e, s) {
        print(e);
        print(s);
        print(this);
        if (e is! CanceledError) {
          try {
            emitError(e.message);
          } catch (_) {
            emitError('An error occurred');
          }
        }
      }
    } else {
      BaseErrorState errorState = events.firstWhere(
          (element) => element is BaseErrorState,
          orElse: () => null);
      emitError(errorState?.message ?? 'An expected error occurred');
    }
  }

  @override
  Future<void> close() {
    subscription?.cancel();
    _cancelable?.cancel();
    _eventsSubject.drain().then((value) => _eventsSubject.close());
    return super.close();
  }
}

abstract class BaseConverterBloc<Input, Output>
    extends BaseWorkingBloc<Input, Output> {
  final debounceMilliseconds = Duration(milliseconds: 100);

  Output currentData;

  StreamSubscription subscription;
  Cancelable<Output> _cancelable;

  Stream<BaseProviderState<Input>> get source => sourceBloc?.stateStream;

  final BaseProviderBloc<dynamic, Input> sourceBloc;

  final _eventsSubject = BehaviorSubject<BaseProviderState<Input>>();
  StreamSink<BaseProviderState<Input>> get eventSink => _eventsSubject.sink;
  Stream<BaseProviderState<Input>> get eventStream => _eventsSubject
      .shareValue()
      .asBroadcastStream(onCancel: (sub) => sub.cancel());

  BaseConverterBloc({this.sourceBloc}) : super() {
    subscription = eventStream
        .doOnData((event) {
          emitLoading();
          _cancelable?.cancel();
          _cancelable = null;
        })
        .throttleTime(debounceMilliseconds, trailing: true)
        .listen(_handler, onError: (e, s) {
          print(e);
          print(s);
          print(this);
          print(sourceBloc?.state);
          try {
            emitError(e.message);
          } catch (_) {
            emitError('An unexpected error occurred');
          }
        });
    source?.pipe(eventSink);
  }

  void reload() {
    sourceBloc?.getData();
  }

  Future<Output> convert(Input input);

  Cancelable<Output> _work(Input input) {
    final result = convert(input);
    if (result is Cancelable<Output>) {
      return result;
    } else {
      final completer = Completer<Output>();
      completer.complete(result);
      return Cancelable(completer, () {
        // if (!completer.isCompleted) {
        //   completer.completeError(CanceledError());
        // }
      });
    }
  }

  void _handler(BaseProviderState event) async {
    if (event is BaseLoadingState<Input>) {
      emitLoading();
    } else if (event is BaseLoadedState<Input>) {
      try {
        final cancelable = _work(event.data);
        _cancelable = cancelable;
        final newData = await cancelable;
        currentData = newData;
        handleData(newData);
        emitLoaded();
      } catch (e, s) {
        print(e);
        print(s);
        print(this);
        if (e is! CanceledError) {
          try {
            emitError(e.message);
          } catch (_) {
            emitError('An error occurred');
          }
        }
      }
    } else if (event is BaseErrorState<Input>) {
      emitError(event.message);
    }
  }

  void handleData(Output data) {}

  @override
  Future<void> close() {
    subscription?.cancel();
    _cancelable?.cancel();
    _eventsSubject.drain().then((value) => _eventsSubject.close());
    return super.close();
  }
}
