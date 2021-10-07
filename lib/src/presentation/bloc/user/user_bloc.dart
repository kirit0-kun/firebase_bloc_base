import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_bloc_base/src/data/repository/user_repository.dart';
import 'package:firebase_bloc_base/src/domain/entity/response_entity.dart';
import 'package:firebase_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../firebase_bloc_base.dart';
import 'user_state.dart';

class BaseUserBloc<UserType extends FirebaseProfile>
    extends BaseCubit<UserState> {
  final Duration emailVerificationDaysLimit = Duration(days: 7);
  final String userNotFoundError = "User not found";
  final String sendEmailError = 'Failed to send the email.';
  final bool isAnonymousUserEnabled = false;

  final BaseUserRepository<UserType> _userRepository;

  final BehaviorSubject<User?> _user = BehaviorSubject<User?>();
  final BehaviorSubject<UserType?> _userAccount = BehaviorSubject<UserType?>();

  Stream<User?> get userChanges => _user.shareValue();

  StreamSubscription<UserType?>? _detailsSubscription;
  StreamSubscription<User?>? _userSubscription;
  Stream<UserType?> get userStream => _userAccount.distinct().shareValue();
  UserType? get currentUser => _userAccount.valueOrNull;

  BaseUserBloc(this._userRepository) : super(UserLoadingState()) {
    _userSubscription = _userRepository.userChanges.listen((event) {
      _user.add(event);
      if (event == null) {
        if (isAnonymousUserEnabled) {
          emitLoading();
          anonymousSignIn();
        } else {
          emitSignedOut();
        }
      } else if (state is! SignedInState) {
        emitLoading();
        signInUser(event);
      }
    });
  }

  @override
  void onChange(change) {
    super.onChange(change);
    handleTransition(change.nextState);
  }

  void handleTransition(UserState state) {
    if (state is SignedOutState) {
      _userAccount.add(null);
      _detailsSubscription?.cancel();
    } else if (state is SignedInState<UserType>) {
      _userAccount.add(state.userAccount);
    }
  }

  UserType syncUserDetails(UserType account, User user) {
    account = account.copyWith(userDetails: user) as UserType;
    return account;
  }

  Future<Either<Failure, UserType>> signInUser(User user) async {
    final result = _userRepository.signInUser(user);
    final completer = userCompleter(result);
    return completer.future;
  }

  Future<Either<Failure, UserType>> autoSignIn() async {
    final result = _userRepository.autoSignIn();
    final completer = userCompleter(result);
    final futureResult = await completer.future;
    futureResult.fold((l) => emit(SignedOutState()), (UserType r) {});
    return futureResult;
  }

  Future<Either<Failure, UserType>> signIn(
      String email, String password) async {
    final result =
        await _userRepository.signInWithEmailAndPassword(email, password);
    final completer = userCompleter(result);
    return completer.future;
  }

  Future<Either<Failure, UserType>> anonymousSignIn() async {
    final result = await _userRepository.anonymousSignIn();
    final completer = userCompleter(result);
    return completer.future;
  }

  Future<Either<Failure, UserType>> signUp(String? firstName, String? lastName,
      String email, String password) async {
    final result = await _userRepository.signUpWithEmailAndPassword(
        firstName, lastName, email, password);
    final completer = userCompleter(result);
    return completer.future;
  }

  Future<Either<Failure, UserType>> updateUser(UserType newDetails,
      {String? phoneNumber,
      String? email,
      Future<String> Function()? getCode}) async {
    final result = await _userRepository.updateUserAccount(
        newDetails, phoneNumber, email, getCode);
    return result;
  }

  Future<Either<Failure, UserCredential>> addPhoneNumber(
      String phoneNumber, Future<String> Function() getCode) async {
    final result = await _userRepository.addPhoneNumber(phoneNumber, getCode);
    return result;
  }

  Future<Either<Failure, void>> resetPassword(String email) async {
    final result = await _userRepository.resetPassword(email);
    return result;
  }

  Future<ResponseEntity> signOut() async {
    final result = await _userRepository.signOut();
    if (result is Success) {
      emitSignedOut();
    }
    return result;
  }

  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      final operation = currentUser!.userDetails!.sendEmailVerification();
      final result = await operation;
      return Right(result);
    } catch (e, s) {
      return Left(Failure(sendEmailError));
    }
  }

  Completer<Either<Failure, T>> userCompleter<T extends UserType>(
      Either<Failure, Stream<T>> result) {
    Completer<Either<Failure, T>> completer = Completer();
    result.fold((l) {
      if (!completer.isCompleted) {
        completer.complete(Left(l));
      }
    }, (r) {
      _detailsSubscription?.cancel();
      _detailsSubscription = null;
      final newStream =
          r.withLatestFrom<User?, T>(userChanges, (userAccount, user) {
        if (user != null) {
          return syncUserDetails(userAccount, user) as T;
        }
        throw Exception();
      });
      _detailsSubscription = newStream.listen((event) {
        if (!completer.isCompleted) {
          completer.complete(Right(event));
        }
        _handleUser(event);
      }, onError: (e, s) async {
        print(e);
        print(s);
        if (!completer.isCompleted) {
          completer.complete(Left(Failure(userNotFoundError)));
        }
        final result = await signOut();
        if (result is! Success) {
          emitSignedOut();
        }
      });
    });
    return completer;
  }

  Future<void> _handleUser(UserType? event) async {
    if (event == null) {
      emitSignedOut();
    } else {
      emitSignedUser(event);
    }
  }

  void emitSignedUser(UserType userAccount) {
    final verificationLimit = userAccount.userDetails!.metadata.creationTime!
        .add(emailVerificationDaysLimit);
    final now = DateTime.now();
    if (userAccount.email != 'testing@test.com' &&
        !userAccount.emailVerified &&
        verificationLimit.isBefore(now)) {
      emit(SignedInWithNoVerifiedEmailState(userAccount));
    } else {
      if (userAccount.firstTime!) {
        emit(SignedUpState(userAccount));
      } else {
        emit(SignedInState(userAccount));
      }
    }
  }

  void emitLoading() {
    emit(UserLoadingState());
  }

  void emitSignedOut() {
    emit(SignedOutState());
  }

  void completeSignUp() {
    _handleUser(currentUser);
  }

  @override
  Future<void> close() {
    _detailsSubscription?.cancel();
    _userSubscription?.cancel();
    _userAccount.close();
    _user.close();
    return super.close();
  }
}
