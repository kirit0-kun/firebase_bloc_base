import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

abstract class BaseCubit<State> extends Cubit<State> {
  String get anUnexpectedErrorOccurred => 'An unexpected error occurred';

  BaseCubit(State initialState) : super(initialState);

  Stream<State> get exclusiveStream => super.stream;

  @override
  get stream => super.stream.shareValueSeeded(state).map((e) => state);
  // get stream => super.stream.shareValueSeeded(state);

  String getExceptionMessage(dynamic e) {
    try {
      return e.message;
    } catch (_) {
      return anUnexpectedErrorOccurred;
    }
  }
}
