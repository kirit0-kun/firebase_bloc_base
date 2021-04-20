import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_bloc_base/src/domain/entity/response_entity.dart';

abstract class FirebaseRepository {
  const FirebaseRepository();

  FutureOr<Either<Failure, T>> tryWork<T>(FutureOr<T> work(),
      [String customErrorIfNoMessage, Failure createFailure(String message)]) {
    try {
      final workSync = work();
      if (workSync is Future<T>) {
        Future<T> workAsync = workSync;
        return workAsync
            .then<Either<Failure, T>>((value) => Right<Failure, T>(value))
            .catchError((e, s) {
          print(e);
          print(s);
          return handleError<T>(e,
              createFailure: createFailure,
              customErrorIfNoMessage: customErrorIfNoMessage);
        });
      } else {
        T result = workSync;
        return Right(result);
      }
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
