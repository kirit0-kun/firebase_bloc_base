import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_bloc_base/src/domain/entity/response_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'working_state.dart';

export 'working_state.dart';

abstract class BaseWorkingBloc<Output> extends Cubit<BlocState<Output>> {
  String get anUnexpectedErrorOccurred => 'An Unexpected Error Occurred';
  String get defaultSuccessMessage => 'Success';
  String get defaultLoadingMessage => 'Loading';
  static const DEFAULT_OPERATION = '_DEFAULT_OPERATION';

  final scrollController = ScrollController();

  late Output _currentData;
  bool wasInitialized = false;
  Output get currentData {
    return _currentData;
  }

  Output? get safeData {
    return wasInitialized ? _currentData : null;
  }

  set currentData(Output data) {
    wasInitialized = true;
    _currentData = data;
  }

  final BehaviorSubject<BlocState<Output>> _statesSubject =
      BehaviorSubject<BlocState<Output>>();
  Stream<BlocState<Output>> get stateStream => _statesSubject
      .shareValue()
      .asBroadcastStream(onCancel: ((sub) => sub.cancel()));

  StreamSink<BlocState<Output>> get stateSink => _statesSubject.sink;

  Map<String, String> _operationStack = {};

  BaseWorkingBloc.work({required Output currentData}) : super(LoadingState()) {
    this.currentData = currentData;
    emitLoaded();
  }

  BaseWorkingBloc({Output? currentData}) : super(LoadingState()) {
    if (currentData != null || currentData?.runtimeType == Output) {
      this.currentData = currentData!;
      emitLoaded();
    }
  }

  @override
  void onChange(change) {
    handleTransition(change.nextState);
    super.onChange(change);
  }

  void handleTransition(BlocState<Output> state) {
    _statesSubject.add(state);
  }

  void setData(Output newData) {
    currentData = newData;
    emitLoaded();
  }

  void clean() {
    wasInitialized = false;
  }

  void emitLoading() {
    emit(LoadingState<Output>());
  }

  void emitLoaded() {
    emit(LoadedState<Output>(currentData));
  }

  void emitError(String message) {
    print("Emitting error");
    emit(ErrorState<Output>(message));
  }

  void checkOperations() {
    if (_operationStack.isNotEmpty && state is! Operation) {
      final item = _operationStack.entries.first;
      startOperation(item.value, operationTag: item.key);
    }
  }

  Future<Operation> handleOperation<T>(FutureOr<Either<Failure, T>> result,
      {String? loadingMessage,
      String? successMessage,
      String? operationTag}) async {
    operationTag ??= DEFAULT_OPERATION;
    startOperation(loadingMessage ?? this.defaultLoadingMessage,
        operationTag: operationTag);
    final future = await result;
    return handleResponse(future,
        successMessage: successMessage, operationTag: operationTag);
  }

  void interceptResponse(Future<Either<Failure, dynamic>> result,
      {void onSuccess()?, void onFailure()?}) {
    result.then((value) {
      value.fold((l) => onFailure?.call(), (r) => onSuccess?.call());
    });
  }

  Operation handleResponse<T>(Either<Failure, T> result,
      {String? successMessage, String? operationTag,bool emitIfFail = true,
        bool emitIfSuccess = true}) {
    operationTag ??= DEFAULT_OPERATION;
    return result.fold(
        (l) => failedOperation(l, operationTag: operationTag,doEmit: emitIfFail),
        (r) => successfulOperation(successMessage ?? this.defaultSuccessMessage,
            operationTag: operationTag, result: r,doEmit: emitIfSuccess));
  }

  void startOperation(String message, {String? operationTag}) {
    operationTag ??= DEFAULT_OPERATION;
    emit(OnGoingOperationState(
      data: currentData,
      loadingMessage: message,
      operationTag: operationTag,
    ));
    _operationStack[operationTag] = message;
    checkOperations();
  }

  void cancelOperation({String? operationTag}) {
    operationTag ??= DEFAULT_OPERATION;
    if (onCancel(operationTag: operationTag)) {
      emitLoaded();
      checkOperations();
    }
  }

  bool onCancel({String operationTag = DEFAULT_OPERATION}) => false;

  void removeOperation({String? operationTag}) {
    _operationStack.remove(operationTag ?? DEFAULT_OPERATION);
    emitLoaded();
    checkOperations();
  }

  SuccessfulOperationState<Output, dynamic> successfulOperation(String message,
      {String? operationTag, bool doEmit = true, dynamic result}) {
    operationTag ??= DEFAULT_OPERATION;
    final newState = SuccessfulOperationState(
        data: currentData,
        successMessage: message,
        operationTag: operationTag,
        result: result);
    if (doEmit) {
      emit(newState);
    }
    _operationStack.remove(operationTag);
    checkOperations();
    return newState;
  }

  FailedOperationState<Output> failedOperation(Failure failure,
      {String? operationTag,bool doEmit = true,}) {
    operationTag ??= DEFAULT_OPERATION;
    return _failedOperation(
        FailedOperationState.failure(
          data: currentData,
          failure: failure,
          operationTag: operationTag,
        ),
        doEmit: doEmit,
        operationTag: operationTag);
  }

  FailedOperationState<Output> failedOperationMessage(String message,
      {String? operationTag,bool doEmit = true,}) {
    operationTag ??= DEFAULT_OPERATION;
    return _failedOperation(
        FailedOperationState(
          data: currentData,
          message: message,
          operationTag: operationTag,
        ),
        doEmit: doEmit,
        operationTag: operationTag);
  }

  FailedOperationState<Output> _failedOperation(FailedOperationState<Output> op,
      {String? operationTag,bool doEmit = true,}) {
    if (doEmit) {
      emit(op);
    }
    _operationStack.remove(operationTag);
    checkOperations();
    return op;
  }

  void scrollUp() {
    scrollController.animateTo(0,
        duration: Duration(milliseconds: 300),
        curve: Curves.fastLinearToSlowEaseIn);
  }

  @override
  Future<void> close() {
    _statesSubject.drain().then((value) => _statesSubject.close());
    scrollController.dispose();
    return super.close();
  }
}
