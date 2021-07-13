import 'dart:async';

import 'package:firebase_bloc_base/firebase_bloc_base.dart';
import 'package:firebase_bloc_base/src/presentation/bloc/base_provider/lifecycle_observer.dart';
import 'package:firebase_bloc_base/src/presentation/bloc/user/user_bloc.dart';

import 'base_provider_bloc.dart';

abstract class BaseUserDependantProvider<Input, Output>
    extends BaseProviderBloc<Input, Output> {
  String? _lastUserId;
  final BaseUserBloc userBloc;

  FirebaseProfile? get currentUser => userBloc.currentUser;
  String? get userId => userBloc.currentUser?.id;

  StreamSubscription<FirebaseProfile>? userSubscription;

  BaseUserDependantProvider(this.userBloc, LifecycleObserver observer)
      : super(getOnCreate: false, observer: observer) {
    userSubscription = userBloc.userStream.listen(
      (user) {
        if (user != null) {
          if (_lastUserId != user?.id) {
            _lastUserId = user?.id;
            if (userId != null) {
              getData();
            }
          }
        } else {
          _lastUserId = null;
          stopListening();
        }
      },
    );
  }

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
