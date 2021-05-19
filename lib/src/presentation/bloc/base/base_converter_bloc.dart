import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:worker_manager/worker_manager.dart';

import '../../../../firebase_bloc_base.dart';
import 'base_working_bloc.dart';

export 'working_state.dart';

abstract class BaseConverterBloc<Input, Output>
    extends BaseWorkingBloc<Output> {
  final debounceMilliseconds = Duration(milliseconds: 100);

  StreamSubscription subscription;
  StreamSubscription dataSubscription;
  StreamSubscription sinkSubscription;
  Cancelable<Output> _cancelable;

  Stream<BaseProviderState<Input>> get source => sourceBloc?.stateStream;

  final BaseProviderBloc<dynamic, Input> sourceBloc;

  List<Stream<BaseProviderState>> get additionalSources => null;

  Stream<List<BaseProviderState>> get combinedSource {
    final source = this.source;
    final additionalSources = this.additionalSources;
    List<Stream<BaseProviderState>> streams = [
      if (source != null) source,
      if (additionalSources?.isNotEmpty == true) ...additionalSources,
    ];
    return CombineLatestStream<BaseProviderState, List<BaseProviderState>>(
        streams, (a) => a).asBroadcastStream(onCancel: (sub) => sub.cancel());
  }

  final _eventsSubject = StreamController<List<BaseProviderState>>.broadcast();
  StreamSink<List<BaseProviderState>> get eventSink => _eventsSubject.sink;
  Stream<List<BaseProviderState>> get eventStream =>
      _eventsSubject.stream;

  final _dataSubject = StreamController<Output>.broadcast();
  StreamSink<Output> get dataSink => _dataSubject.sink;
  Stream<Output> get dataStream =>
      _dataSubject.stream;

  BaseConverterBloc(
      {this.sourceBloc, Output currentData, bool getOnCreate = true})
      : super(currentData: currentData) {
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
    dataSubscription = dataStream.listen(super.setData);
    if (getOnCreate) {
      getData();
    }
  }

  Stream<List<BaseProviderState>> convertStream(
          Stream<List<BaseProviderState>> input) =>
      input;

  bool shouldProcessEvents(List<BaseProviderState<dynamic>> event) {
    return true;
  }

  void getData() {
    sinkSubscription?.cancel();
    sinkSubscription = combinedSource?.listen((event) => eventSink.add(event));
  }

  void setData(Output newData) {
    dataSink.add(newData);
  }

  void reload() {
    clean();
    if (sourceBloc == null) {
      getData();
    } else {
      sourceBloc.getData();
    }
  }

  void reset() async {
    clean();
    return getData();
  }

  @mustCallSuper
  void refresh() async {
    clean();
    return reload();
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

  Input combineSources(List<BaseLoadedState> events) {
    final dataEvent = events.firstWhere(
        (element) => element is BaseLoadedState<Input>,
        orElse: () => null);
    return dataEvent?.data;
  }

  void _handler(List<BaseProviderState> events) async {
    _cancelable?.cancel();
    _cancelable = null;
    if (events.any((event) => event is BaseLoadingState)) {
      emitLoading();
    } else if (events.every((event) => event is BaseLoadedState)) {
      try {
        final data = combineSources(events.cast<BaseLoadedState>());
        final cancelable = _work(data);
        _cancelable = cancelable;
        final newData = await cancelable;
        handleInput(data);
        handleData(newData);
        setData(newData);
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

  void handleInput(Input data) {}
  void handleData(Output data) {}

  @override
  Future<void> close() {
    subscription?.cancel();
    dataSubscription?.cancel();
    sinkSubscription?.cancel();
    _cancelable?.cancel();
    _eventsSubject.close();
    _dataSubject.close();
    return super.close();
  }
}
