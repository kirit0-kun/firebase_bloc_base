import 'dart:async';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:dartz/dartz.dart';

export 'working_state.dart';

abstract class FirebaseIndependentBloc<Output>
    extends BaseIndependentBloc<Output> {
  FirebaseIndependentBloc(
      {List<Stream<ProviderState>> sources = const [], Output currentData})
      : super(currentData: currentData, sources: sources);

  Output combineData(Output data) => data;

  void handleData(Output event) {
    final newData = event;
    super.handleData(newData);
  }

  Result<Either<ResponseEntity, Output>> get dataSource;

  void getData() {
    super.getData();
    final data = dataSource;
    handleDataRequest(data);
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
