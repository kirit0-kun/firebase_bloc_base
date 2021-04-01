import 'package:api_bloc_base/api_bloc_base.dart' as api;

import 'base_listing_bloc.dart';

abstract class BaseUserAwareListingBloc<Output, Filtering extends FilterType>
    extends BaseListingBloc<Output, Filtering>
    with api.UserDependantMixin<Output> {
  final api.BaseUserBloc userBloc;

  BaseUserAwareListingBloc(this.userBloc,
      {List<Stream<api.ProviderState>> sources = const [], Output currentData})
      : super(currentData: currentData, sources: sources) {
    setUpUserListener();
  }
}
