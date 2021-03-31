import 'dart:async';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_bloc_base/src/data/repository/user_repository.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../firebase_bloc_base.dart';

abstract class FirebaseUserBloc<T extends FirebaseProfile>
    extends BaseUserBloc<T> {
  final UserRepository<T> userRepository;
  final _user = BehaviorSubject<User>();

  StreamSubscription _sub;
  StreamSubscription<T> _userSub;

  Stream<User> get userChanges => _user.shareValue();
  User get currentUserDetails => _user.value;
  bool get isNewUser => currentUser.isNewUser;

  FirebaseUserBloc(this.userRepository, UserDefaults userDefaults)
      : super(userDefaults) {
    _sub = userRepository.userChanges.listen((User event) {
      _user.add(event);
      if (event == null && state is BaseSignedInState) {
        emit(SignedOutState());
      }
    });
  }

  @override
  void onChange(change) {
    handleTransition(change.nextState);
    super.onChange(change);
  }

  void handleTransition(BaseUserState state) {
    if (state is SignedOutState) {
      userSink.add(null);
      _userSub?.cancel();
    } else if (state is BaseSignedInState) {
      if (state.userAccount != currentUser) {
        userSink.add(state.userAccount);
      }
    }
  }

  bool shouldProfileRefresh(state) => false;

  T syncUserDetails(T account, User user) {
    account = account.copyWith(userDetails: user);
    return account;
  }

  Future<Either<Failure, T>> autoSignIn([bool silent = true]) async {
    final Either<Failure, Stream<T>> result = await userRepository.autoSignIn();
    Completer<Either<Failure, T>> completer = handleUserStream(result);
    final futureResult = await completer.future;
    futureResult.leftMap((l) => emit(SignedOutState()));
    return futureResult;
  }

  Result<Either<Failure, T>> login(AuthParams params);

  Result<ResponseEntity> changePassword(String oldPassword, String password) {
    return Result(
        resultFuture: userRepository.changePassword(oldPassword, password));
  }

  Future<ResponseEntity> get signOutApi => userRepository.signOut();

  Future<ResponseEntity> signOut() {
    return signOutApi;
  }

  Result<ResponseEntity> offlineSignOut() {
    return Result(resultFuture: signOutApi);
  }

  Completer<Either<Failure, T>> handleUserStream(
      Either<Failure, Stream<T>> result) {
    Completer<Either<Failure, T>> completer = Completer();
    result.fold((l) {
      if (!completer.isCompleted) {
        completer.complete(Left(l));
      }
    }, (r) {
      _userSub?.cancel();
      _userSub = null;
      final newStream = CombineLatestStream.combine2<T, User, T>(r, userChanges,
          (userAccount, user) {
        if (userAccount != null && user != null) {
          return syncUserDetails(userAccount, user);
        }
        return null;
      });
      _userSub = newStream.listen((event) {
        if (!completer.isCompleted) {
          completer.complete(Right(event));
        }
        handleUser(event);
      }, onError: (e, s) {
        if (!completer.isCompleted) {
          String error = 'Error logging you in';
          dynamic err;
          if (e is Exception) {
            err = e;
            error = err.message;
          }
          completer.complete(Left(Failure(error)));
        }
        handleUser(null);
        signOut();
      });
    });
    return completer;
  }

  Future<void> handleUser(T user) async {
    if (user == null) {
      emit(SignedOutState());
    } else {
      emitSignedUser(user);
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _userSub?.cancel();
    _user.close();
    return super.close();
  }
}
