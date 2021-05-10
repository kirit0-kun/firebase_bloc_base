import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../firebase_bloc_base.dart';

export 'working_state.dart';

mixin IndependentMixin<Input, Output> on BaseConverterBloc<Input, Output> {
  bool get getDataWhenSourceChange => false;

  Either<Failure, Stream<Input>> get dataSourceStream => null;
  Future<Either<Failure, Input>> get dataSourceFuture => null;

  get source {
    final dataSource = this.dataSourceStream;
    if (dataSource != null) {
      return dataSource.fold(
        (failure) => Stream.value(BaseErrorState<Input>(failure.message)),
        (stream) => stream
            .map<BaseProviderState<Input>>(
                (event) => BaseLoadedState<Input>(event))
            .handleError((e, s) {
          String error;
          try {
            error = e.message;
          } catch (_) {
            error = this.anUnexpectedErrorOccurred;
          }
          return BaseErrorState<Input>(error);
        }).cast<BaseProviderState<Input>>(),
      ).startWith(BaseLoadingState<Input>());
    }
    final dataSourceFuture = this.dataSourceFuture;
    if (dataSourceFuture != null) {
      return dataSourceFuture.asStream().map((event) {
        return event.fold(
          (failure) => BaseErrorState<Input>(failure.message),
          (input) => BaseLoadedState<Input>(input),
        );
      }).startWith(BaseLoadingState<Input>());
    }
    return null;
  }
}
