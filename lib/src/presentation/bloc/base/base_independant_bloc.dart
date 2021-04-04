import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_bloc_base/src/domain/entity/response_entity.dart';

import '../../../../firebase_bloc_base.dart';
import 'base_converter_bloc.dart';

export 'working_state.dart';

abstract class BaseIndependentBloc<Input, Output>
    extends MultiConverterBloc<Input, Output> {
  StreamSubscription _sub;

  List<Stream<BaseProviderState>> _sources;

  @override
  get sources {
    if (_sources?.isEmpty == true) {
      return [_ownDataStateSubject.stream, ..._sources];
    } else {
      return [_ownDataStateSubject.stream];
    }
  }

  Future<Either<ResponseEntity, Input>> get result;

  BaseIndependentBloc({List<Stream<BaseProviderState>> sources = const []})
      : _sources = sources,
        super() {
    getData();
  }

  final _ownDataStateSubject = StreamController<BaseProviderState<Input>>();
  Stream<BaseProviderState<Input>> get originalDataStream =>
      _ownDataStateSubject.stream;

  Future<void> handleDataRequest(
      Future<Either<ResponseEntity, Input>> result) async {
    _ownDataStateSubject.add(BaseLoadingState<Input>());
    final future = await result;
    final event = future.fold<BaseProviderState<Input>>(
      (l) {
        return BaseErrorState(l.message);
      },
      (r) {
        return BaseLoadedState(r);
      },
    );
    if (!_ownDataStateSubject.isClosed) {
      _ownDataStateSubject.add(event);
    }
  }

  void getData() {
    final result = this.result;
    if (result != null) {
      handleDataRequest(result);
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _ownDataStateSubject?.close();
    return super.close();
  }
}
