import 'dart:async';

import '../../../../firebase_bloc_base.dart';

export 'working_state.dart';

abstract class PaginatedConverterBloc<Input, Output>
    extends BaseConverterBloc<Input, Output> with PaginatedMixin<Output> {
  StreamSubscription _subscription;
  final bool getDataWhenSourceChange;

  PaginatedConverterBloc(
      {Output currentData,
      this.getDataWhenSourceChange = false,
      BaseProviderBloc<dynamic, Input> sourceBloc})
      : super(currentData: currentData, sourceBloc: sourceBloc) {
    if (getDataWhenSourceChange) {
      _subscription = sourceBloc?.dataStream?.distinct()?.listen((event) {
        getData();
      });
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
