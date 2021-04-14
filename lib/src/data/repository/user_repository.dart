import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_bloc_base/firebase_bloc_base.dart';
import 'package:firebase_bloc_base/src/data/service/auth.dart';
import 'package:firebase_bloc_base/src/data/source/remote/user_data_source.dart';
import 'package:firebase_bloc_base/src/domain/entity/response_entity.dart';

import 'firebase_repository.dart';

abstract class BaseUserRepository<UserType extends FirebaseProfile>
    extends FirebaseRepository {
  final BaseAuth auth;
  final BaseUserDataSource<UserType> userDataSource;

  const BaseUserRepository(this.auth, this.userDataSource);

  String get notSignedInError => "You're not signed in";
  String get signedOutError => "You were signed out";
  String get requestError => "Couldn't complete your request";

  Stream<User> get userChanges {
    return auth.userChanges;
  }

  Stream<UserType> signIn(User user, bool isNewUser) {
    if (user != null) {
      final userAccountStream = userDataSource.listenToUser(user).map(
          (event) => event?.copyWith(userDetails: user, firstTime: isNewUser));
      return userAccountStream;
    }
    throw Exception(notSignedInError);
  }

  Stream<UserType> signUp(
      UserCredential user, String firstName, String lastName) {
    if (user != null) {
      final userAccountStream = userDataSource
          .createUser(user.user,
              firstName: firstName,
              lastName: lastName,
              requireConfirmation: false)
          .map((event) =>
              event?.copyWith(userDetails: user.user, firstTime: true));
      return userAccountStream;
    } else {
      throw Exception(requestError);
    }
  }

  Future<Either<Failure, Stream<UserType>>> signInWithEmailAndPassword(
      String email, String password) async {
    return tryWork(() async {
      final user = await auth.signIn(email, password);
      return signIn(user.user, user.additionalUserInfo.isNewUser);
    });
  }

  Future<Either<Failure, Stream<UserType>>> autoSignIn() async {
    return tryWork(() async {
      final user = await auth.getUser();
      return signIn(user, false);
    });
  }

  Future<ResponseEntity> signOut() async {
    return tryWorkWithResponse(() => auth.signOut());
  }

  Future<Either<Failure, Stream<UserType>>> signUpWithEmailAndPassword(
      String firstName, String lastName, String email, String password) async {
    return tryWork(() async {
      final user = await auth.signUp(email, password);
      return signUp(user, firstName, lastName);
    });
  }

  Future<Either<Failure, UserType>> updateUserAccount(UserType userAccount,
      [String phoneNumber,
      String email,
      Future<String> Function() getCode]) async {
    return tryWork(() async {
      if (email != null && email != userAccount.email) {
        await auth.changeEmail(email);
      }
      if (phoneNumber != null && phoneNumber != userAccount.phoneNumber) {
        await auth.setPhoneNumber(phoneNumber, getCode);
      }
      final user = await auth.getUser();
      if (user != null) {
        userAccount = userAccount.copyWith(userDetails: user);
        final newUserType = await userDataSource.updateUserAccount(userAccount);
        return newUserType;
      } else {
        throw Exception(signedOutError);
      }
    });
  }

  Future<Either<Failure, void>> resetPassword(
    String email,
  ) async {
    return tryWork(() => auth.resetPassword(email));
  }

  Future<Either<Failure, UserCredential>> addPhoneNumber(
      String phoneNumber, Future<String> Function() getCode) async {
    return tryWork(() => auth.setPhoneNumber(phoneNumber, getCode));
  }
}
