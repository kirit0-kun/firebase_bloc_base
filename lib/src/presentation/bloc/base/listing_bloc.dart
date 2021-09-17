import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_bloc_base/src/domain/entity/grouped_item_header.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../firebase_bloc_base.dart';
import 'base_converter_bloc.dart';

abstract class ListingBundle<T> extends Equatable {
  final bool search;
  const ListingBundle(this.search);

  ListingBundle<T> withSearch(bool enabled);

  @override
  get props => [this.search];
}

class IndividualListingBundle<T> extends ListingBundle<T> {
  final List<T> items;

  ListingBundle<T> withSearch(bool enabled) =>
      IndividualListingBundle(items, enabled);

  const IndividualListingBundle(this.items, bool search) : super(search);

  @override
  get props => [...super.props, this.items];
}

class GroupedListingBundle<T> extends ListingBundle<T> {
  final List<GroupedItemHeader<T>> items;

  ListingBundle<T> withSearch(bool enabled) =>
      GroupedListingBundle(items, enabled);

  const GroupedListingBundle(this.items, bool search) : super(search);

  @override
  get props => [...super.props, this.items];
}

abstract class BaseListingBloc<EntityType, InputType, Filter, Grouping, Sorting>
    extends BaseConverterBloc<InputType, ListingBundle<EntityType>> {
  bool isSearch = false;

  Filter? get filter => _filterStream.valueOrNull;
  set filter(Filter? newFilter) {
    if (newFilter != filter) _filterStream.add(newFilter);
  }

  final _filterStream = BehaviorSubject<Filter?>()..add(null);

  Sorting? get sorting => _sortingStream.valueOrNull;
  set sorting(Sorting? newSorting) {
    if (newSorting != sorting) _sortingStream.add(newSorting);
  }

  final _sortingStream = BehaviorSubject<Sorting?>()..add(null);

  Grouping? get grouping => _groupingStream.valueOrNull;
  set grouping(Grouping? newGrouping) {
    if (newGrouping != grouping) _groupingStream.add(newGrouping);
  }

  final _groupingStream = BehaviorSubject<Grouping?>()..add(null);

  Stream<BaseProviderState<InputType>> get source =>
      CombineLatestStream.combine4<BaseProviderState<InputType>, Filter?,
              Grouping?, Sorting?, BaseProviderState<InputType>>(super.source!,
          _filterStream, _groupingStream, _sortingStream, (a, b, c, d) => a);

  BaseListingBloc({
    BaseProviderBloc<dynamic, InputType>? sourceBloc,
    Sorting? initialSorting,
  }) : super(sourceBloc: sourceBloc) {
    sorting = initialSorting;
  }

  @override
  Future<ListingBundle<EntityType>> convert(InputType? input) {
    final values = sourceBloc!.latestData!;
    return filtered(values, filter, grouping, sorting);
  }

  Future<ListingBundle<EntityType>> filtered(
    InputType input,
    Filter? filter,
    Grouping? grouping,
    Sorting? sorting,
  );

  void search() {
    if (state is LoadedState) {
      isSearch = true;
      currentData = currentData.withSearch(isSearch);
      emitLoaded();
    }
  }

  void closeSearch() {
    if (state is LoadedState) {
      filter = null;
      isSearch = false;
      currentData = currentData.withSearch(isSearch);
      emitLoaded();
    }
  }

  // ignore: invalid_override_different_default_values_named
  bool onCancel({String? operationTag}) => false;

  @override
  Future<void> close() {
    _filterStream.drain().then((value) => _filterStream.close());
    _sortingStream.drain().then((value) => _sortingStream.close());
    _groupingStream.drain().then((value) => _groupingStream.close());
    return super.close();
  }
}
