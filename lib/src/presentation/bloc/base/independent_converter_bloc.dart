import 'dart:async';

import 'package:firebase_bloc_base/src/presentation/bloc/base/independent_converter_mixin.dart';

import '../../../../firebase_bloc_base.dart';

export 'working_state.dart';

abstract class IndependentMultiConverterBloc<Input, Output>
    extends MultiConverterBloc<Input, Output>
    with IndependentMultiConverterMixin<Input, Output> {
  IndependentMultiConverterBloc({Output currentData})
      : super(currentData: currentData);
}

abstract class IndependentConverterBloc<Input, Output>
    extends BaseConverterBloc<Input, Output>
    with IndependentConverterMixin<Input, Output> {
  StreamSubscription _subscription;
  final bool getDataWhenSourceChange;

  IndependentConverterBloc(
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
