import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../../firebase_bloc_base.dart';
import '../base_provider/provider_state.dart' as provider;

export 'working_state.dart';

abstract class FilterType {}

abstract class BaseListingBloc<Output, Filtering extends FilterType>
    extends BaseIndependentBloc<Output> {
  final int searchDelayMillis;

  get finalDataStream =>
      CombineLatestStream.combine3<Output, Filtering, String, Output>(
              super.finalDataStream, _filterSubject, _queryStream, applyFilter)
          .asBroadcastStream();

  BaseListingBloc(
      {this.searchDelayMillis = 1000,
      List<Stream<provider.ProviderState>> sources = const [],
      Output currentData})
      : super(sources: sources, currentData: currentData);

  Output applyFilter(Output output, Filtering filter, String query) {
    return output;
  }

  final _filterSubject = BehaviorSubject<Filtering>()..value = null;
  Filtering get filter => _filterSubject.value;
  set filter(Filtering filter) {
    _filterSubject.add(filter);
  }

  final _querySubject = BehaviorSubject<String>()..value = '';
  Stream<String> get _queryStream => _querySubject
      .shareValue()
      .debounceTime(Duration(milliseconds: searchDelayMillis));
  String get query => _querySubject.value;
  set query(String query) {
    _querySubject.add(query);
  }

  @override
  Future<void> close() {
    _filterSubject.close();
    _querySubject.close();
    return super.close();
  }
}
