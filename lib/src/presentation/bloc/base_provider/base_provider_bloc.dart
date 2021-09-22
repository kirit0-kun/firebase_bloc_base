import 'dart:async';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_bloc_base/src/domain/entity/response_entity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lazy_evaluation/lazy_evaluation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:worker_manager/worker_manager.dart';

import 'lifecycle_observer.dart';
import 'provider_state.dart';

export 'provider_state.dart';

extension BehaviorSubjectExtension<T> on BehaviorSubject<T> {
  T? get valueOrNull {
    return hasValue ? value : null;
  }
}

abstract class BaseProviderBloc<Input, Output>
    extends Cubit<BaseProviderState<Output>> with LifecycleAware {
  final LifecycleObserver? observer;

  final debounceMilliseconds = Duration(milliseconds: 100);
  final BehaviorSubject<Output?> dataSubject = BehaviorSubject<Output?>();
  final stateSubject = BehaviorSubject<BaseProviderState<Output>>();
  var _dataFuture = Completer<Output>();
  var _stateFuture = Completer<BaseProviderState<Output>>();

  String get anUnexpectedErrorOccurred => 'An unexpected error occurred';

  Output? get currentData => dataSubject.valueOrNull;

  Stream<Output?> get dataStream => LazyStream(() => dataSubject
      .shareValue()
      .asBroadcastStream(onCancel: ((sub) => sub.cancel())));

  Stream<BaseProviderState<Output>> get stateStream =>
      LazyStream(() => stateSubject
          .shareValue()
          .asBroadcastStream(onCancel: (sub) => sub.cancel()));

  Future<Output> get dataFuture => _dataFuture.future;
  Future<BaseProviderState<Output>> get stateFuture => _stateFuture.future;

  FutureOr<Either<Failure, Stream<Input>>>? get dataSource => null;
  Future<Either<Failure, Input>>? get result => null;

  List<Stream<BaseProviderState>> get additionalSources => [];

  Lazy<Output?>? latestDataLazy;
  Lazy<Output?>? latestCacheDataLazy;

  Output? get latestData => latestDataLazy?.value;
  Output? get latestCacheData => latestCacheDataLazy?.value;

  StreamSubscription? _listenerSub;
  Cancelable<Output>? _cancelable;

  Timer? _retryTimer;

  bool listening = false;

  BaseProviderBloc({bool getOnCreate = true, this.observer})
      : super(BaseLoadingState()) {
    if (getOnCreate) {
      getData();
    }
    observer?.addListener(this);
  }

  @override
  void onChange(change) {
    handleTransition(change.nextState);
    super.onChange(change);
  }

  void handleTransition(BaseProviderState<Output> state) {
    print('Emitting ${state.runtimeType} from ${this.runtimeType}');
    if (state is BaseLoadedState<Output>) {
      Output data = state.data;
      handleData(data);
      mapData(data);
      if (_dataFuture.isCompleted) {
        _dataFuture = Completer<Output>();
      }
      _dataFuture.complete(data);
    } else if (state is BaseErrorState<Output>) {
      handleData(null);
      mapData(null);
      dataSubject.addError(state);
      if (_dataFuture.isCompleted) {
        _dataFuture = Completer<Output>();
      }
      _dataFuture.completeError(state);
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(seconds: 15), () {
        if (listening) getData();
      });
    }
    if (state is! InvalidatedState<Output>) {
      stateSubject.add(state);
      if (_stateFuture.isCompleted) {
        _stateFuture = Completer<BaseProviderState<Output>>();
      }
      _stateFuture.complete(state);
    } else {
      reload();
    }
  }

  void mapData(Output? data) {
    latestDataLazy = Lazy(() => data);
    latestCacheDataLazy = Lazy(() => this.latestData);
    dataSubject.add(data);
  }

  Stream<T> convertStream<T>(Stream<T> input) => input;

  Future<void> _handleOperation(
      FutureOr<Either<Failure, Stream<Input>>> getOperation) async {
    emitLoading();
    final operation = await getOperation;
    await operation.fold(
      (l) async {
        emitError(l.message);
      },
      (r) async {
        await _handleStream(r);
      },
    );
  }

  Future<void> _handleDataRequest(
      FutureOr<Either<Failure, Input>> result) async {
    emitLoading();
    final operation = await result;
    operation.fold(
      (l) {
        emitError(l.message);
      },
      (r) {
        _handleStream(Stream.value(r));
      },
    );
  }

  Future<void> _handleStream(Stream<Input?> sourceStream) async {
    final dataStream = sourceStream
        .doOnError((e, s) {})
        .doOnData((event) {
          emitLoading();
          _cancelable?.cancel();
          _cancelable = null;
        })
        .switchMap<Tuple2<Input?, List<BaseProviderState<dynamic>>>>((event) {
          if (additionalSources.isEmpty) {
            return Stream.value(Tuple2(event, []));
          } else {
            return CombineLatestStream<BaseProviderState<dynamic>,
                    Tuple2<Input?, List<BaseProviderState<dynamic>>>>(
                additionalSources, (a) => Tuple2(event, a));
          }
        })
        .where(shouldProcessEvents)
        .debounceTime(debounceMilliseconds)
        .asyncMap((event) async {
          BaseErrorState? errorState = event.value2
                  .firstWhereOrNull((element) => element is BaseErrorState)
              as BaseErrorState<dynamic>?;
          if (errorState != null) {
            return createErrorState<Output>(errorState.message!);
          } else if (event.value2
              .any((element) => element is BaseLoadingState)) {
            return createLoadingState<Output>();
          } else {
            try {
              final data = event.value1;
              _cancelable?.cancel();
              final cancelable = _work(data);
              _cancelable = cancelable;
              final result = await cancelable;
              return createLoadedState(result);
            } catch (e, s) {
              print(e);
              print(s);
              print(this);
              if (e is! CanceledError) {
                throw e;
              }
            }
            return null;
          }
        });
    _listenerSub?.cancel();
    _listenerSub = convertStream(dataStream).doOnData((event) {
      emitLoading();
    }).listen(
      (event) {
        if (event != null) {
          emitState(event);
        }
      },
      onError: (e, s) {
        print(e);
        print(s);
        print(this);
        emitError(getExceptionMessage(e));
      },
    );
  }

  void stopListening() {
    _listenerSub?.cancel();
    _listenerSub = null;
    listening = false;
    _retryTimer?.cancel();
  }

  void handleData(Output? data) {}

  Future<Output> convert(Input? input);

  Cancelable<Output> _work(Input? input) {
    final result = convert(input);
    if (result is Cancelable<Output>) {
      return result;
    } else {
      final completer = Completer<Output>();
      completer.complete(result);
      return Cancelable(completer);
    }
  }

  bool shouldProcessEvents(
      Tuple2<Input?, List<BaseProviderState<dynamic>>> event) {
    return true;
  }

  @mustCallSuper
  Future<void> getData() async {
    listening = true;
    try {
      final result = this.result;
      final dataSource = this.dataSource;
      final additionalSources = this.additionalSources;
      if (dataSource != null) {
        await _handleOperation(dataSource);
      } else if (additionalSources.isNotEmpty) {
        await _handleStream(Stream.value(null));
      } else if (result != null) {
        await _handleDataRequest(result);
      }
    } catch (e,s) {
      listening = false;
      print(this.runtimeType);
      print(e);
      print(s);
      emitError(getExceptionMessage(e));
    }
  }

  void reload() {
    getData();
  }

  BaseProviderState<Output> createLoadingState<Output>() {
    return BaseLoadingState<Output>();
  }

  BaseProviderState<Output> createLoadedState<Output>(Output data) {
    return BaseLoadedState<Output>(data);
  }

  BaseProviderState<Output> createErrorState<Output>(String? message) {
    return BaseErrorState<Output>(message);
  }

  void emitState(BaseProviderState<Output> state) {
    if (state is BaseLoadingState<Output>) {
      emitLoading();
    } else if (state is BaseLoadedState<Output>) {
      emitLoaded(state.data);
    } else if (state is BaseErrorState<Output>) {
      emitError(state.message);
    }
  }

  void emitLoading() {
    emit(createLoadingState<Output>());
  }

  void emitLoaded(Output data) {
    emit(createLoadedState<Output>(data));
  }

  void emitError(String? message) {
    emit(createErrorState<Output>(message));
  }

  Stream<BaseProviderState<Out>> transformStream<Out>(
      {Out? outData, Stream<Out>? outStream}) {
    if (outStream != null) {
      return CombineLatestStream.list([stateStream, outStream]).map((event) {
        return _switch<Out>(
            event.first as BaseProviderState<Output>, event.last as Out);
      }).asBroadcastStream(onCancel: (sub) => sub.cancel());
    } else if (outData != null) {
      return stateStream.map((value) {
        return _switch<Out>(value, outData);
      }).asBroadcastStream(onCancel: (sub) => sub.cancel());
    } else {
      return stateStream.map((event) => BaseLoadingState<Out>());
    }
  }

  BaseProviderState<Out> _switch<Out>(
      BaseProviderState<Output> value, Out outData) {
    if (value is BaseLoadingState<Output>) {
      return createLoadingState<Out>();
    } else if (value is BaseErrorState<Output>) {
      return createErrorState<Out>(value.message);
    } else {
      return createLoadedState<Out>(outData);
    }
  }

  @override
  void onPause() {
    _listenerSub?.pause();
  }

  @override
  void onResume() {
    _listenerSub?.resume();
  }

  String getExceptionMessage(dynamic e) {
    try {
      return e.message;
    } catch (_) {
      return anUnexpectedErrorOccurred;
    }
  }

  @override
  Future<void> close() {
    observer?.removeListener(this);
    _listenerSub?.cancel();
    _cancelable?.cancel();
    dataSubject.drain().then((value) => dataSubject.close());
    stateSubject.drain().then((value) => stateSubject.close());
    _retryTimer?.cancel();
    return super.close();
  }
}
