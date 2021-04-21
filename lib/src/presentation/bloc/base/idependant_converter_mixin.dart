import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../firebase_bloc_base.dart';

export 'working_state.dart';

mixin IndependentConverterMixin<Input, Output>
    on BaseConverterBloc<Input, Output> {
  Either<Failure, Stream<Input>> get dataSource;

  Stream<BaseProviderState<Input>> get source {
    if (dataSource != null) {
      return dataSource.fold(
        (failure) => Stream.value(BaseErrorState<Input>(failure.message)),
        (stream) => stream
            .map((event) => BaseLoadedState<Input>(event))
            .handleError((e, s) {
          String error;
          try {
            error = e.message;
          } catch (_) {
            error = this.anUnexpectedErrorOccurred;
          }
          return BaseErrorState<Input>(error);
        }),
      );
    }
    return null;
  }
}
