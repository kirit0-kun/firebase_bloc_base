import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'base_firebase_query.dart';

class QueryParamCombo<T> extends Equatable {
  final Query<T> query;
  final PaginatedParam? param;

  const QueryParamCombo(this.query, this.param);

  @override
  get props => [this.query, this.param];
}

class Page<T> extends Equatable {
  final List<PaginatedResult<T>> chunks;

  const Page(this.chunks);

  @override
  get props => [this.chunks];
}

class PaginatedParam extends Equatable {
  final DocumentSnapshot? startAfter;
  final int? count;

  const PaginatedParam({this.startAfter, this.count});

  @override
  get props => [this.startAfter, this.count];

  PaginatedParam copyWith({DocumentSnapshot? startAfter, int? count}) =>
      PaginatedParam(
          startAfter: startAfter ?? this.startAfter,
          count: count ?? this.count);
}

class PaginatedWhereParam extends PaginatedParam {
  final List<dynamic> values;

  const PaginatedWhereParam(this.values,
      {DocumentSnapshot? startAfter, int? count})
      : super(startAfter: startAfter, count: count);

  @override
  get props => [this.values, this.startAfter, this.count];

  PaginatedWhereParam copyWith(
          {List<dynamic>? values, DocumentSnapshot? startAfter, int? count}) =>
      PaginatedWhereParam(values ?? this.values,
          startAfter: startAfter ?? this.startAfter,
          count: count ?? this.count);
}

class PaginatedResult<T> extends PaginatedParam {
  final List<T> result;
  final PaginatedParam? param;

  DocumentSnapshot? get startAfter => super.startAfter ?? param?.startAfter;
  int get count => result.length;

  const PaginatedResult(this.result, this.param, [DocumentSnapshot? startAfter])
      : super(startAfter: startAfter);

  factory PaginatedResult.fromParams(List<T> result, PaginatedParam? param,
      [DocumentSnapshot? startAfter]) {
    return PaginatedResult<T>(result, param, startAfter);
  }

  @override
  get props => [
        ...super.props,
        this.result,
      ];

  PaginatedResult copyWith(
      {List? result, DocumentSnapshot? startAfter, int? count}) {
    var param = startAfter != null || count != null
        ? (this.param ?? PaginatedParam())
            .copyWith(startAfter: startAfter, count: count)
        : null;
    return PaginatedResult(result ?? this.result, param);
  }
}

class PaginatedFirebaseQuerySwitcher<T> extends BaseFirebaseQuerySwitcher {
  static const l = 10;

  const PaginatedFirebaseQuerySwitcher({
    this.paginatedParam,
    Map<String, dynamic>? isEqualTo,
    Map<String, dynamic>? isNotEqualTo,
    Map<String, dynamic>? isLessThan,
    Map<String, dynamic>? isLessThanOrEqualTo,
    Map<String, dynamic>? isGreaterThan,
    Map<String, dynamic>? isGreaterThanOrEqualTo,
    Map<String, dynamic>? arrayContains,
    List<MapEntry<String, bool>>? orderBy,
    List<MapEntry<String, bool>>? isNull,
    this.arrayContainsAny,
    this.whereIn,
  }) : super(
          isEqualTo: isEqualTo,
          isNotEqualTo: isNotEqualTo,
          isLessThan: isLessThan,
          isLessThanOrEqualTo: isLessThanOrEqualTo,
          isGreaterThan: isGreaterThan,
          isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
          arrayContains: arrayContains,
          orderBy: orderBy,
          isNull: isNull,
        );

  final PaginatedParam? paginatedParam;
  final List<MapEntry<String, PaginatedWhereParam>>? arrayContainsAny;
  final List<MapEntry<String, PaginatedWhereParam>>? whereIn;

  List<QueryParamCombo<T>>? paginate<T>(Query<T> initial,
      {bool? arrayContainsAny, bool? whereIn}) {
    Query<T> finalQuery = super.applyToQuery(initial);
    List<QueryParamCombo<T>>? newQueries;
    if (arrayContainsAny == true && this.arrayContainsAny != null) {
      newQueries = this.arrayContainsAny!.map((item) {
        final key = item.key;
        final entry = item.value;
        var newQuery = finalQuery.where(key, arrayContainsAny: entry.values);
        if (entry.startAfter != null) {
          newQuery = newQuery.startAfterDocument(entry.startAfter!);
        }
        if (entry.count != null) {
          newQuery = newQuery.limit(entry.count!);
        }
        return QueryParamCombo<T>(newQuery, entry);
      }).toList();
    } else if (whereIn == true && this.whereIn != null) {
      newQueries = this.whereIn!.map((item) {
        final key = item.key;
        final entry = item.value;
        var newQuery = finalQuery.where(key, whereIn: entry.values);
        if (entry.startAfter != null) {
          newQuery = newQuery.startAfterDocument(entry.startAfter!);
        }
        if (entry.count != null) {
          newQuery = newQuery.limit(entry.count!);
        }
        return QueryParamCombo<T>(newQuery, entry);
      }).toList();
    } else if (this.paginatedParam != null) {
      if (this.paginatedParam!.count != null) {
        finalQuery = finalQuery.limit(this.paginatedParam!.count!);
      }
      if (this.paginatedParam!.startAfter != null) {
        finalQuery =
            finalQuery.startAfterDocument(this.paginatedParam!.startAfter!);
      }
      newQueries = [QueryParamCombo<T>(finalQuery, this.paginatedParam)];
    }
    return newQueries;
  }

  Future<Page<T>> paginatedFutureTransform<S, T>(
      Query<S> initial, FutureOr<T> Function(S)? transform,
      {bool? arrayContainsAny, bool? whereIn}) {
    if (transform == null && S == T) {
      transform = (s) => s as T;
    }
    return paginateFuture(initial,
            arrayContainsAny: arrayContainsAny, whereIn: whereIn)
        .then((value) async {
      final chunksFuture = value.chunks.map((chunk) async {
        final futures =
            chunk.result.map((data) async => await transform!(data));
        final newResult = await Future.wait(futures);
        return PaginatedResult.fromParams(
            newResult, chunk.param, chunk.startAfter);
      });
      return Page(await Future.wait(chunksFuture));
    });
  }

  Future<Page<T>> paginateFuture<T>(Query<T> initial,
      {bool? arrayContainsAny, bool? whereIn}) {
    final futures = paginate<T>(initial,
            whereIn: whereIn, arrayContainsAny: arrayContainsAny)!
        .map((combo) => combo.query.get().then((value) =>
            PaginatedResult.fromParams(value.objects, combo.param,
                value.docs.isEmpty ? null : value.docs.last)));
    return Future.wait(futures).then((value) {
      final list = value.toList();
      return Page(list);
    });
  }
}
