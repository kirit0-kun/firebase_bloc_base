import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import 'base_firebase_query.dart';

class FirebaseQuerySwitcher extends BaseFirebaseQuerySwitcher {
  static const l = 10;

  const FirebaseQuerySwitcher({
    int? limit,
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
    this.whereNotIn,
    this.startAfter,
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

  final Map<String, List<dynamic>>? arrayContainsAny;
  final Map<String, List<dynamic>>? whereIn;
  final Map<String, List<dynamic>>? whereNotIn;
  final DocumentSnapshot? startAfter;

  Query<T> applyToQuery<T>(Query<T> initial) {
    Query<T> finalQuery = super.applyToQuery(initial);
    arrayContainsAny?.forEach((key, value) {
      finalQuery = finalQuery.where(key, arrayContainsAny: value);
    });
    whereIn?.forEach((key, value) {
      finalQuery = finalQuery.where(key, whereIn: value);
    });
    whereNotIn?.forEach((key, value) {
      finalQuery = finalQuery.where(key, whereNotIn: value);
    });
    if (startAfter != null) {
      finalQuery = finalQuery.startAfterDocument(startAfter!);
    }
    return finalQuery;
  }

  List<Query<T>> moreThan10<T>(Query<T> initial,
      {bool? arrayContainsAny, bool? whereIn}) {
    Query<T> finalQuery = super.applyToQuery(initial);
    if (startAfter != null) {
      finalQuery = finalQuery.startAfterDocument(startAfter!);
    }
    whereNotIn?.forEach((key, value) {
      finalQuery = finalQuery.where(key, whereNotIn: value);
    });
    if (arrayContainsAny != true) {
      this.arrayContainsAny?.forEach((key, value) {
        finalQuery = finalQuery.where(key, arrayContainsAny: value);
      });
    }
    if (whereIn != true) {
      this.whereIn?.forEach((key, value) {
        finalQuery = finalQuery.where(key, whereIn: value);
      });
    }
    whereNotIn?.forEach((key, value) {
      finalQuery = finalQuery.where(key, whereNotIn: value);
    });
    List<Query<T>>? newQueries;
    if (arrayContainsAny == true && this.arrayContainsAny != null) {
      newQueries = this
          .arrayContainsAny!
          .entries
          .map((entry) {
            return _split(entry.value)
                .map((miniList) =>
                    finalQuery.where(entry.key, arrayContainsAny: miniList))
                .toList();
          })
          .expand((element) => element)
          .toList();
    }
    if (whereIn == true && this.whereIn != null) {
      newQueries = this
          .whereIn!
          .entries
          .map((entry) {
            return _split(entry.value)
                .map((miniList) =>
                    finalQuery.where(entry.key, whereIn: miniList))
                .toList();
          })
          .expand((element) => element)
          .toList();
    }
    return newQueries ?? [finalQuery];
  }

  Future<List<QueryDocumentSnapshot<T>>> moreThan10Future<T>(Query<T> initial,
      {bool? arrayContainsAny, bool? whereIn}) {
    final futures = moreThan10(initial,
            whereIn: whereIn, arrayContainsAny: arrayContainsAny)
        .map((query) => query.get().then((value) => value.docs));
    return Future.wait(futures).then((value) {
      final entries = value
          .expand((element) => element)
          .where((element) => element.exists)
          .toList();
      final emitted = <String>{};
      final toEmit = <QueryDocumentSnapshot<T>>[];
      entries.forEach((element) {
        final path = element.reference.path;
        if (!emitted.contains(path)) {
          toEmit.add(element);
          emitted.add(path);
        }
      });
      return toEmit;
    });
  }

  Stream<List<QueryDocumentSnapshot<T>>> moreThan10Stream<T>(Query<T> initial,
      {bool? arrayContainsAny, bool? whereIn}) {
    final futures = moreThan10(initial,
            whereIn: whereIn, arrayContainsAny: arrayContainsAny)
        .map((query) =>
            query.snapshots().map((value) => value.docs).defaultIfEmpty([]))
        .toList();
    return CombineLatestStream<List<QueryDocumentSnapshot<T>>,
        List<QueryDocumentSnapshot<T>>>(futures, (streams) {
      final entries = streams
          .expand((element) => element)
          .where((element) => element.exists)
          .toList();
      final emitted = <String>{};
      final toEmit = <QueryDocumentSnapshot<T>>[];
      entries.forEach((element) {
        final path = element.reference.path;
        if (!emitted.contains(path)) {
          toEmit.add(element);
          emitted.add(path);
        }
      });
      return toEmit;
    });
  }

  Future<List<T>> moreThan10FutureTransform<S, T>(
      Query<S> initial, FutureOr<T> Function(S)? transform,
      {bool? arrayContainsAny, bool? whereIn}) {
    if (transform == null && S == T) {
      transform = (s) => s as T;
    }
    return moreThan10Future<S>(initial,
            arrayContainsAny: arrayContainsAny, whereIn: whereIn)
        .then((value) async {
      final futures = value.map((data) async => await transform!(data.data()));
      return await Future.wait(futures);
    });
  }

  Stream<List<T>> moreThan10StreamTransform<S, T>(
      Query<S> initial, FutureOr<T> Function(S)? transform,
      {bool? arrayContainsAny, bool? whereIn}) {
    if (transform == null && S == T) {
      transform = (s) => s as T;
    }
    return moreThan10Stream<S>(initial,
            arrayContainsAny: arrayContainsAny, whereIn: whereIn)
        .asyncMap((list) async {
      final futures = list.map((data) async => await transform!(data.data()));
      return await Future.wait(futures);
    });
  }

  static List<List> _split(List list) {
    if (list.length <= l) {
      return [list];
    }
    final List<List> result = [];
    final rounds = (list.length / l).ceil();
    for (int i = 0; i < rounds; i++) {
      final newList = list.skip(l * i).take(l).toList();
      result.add(newList);
    }
    return result;
  }
}
