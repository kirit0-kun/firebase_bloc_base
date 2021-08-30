import 'dart:async';

import 'package:firebase_bloc_base/firebase_bloc_base.dart';
import 'package:firebase_bloc_base/src/presentation/bloc/base_provider/lifecycle_observer.dart';
import 'package:firebase_bloc_base/src/presentation/bloc/user/user_bloc.dart';

import 'base_provider_bloc.dart';

abstract class BaseUserDependantProvider<Input, Output,
    UserType extends FirebaseProfile> extends BaseProviderBloc<Input, Output> {
  UserType? _lastUser;
  final BaseUserBloc<UserType> userBloc;

  UserType? get currentUser => userBloc.currentUser;
  UserType get requireUser => currentUser!;
  String? get userId => userBloc.currentUser?.id;
  String get requireUserId => userId!;

  StreamSubscription<UserType?>? userSubscription;

  BaseUserDependantProvider(this.userBloc, LifecycleObserver observer)
      : super(getOnCreate: false, observer: observer) {
    userSubscription = userBloc.userStream.distinct().listen(
      (user) {
        if (user != null) {
          if (_lastUser == null || !isSameUser(_lastUser!, user)) {
            _lastUser = user;
            if (userId != null) {
              getData();
            }
          }
        } else {
          _lastUser = null;
          stopListening();
        }
      },
    );
  }

  bool isSameUser(UserType oldUser, UserType newUser) =>
      oldUser.id == newUser.id;

  @override
  void onPause() {
    userSubscription?.pause();
    super.onPause();
  }

  @override
  void onResume() {
    userSubscription?.resume();
    super.onResume();
  }

  @override
  Future<void> close() {
    userSubscription?.cancel();
    return super.close();
  }
}
