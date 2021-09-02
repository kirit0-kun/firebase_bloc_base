import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class BaseFirebaseQuerySwitcher {
  const BaseFirebaseQuerySwitcher({
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.orderBy,
    this.isNull,
    this.limit,
  });

  final int? limit;
  final Map<String, dynamic>? isEqualTo;
  final Map<String, dynamic>? isNotEqualTo;
  final Map<String, dynamic>? isLessThan;
  final Map<String, dynamic>? isLessThanOrEqualTo;
  final Map<String, dynamic>? isGreaterThan;
  final Map<String, dynamic>? isGreaterThanOrEqualTo;
  final Map<String, dynamic>? arrayContains;
  final List<MapEntry<String, bool>>? orderBy;
  final List<MapEntry<String, bool>>? isNull;

  Query<T> applyToQuery<T>(Query<T> initial) {
    Query<T> finalQuery = initial;
    isEqualTo?.forEach((key, value) {
      finalQuery = finalQuery.where(key, isEqualTo: value);
    });
    isNotEqualTo?.forEach((key, value) {
      finalQuery = finalQuery.where(key, isNotEqualTo: value);
    });
    isLessThan?.forEach((key, value) {
      finalQuery = finalQuery.where(key, isLessThan: value);
    });
    isLessThanOrEqualTo?.forEach((key, value) {
      finalQuery = finalQuery.where(key, isLessThanOrEqualTo: value);
    });
    isGreaterThan?.forEach((key, value) {
      finalQuery = finalQuery.where(key, isGreaterThan: value);
    });
    isGreaterThanOrEqualTo?.forEach((key, value) {
      finalQuery = finalQuery.where(key, isGreaterThanOrEqualTo: value);
    });
    arrayContains?.forEach((key, value) {
      finalQuery = finalQuery.where(key, arrayContains: value);
    });
    isNull?.forEach((item) {
      finalQuery = finalQuery.where(item.key, isNull: item.value);
    });
    orderBy?.forEach((element) {
      final key = element.key;
      final descending = element.value;
      finalQuery = finalQuery.orderBy(key, descending: descending);
    });
    if (limit != null) {
      finalQuery = finalQuery.limit(limit!);
    }
    return finalQuery;
  }

  Future<List<T>> future<S, T>(
      Query<S> initial, FutureOr<T> Function(S)? transform,
      [GetOptions? getOptions]) async {
    if (transform == null && S == T) {
      transform = (s) async => s as T;
    }
    final future = await applyToQuery(initial)
        .get(getOptions)
        .then((value) => value.objects);
    final futures = future.map((item) async => await transform!(item));
    return await Future.wait(futures);
  }

  Stream<List<T>> stream<S, T>(
      Query<S> initial, FutureOr<T> Function(S)? transform) {
    if (transform == null && S == T) {
      transform = (s) async => s as T;
    }
    return applyToQuery(initial)
        .snapshots()
        .map((value) => value.objects)
        .asyncMap((event) async {
      final futures = event.map((item) async => await transform!(item));
      return await Future.wait(futures);
    });
  }
}

T? getDataIfNotNull<T>(DocumentSnapshot<Map<String, dynamic>> document,
    T Function(Map<String, dynamic>) fromJson) {
  final data = document.data();
  if (document.exists && data != null) {
    return fromJson(data);
  } else {
    return null;
  }
}

extension EntityQueryFirestore<T> on QuerySnapshot<T?> {
  List<T> get objects {
    return this.docs.map((e) => e.data()).whereType<T>().toList();
  }
}
