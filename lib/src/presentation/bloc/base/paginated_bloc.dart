import 'dart:async';

import '../../../../firebase_bloc_base.dart';

export 'working_state.dart';

abstract class PaginatedConverterBloc<Input, Output>
    extends BaseConverterBloc<Input, Output> with PaginatedMixin<Output> {
  PaginatedConverterBloc(
      {Output currentData,
      BaseProviderBloc<dynamic, Input> sourceBloc,
      bool getOnCreate = true})
      : super(
            currentData: currentData,
            sourceBloc: sourceBloc,
            getOnCreate: getOnCreate);

  @override
  Future<void> close() {
    return super.close();
  }
}
