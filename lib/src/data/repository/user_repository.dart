import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_bloc_base/firebase_bloc_base.dart';
import 'package:firebase_bloc_base/src/data/service/auth.dart';
import 'package:firebase_bloc_base/src/data/source/remote/user_data_source.dart';

import 'firebase_repository.dart';

abstract class UserRepository<T extends FirebaseProfile>
    extends FirebaseRepository {
  final BaseAuth auth;
  final UserDataSource<T> userDataSource;

  const UserRepository(this.auth, this.userDataSource);

  Stream<User> get userChanges {
    return auth.userChanges;
  }

  Future<Either<Failure, Stream<T>>> signIn(
      String email, String password) async {
    try {
      final user = await auth.signIn(email, password);
      if (user != null) {
        final userAccountStream = userDataSource
            .listenToUser(user.user.uid)
            .map((event) => event?.copyWith(userDetails: user.user));
        return Right(userAccountStream);
      }
      return Left(Failure('Failed to sign you in.'));
    } catch (e, s) {
      print(e);
      print(s);
      return handleError<Stream<T>>(e, (message) => Failure(message));
    }
  }

  Future<Either<Failure, Stream<T>>> autoSignIn() async {
    try {
      final user = await auth.getUser();
      if (user != null) {
        final userAccountStream = userDataSource
            .listenToUser(user.uid)
            .map((event) => event?.copyWith(userDetails: user));
        return Right(userAccountStream);
      }
      return Left(Failure('Failed to sign you in.'));
    } catch (e, s) {
      print(e);
      print(s);
      return handleError<Stream<T>>(e, (message) => Failure(message));
    }
  }

  Future<Failure> signOut() async {
    try {
      final user = await auth.signOut();
      return null;
    } catch (e, s) {
      print(e);
      print(s);
      return handleError<void>(e, (message) => Failure(message)).value;
    }
  }

  Future<Either<Failure, Stream<T>>> signUp(
      String firstName, String lastName, String email, String password) async {
    try {
      final user = await auth.signUp(email, password);
      if (user != null) {
        final userAccountStream = userDataSource
            .createUser(user.user,
                firstName: firstName,
                lastName: lastName,
                requireConfirmation: false)
            .map((event) => event?.copyWith(userDetails: user.user));
        return Right(userAccountStream);
      }
      return Left(Failure('Failed to sign you up.'));
    } catch (e, s) {
      print(e);
      print(s);
      return handleError<Stream<T>>(e, (message) => Failure(message));
    }
  }

  Future<Either<Failure, T>> updateUserAccount(T userAccount,
      [String phoneNumber,
      String email,
      Future<String> Function() getCode]) async {
    try {
      if (email != null && email != userAccount.email) {
        await auth.changeEmail(email);
      }
      if (phoneNumber != null && phoneNumber != userAccount.phoneNumber) {
        await auth.setPhoneNumber(phoneNumber, getCode);
      }
      final user = await auth.getUser();
      if (user != null) {
        userAccount = userAccount.copyWith(userDetails: user);
        final newT = await userDataSource.updateUserAccount(userAccount, false);
        return Right(newT);
      } else {
        return Left(Failure("You were signed out."));
      }
    } catch (e, s) {
      print(e);
      print(s);
      return handleError<T>(e, (message) => Failure(message));
    }
  }

  Future<Either<Failure, void>> resetPassword(
    String email,
  ) async {
    try {
      return Right(await auth.resetPassword(email));
    } catch (e, s) {
      print(e);
      print(s);
      return handleError<void>(e, (message) => Failure(message));
    }
  }

  Future<Either<Failure, UserCredential>> addPhoneNumber(
      String phoneNumber, Future<String> Function() getCode) async {
    try {
      final result = await auth.setPhoneNumber(phoneNumber, getCode);
      return Right(result);
    } catch (e, s) {
      print(e);
      print(s);
      return handleError<UserCredential>(e, (message) => Failure(message));
    }
  }
}
