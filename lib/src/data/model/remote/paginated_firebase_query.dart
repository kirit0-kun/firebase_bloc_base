import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'base_firebase_query.dart';

class QueryParamCombo extends Equatable {
  final Query query;
  final PaginatedParam param;

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
  final List<dynamic> values;
  final DocumentSnapshot startAfter;
  final int count;

  const PaginatedParam(this.values, {this.startAfter, this.count});

  @override
  get props => [this.values, this.startAfter, this.count];

  PaginatedParam copyWith(
          {List<dynamic> values, DocumentSnapshot startAfter, int count}) =>
      PaginatedParam(values ?? this.values,
          startAfter: startAfter ?? this.startAfter,
          count: count ?? this.count);
}

class PaginatedResult<T> extends PaginatedParam {
  final List<T> result;

  const PaginatedResult(this.result, List values,
      {DocumentSnapshot startAfter, int count})
      : super(values, startAfter: startAfter, count: count);

  factory PaginatedResult.fromParams(List<T> result, PaginatedParam param,
      [DocumentSnapshot startAfter]) {
    return PaginatedResult(result, param.values,
        startAfter: startAfter ?? param.startAfter, count: result.length);
  }

  @override
  get props => [
        ...super.props,
        this.result,
      ];

  PaginatedResult copyWith(
          {List<T> result,
          List<dynamic> values,
          DocumentSnapshot startAfter,
          int count}) =>
      PaginatedResult<T>(result ?? this.result, values ?? this.values,
          startAfter: startAfter ?? this.startAfter,
          count: count ?? this.count);
}

class PaginatedFirebaseQuerySwitcher extends BaseFirebaseQuerySwitcher {
  static const l = 10;

  const PaginatedFirebaseQuerySwitcher({
    int limit,
    Map<String, dynamic> isEqualTo,
    Map<String, dynamic> isNotEqualTo,
    Map<String, dynamic> isLessThan,
    Map<String, dynamic> isLessThanOrEqualTo,
    Map<String, dynamic> isGreaterThan,
    Map<String, dynamic> isGreaterThanOrEqualTo,
    Map<String, dynamic> arrayContains,
    List<MapEntry<String, bool>> orderBy,
    Map<String, bool> isNull,
    this.arrayContainsAny,
    this.whereIn,
  }) : super(
          limit: limit,
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

  final Map<String, PaginatedParam> arrayContainsAny;
  final Map<String, PaginatedParam> whereIn;

  List<QueryParamCombo> paginate(Query initial,
      {bool arrayContainsAny, bool whereIn}) {
    Query finalQuery = super.applyToQuery(initial);
    List<QueryParamCombo> newQueries;
    if (arrayContainsAny == true && this.arrayContainsAny != null) {
      newQueries = this.arrayContainsAny.entries.map((item) {
        final key = item.key;
        final entry = item.value;
        var newQuery = finalQuery.where(key, arrayContainsAny: entry.values);
        if (entry.startAfter != null) {
          newQuery = newQuery.startAfterDocument(entry.startAfter);
        }
        if (entry.count != null) {
          newQuery = newQuery.limit(entry.count);
        }
        return QueryParamCombo(newQuery, entry);
      }).toList();
    }
    if (whereIn == true && this.whereIn != null) {
      newQueries = this.whereIn.entries.map((item) {
        final key = item.key;
        final entry = item.value;
        var newQuery = finalQuery.where(key, whereIn: entry.values);
        if (entry.startAfter != null) {
          newQuery = newQuery.startAfterDocument(entry.startAfter);
        }
        if (entry.count != null) {
          newQuery = newQuery.limit(entry.count);
        }
        return QueryParamCombo(newQuery, entry);
      }).toList();
    }
    return newQueries;
  }

  Future<Page<T>> moreThan10FutureTransform<T>(
      Query initial, FutureOr<T> Function(Map<String, dynamic>) transform,
      {bool arrayContainsAny, bool whereIn}) {
    return moreThan10Future(initial,
            arrayContainsAny: arrayContainsAny, whereIn: whereIn)
        .then((value) async {
      final chunksFuture = value.chunks.map((chunk) async {
        final futures =
            chunk.result.map((data) async => await transform(data.data()));
        final newResult = await Future.wait(futures);
        return PaginatedResult.fromParams(newResult, chunk);
      });
      return Page(await Future.wait(chunksFuture));
    });
  }

  Future<Page<QueryDocumentSnapshot>> moreThan10Future(Query initial,
      {bool arrayContainsAny, bool whereIn}) {
    final futures =
        paginate(initial, whereIn: whereIn, arrayContainsAny: arrayContainsAny)
            .map((combo) => combo.query.get().then((value) =>
                PaginatedResult.fromParams(
                    value.docs, combo.param, value.docs.last)));
    return Future.wait(futures).then((value) {
      final list = value.where((element) => element != null).toList();
      return Page(list);
    });
  }
}
