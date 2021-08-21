import 'package:equatable/equatable.dart';
import 'package:firebase_bloc_base/firebase_bloc_base.dart';

abstract class BlocState<T> extends Equatable {
  const BlocState();

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [];
}

abstract class Error {
  String? get message;
}

class LoadingState<T> extends BlocState<T> {}

class ErrorState<T> extends BlocState<T> implements Error {
  final String message;

  const ErrorState(this.message);

  @override
  List<Object?> get props => [this.message];
}

class InsufficientLicenseState<T> extends ErrorState<T> {
  const InsufficientLicenseState(String message) : super(message);

  @override
  List<Object?> get props => [...super.props];
}

class BranchRequiredState<T> extends ErrorState<T> {
  const BranchRequiredState(String message) : super(message);

  @override
  List<Object?> get props => [...super.props];
}

class LoadedState<T> extends BlocState<T> {
  final T data;

  const LoadedState(this.data);

  @override
  List<Object?> get props => [this.data];
}

abstract class Operation {
  String? get operationTag;
}

class OnGoingOperationState<T> extends LoadedState<T>
    implements Operation, LoadingState<T> {
  final String? operationTag;
  final String? loadingMessage;

  const OnGoingOperationState(
      {required T data, this.loadingMessage, this.operationTag})
      : super(data);

  @override
  List<Object?> get props =>
      [...super.props, this.operationTag, this.loadingMessage];
}

class FailedOperationState<T> extends LoadedState<T>
    with Operation
    implements Error {
  final String? operationTag;
  final Failure? failure;

  String? get message => failure?.message;

  FailedOperationState(
      {required T data, this.operationTag, required String message})
      : failure = Failure(message),
        super(data);

  const FailedOperationState.failure(
      {required T data, this.operationTag, this.failure})
      : super(data);

  @override
  List<Object?> get props => [...super.props, this.operationTag, this.failure];
}

class SuccessfulOperationState<T, S> extends LoadedState<T> with Operation {
  final String? operationTag;
  final String? successMessage;
  final S? result;

  const SuccessfulOperationState(
      {required T data, this.operationTag, this.successMessage, this.result})
      : super(data);

  @override
  List<Object?> get props =>
      [...super.props, this.operationTag, this.successMessage];
}
