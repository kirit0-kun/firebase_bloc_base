import 'dart:async';
import 'dart:math';

import 'package:async/async.dart' as async;
import 'package:equatable/equatable.dart';
import 'package:firebase_bloc_base/firebase_bloc_base.dart';

import 'paginated_state.dart';

class PaginatedData<T> extends Equatable {
  final Map<int, T> data;
  final bool? isThereMore;
  final int currentPage;

  const PaginatedData(this.data, this.isThereMore, this.currentPage);

  @override
  get props => [this.data, this.isThereMore, this.currentPage];
}

mixin PaginatedMixin<Output> on BaseWorkingBloc<Output> {
  int get startPage => 1;

  int? _currentPage;

  int get currentPage => _currentPage ?? startPage;
  int get lastPage =>
      paginatedData?.data.keys
          .fold(0, (previousValue, element) => max(previousValue!, element)) ??
      2;

  bool get canGoBack => currentPage > startPage;
  bool get canGoForward => currentPage < lastPage || isThereMore;
  bool get isThereMore => paginatedData?.isThereMore ?? true;

  set currentPage(int? newPage) {
    _currentPage = newPage;
  }

  PaginatedData<Output>? paginatedData;

  Stream<PaginatedData<Output>?> get paginatedStream => async.LazyStream(
      () => stateStream.map((event) => paginatedData).distinct());

  @override
  void setData(Output newData) {
    final map = paginatedData?.data ?? <int, Output>{};
    final newMap = Map.of(map);
    final isThereMore =
        currentPage > newMap.length ? canGetMore(newData) : this.isThereMore;
    newMap[currentPage] = newData;
    paginatedData = PaginatedData(newMap, isThereMore, currentPage);
    super.setData(selectData(paginatedData!));
  }

  Output selectData(PaginatedData<Output> data) {
    return data.data[data.currentPage]!;
  }

  void getData();

  bool? canGetMore(Output newData) {
    if (newData == null) {
      return false;
    } else if (newData is Iterable) {
      return newData.isNotEmpty;
    } else if (newData is Map) {
      return newData.isNotEmpty;
    } else {
      try {
        dynamic d = newData;
        return d.count > 0;
      } catch (e) {
        return false;
      }
    }
  }

  void next() async {
    if (canGoForward) {
      currentPage++;
      final nextData = paginatedData?.data[currentPage];
      if (nextData != null) {
        setData(nextData);
      }
      return getData();
    }
  }

  void back() async {
    if (canGoBack) {
      currentPage--;
      final previousData = paginatedData!.data[currentPage]!;
      setData(previousData);
    }
  }

  @override
  void clean() {
    super.clean();
    _currentPage = startPage;
    paginatedData = null;
  }

  @override
  void emitError(String message) {
    if (currentPage != startPage) {
      currentPage--;
    } else {
      currentPage = null;
    }
    if (!wasInitialized || safeData == null) {
      super.emitError(message);
    } else {
      emit(ErrorGettingNextPageState<Output>(currentData, message));
    }
  }

  @override
  void emitLoading() {
    if (!wasInitialized || safeData == null) {
      super.emitLoading();
    } else {
      emit(LoadingNextPageState<Output>(currentData));
    }
  }

  @override
  void emitLoaded() {
    emit(PaginatedLoadedState(paginatedData, currentData));
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
