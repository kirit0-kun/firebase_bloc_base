import 'package:equatable/equatable.dart';

abstract class BaseProviderState<T> extends Equatable {
  const BaseProviderState();

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [];
}

class BaseLoadingState<T> extends BaseProviderState<T> {
  const BaseLoadingState();
}

class InvalidatedState<T> extends BaseProviderState<T> {
  const InvalidatedState();
}

class BaseLoadedState<T> extends BaseProviderState<T> {
  final T data;

  const BaseLoadedState(this.data);

  @override
  get props => [this.data];
}

class BaseErrorState<T> extends BaseProviderState<T> {
  final String? message;

  const BaseErrorState(this.message);

  @override
  get props => [this.message];
}
