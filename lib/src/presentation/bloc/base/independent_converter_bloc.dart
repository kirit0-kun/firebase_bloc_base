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
  IndependentConverterBloc(
      {Output currentData, BaseProviderBloc<dynamic, Input> sourceBloc})
      : super(currentData: currentData, sourceBloc: sourceBloc);
}
