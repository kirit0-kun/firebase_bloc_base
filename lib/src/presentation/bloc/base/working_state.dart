import 'package:equatable/equatable.dart';

abstract class BlocState<T> extends Equatable {
  const BlocState();

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [];
}

class LoadingState<T> extends BlocState<T> {}

class ErrorState<T> extends BlocState<T> {
  final String message;

  const ErrorState(this.message);

  @override
  List<Object> get props => [this.message];
}

class InsufficientLicenseState<T> extends ErrorState<T> {
  const InsufficientLicenseState(String message) : super(message);

  @override
  List<Object> get props => [...super.props];
}

class BranchRequiredState<T> extends ErrorState<T> {
  const BranchRequiredState(String message) : super(message);

  @override
  List<Object> get props => [...super.props];
}

class LoadedState<T> extends BlocState<T> {
  final T data;

  const LoadedState(this.data);

  @override
  List<Object> get props => [this.data];
}

abstract class Operation {
  String get operationTag;
}

class OnGoingOperationState<T> extends LoadedState<T>
    implements Operation, LoadingState<T> {
  final String operationTag;
  final String loadingMessage;

  const OnGoingOperationState({T data, this.loadingMessage, this.operationTag})
      : super(data);

  @override
  List<Object> get props =>
      [...super.props, this.operationTag, this.loadingMessage];
}

class FailedOperationState<T> extends LoadedState<T> with Operation {
  final String operationTag;
  final String errorMessage;

  const FailedOperationState({T data, this.operationTag, this.errorMessage})
      : super(data);

  @override
  List<Object> get props =>
      [...super.props, this.operationTag, this.errorMessage];
}

class SuccessfulOperationState<T, S> extends LoadedState<T> with Operation {
  final String operationTag;
  final String successMessage;
  final S result;

  const SuccessfulOperationState(
      {T data, this.operationTag, this.successMessage, this.result})
      : super(data);

  @override
  List<Object> get props =>
      [...super.props, this.operationTag, this.successMessage];
}
