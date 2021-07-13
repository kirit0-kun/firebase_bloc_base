import 'package:firebase_bloc_base/src/presentation/bloc/base/independent_mixin.dart';

import '../../../../firebase_bloc_base.dart';

export 'working_state.dart';

abstract class IndependentConverterBloc<Input, Output>
    extends BaseConverterBloc<Input, Output>
    with IndependentMixin<Input, Output> {
  IndependentConverterBloc({
    Output? currentData,
    bool getOnCreate = true,
  }) : super(currentData: currentData, getOnCreate: getOnCreate);
}
