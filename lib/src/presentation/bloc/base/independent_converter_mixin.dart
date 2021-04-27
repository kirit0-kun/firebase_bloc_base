import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../firebase_bloc_base.dart';

export 'working_state.dart';

mixin IndependentConverterMixin<Input, Output>
    on BaseConverterBloc<Input, Output> {
  bool get getDataWhenSourceChange => false;
  Either<Failure, Stream<Input>> get dataSource;

  Stream<BaseProviderState<Input>> get source {
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

mixin IndependentMultiConverterMixin<Input, Output>
    on MultiConverterBloc<Input, Output> {
  Either<Failure, Stream> get dataSource;

  get sources {
    Stream<BaseProviderState> source;
    if (dataSource != null) {
      source = dataSource.fold(
        (failure) => Stream.value(BaseErrorState(failure.message)),
        (stream) => stream
            .map<BaseProviderState>((event) => BaseLoadedState(event))
            .handleError((e, s) {
          String error;
          try {
            error = e.message;
          } catch (_) {
            error = this.anUnexpectedErrorOccurred;
          }
          return BaseErrorState(error);
        }).cast<BaseProviderState>(),
      );
    }
    return [if (source != null) source, ...super.sources];
  }
}
