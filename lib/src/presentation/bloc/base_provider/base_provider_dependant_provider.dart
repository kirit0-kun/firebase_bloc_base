import 'dart:async';

import 'package:firebase_bloc_base/firebase_bloc_base.dart';
import 'package:firebase_bloc_base/src/presentation/bloc/base_provider/lifecycle_observer.dart';

import 'base_provider_bloc.dart';

abstract class BaseDependantProvider<Input, Output>
    extends BaseProviderBloc<Input, Output> {
  final Stream source;
  StreamSubscription _subscription;

  BaseDependantProvider(this.source, LifecycleObserver observer)
      : super(getOnCreate: false, observer: observer) {
    _subscription = source?.distinct()?.listen((event) {
      getData();
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
