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
      return handleError<T>(e, createFailure, customErrorIfNoMessage);
    }
  }

  Future<Either<Failure, T>> tryFutureWork<T>(
      FutureOr<Either<Failure, T>> work(),
      Failure createFailure(String message),
      [String customErrorIfNoMessage]) async {
    try {
      final result = await work();
      return result;
    } catch (e, s) {
      print(e);
      print(s);
      return handleError<T>(e, createFailure, customErrorIfNoMessage);
    }
  }

  Left<Failure, T> handleError<T>(error, Failure createFailure(String message),
      [String customErrorIfNoMessage]) {
    String message;
    try {
      message = error.message;
    } catch (e, s) {
      message ??= customErrorIfNoMessage ?? 'An unexpected error occurred';
    }
    return Left(createFailure(message));
  }
}
