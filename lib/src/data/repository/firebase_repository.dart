import 'dart:async';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:dartz/dartz.dart';

abstract class FirebaseRepository extends BaseRepository {
  const FirebaseRepository();

  Either<Failure, T> tryWork<T>(FutureOr<Either<Failure, T>> work(),
      Failure createFailure(String message),
      [String customErrorIfNoMessage]) {
    try {
      final result = work();
      return result;
    } catch (e, s) {
      print(e);
      print(s);
      return handleError<T>(e,
          createFailure: createFailure,
          customErrorIfNoMessage: customErrorIfNoMessage);
    }
  }

  Future<Either<Failure, T>> tryFutureWork<T>(
      FutureOr<Either<Failure, T>> work(),
      [String customErrorIfNoMessage,
      Failure createFailure(String message)]) async {
    try {
      final result = await work();
      return result;
    } catch (e, s) {
      print(e);
      print(s);
      return handleError<T>(e,
          createFailure: createFailure,
          customErrorIfNoMessage: customErrorIfNoMessage);
    }
  }

  Left<Failure, T> handleError<T>(error,
      {String customErrorIfNoMessage, Failure createFailure(String message)}) {
    String message = getErrorMessage(error, customErrorIfNoMessage);
    createFailure ??= (message) => Failure(message);
    return Left(createFailure(message));
  }

  FutureOr<ResponseEntity> tryWorkWithResponse(FutureOr work(),
      [String customErrorIfNoMessage]) async {
    try {
      await work();
      return Success();
    } catch (e, s) {
      print(e);
      print(s);
      return Failure(getErrorMessage(e, customErrorIfNoMessage));
    }
  }

  String getErrorMessage(error, [String customErrorIfNoMessage]) {
    String message;
    try {
      message = error.message;
    } catch (e, s) {
      message ??= customErrorIfNoMessage ?? 'An unexpected error occurred';
    }
    return message;
  }
}
