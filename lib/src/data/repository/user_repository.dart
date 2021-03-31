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

  Future<Either<Failure, Stream<T>>> signIn(String email, String password) {
    return tryFutureWork<Stream<T>>(() async {
      final user = await auth.signIn(email, password);
      if (user != null) {
        final userAccountStream = userDataSource
            .listenToUser(user.user.uid)
            .map((event) => event?.copyWith(
                userDetails: user.user,
                isNewUser: user.additionalUserInfo.isNewUser));
        return Right(userAccountStream);
      }
      return Left(Failure('Failed to sign you in.'));
    });
  }

  Future<Either<Failure, Stream<T>>> autoSignIn() async {
    return tryFutureWork<Stream<T>>(() async {
      final user = await auth.getUser();
      if (user != null) {
        final userAccountStream = userDataSource.listenToUser(user.uid).map(
            (event) => event?.copyWith(userDetails: user, isNewUser: false));
        return Right(userAccountStream);
      }
      return Left(Failure('Failed to sign you in.'));
    });
  }

  Future<ResponseEntity> signOut() {
    return tryWorkWithResponse(() => auth.signOut());
  }

  Future<Either<Failure, Stream<T>>> signUp(
      String firstName, String lastName, String email, String password) async {
    return tryFutureWork<Stream<T>>(() async {
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
    });
  }

  Future<Either<Failure, T>> updateUserAccount(T userAccount,
      [String phoneNumber,
      String email,
      Future<String> Function() getCode]) async {
    return tryFutureWork<T>(() async {
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
    });
  }

  Future<ResponseEntity> resetPassword(
    String email,
  ) {
    return tryWorkWithResponse(() => auth.resetPassword(email));
  }

  Future<ResponseEntity> addPhoneNumber(
      String phoneNumber, Future<String> Function() getCode) {
    return tryWorkWithResponse(() => auth.setPhoneNumber(phoneNumber, getCode));
  }

  Future<ResponseEntity> changePassword(String oldPassword, String password) {
    return tryWorkWithResponse(
        () => auth.changePassword(oldPassword, password));
  }
}
