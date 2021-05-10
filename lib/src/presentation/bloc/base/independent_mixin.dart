import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../firebase_bloc_base.dart';

export 'working_state.dart';

mixin IndependentMixin<Input, Output> on BaseConverterBloc<Input, Output> {
  bool get getDataWhenSourceChange => false;

  Either<Failure, Stream<Input>> get dataSourceStream => null;
  Either<Failure, Future<Input>> get dataSourceFuture => null;

  get source {
    Either<Failure, Stream<Input>> dataSource;
    dataSource = this.dataSourceStream;
    final dataSourceFuture = this.dataSourceFuture;
    if (dataSource == null) {
      dataSource = dataSourceFuture?.map((r) => r.asStream());
    }
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
      );
    }
    return null;
  }
}
