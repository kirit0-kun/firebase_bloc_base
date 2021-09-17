import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_bloc_base/src/domain/entity/response_entity.dart';

abstract class FirebaseRepository {
  const FirebaseRepository();

  String get anUnexpectedErrorOccurred => 'An unexpected error occurred';

  @protected
  Future<Either<Failure, T>> tryWork<T>(Future<T> work(),
      [String? customErrorIfNoMessage,
      Failure createFailure(String message)?]) async {
    try {
      final workAsync = work();
      return workAsync
          .then<Either<Failure, T>>((value) => Right<Failure, T>(value))
          .catchError((e, s) {
        print(e);
        print(s);
        return handleError<T>(e,
            createFailure: createFailure,
            customErrorIfNoMessage: customErrorIfNoMessage);
      });
    } catch (e, s) {
      print(e);
      print(s);
      return handleError<T>(e,
          createFailure: createFailure,
          customErrorIfNoMessage: customErrorIfNoMessage);
    }
  }

  @protected
  Either<Failure, T> tryWorkSync<T>(T work(),
      [String? customErrorIfNoMessage,
      Failure createFailure(String message)?]) {
    try {
      final result = work();
      return Right(result);
    } catch (e, s) {
      print(e);
      print(s);
      return handleError<T>(e,
          createFailure: createFailure,
          customErrorIfNoMessage: customErrorIfNoMessage);
    }
  }

  @protected
  Left<Failure, T> handleError<T>(error,
      {String? customErrorIfNoMessage,
      Failure createFailure(String message)?}) {
    final message = getErrorMessage(error, customErrorIfNoMessage);
    createFailure ??= (message) => Failure(message);
    return Left(createFailure(message));
  }

  @protected
  FutureOr<ResponseEntity> tryWorkWithResponse(FutureOr work(),
      [String? customErrorIfNoMessage]) async {
    try {
      await work();
      return Success();
    } catch (e, s) {
      print(e);
      print(s);
      return Failure(getErrorMessage(e, customErrorIfNoMessage));
    }
  }

  @protected
  String getErrorMessage(error, [String? customErrorIfNoMessage]) {
    String? message;
    try {
      message = error.message;
    } catch (e, s) {
      message ??= customErrorIfNoMessage ?? this.anUnexpectedErrorOccurred;
    }
    return message!;
  }
}
