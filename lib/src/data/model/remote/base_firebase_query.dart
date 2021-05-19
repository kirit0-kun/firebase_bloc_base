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

  final int limit;
  final Map<String, dynamic> isEqualTo;
  final Map<String, dynamic> isNotEqualTo;
  final Map<String, dynamic> isLessThan;
  final Map<String, dynamic> isLessThanOrEqualTo;
  final Map<String, dynamic> isGreaterThan;
  final Map<String, dynamic> isGreaterThanOrEqualTo;
  final Map<String, dynamic> arrayContains;
  final List<MapEntry<String, bool>> orderBy;
  final List<MapEntry<String, bool>> isNull;

  Query applyToQuery(Query initial) {
    Query finalQuery = initial;
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
      finalQuery = finalQuery.limit(limit);
    }
    return finalQuery;
  }

  Future<List<T>> future<T>(Query initial,
      FutureOr<T> Function(Map<String, dynamic>) transform) async {
    final future =
        await applyToQuery(initial).get().then((value) => value?.docs);
    if (future?.isNotEmpty == true) {
      final futures = future.map((item) async => await transform(item.data()));
      return await Future.wait(futures);
    } else {
      return [];
    }
  }

  Stream<List<T>> stream<T>(
      Query initial, FutureOr<T> Function(Map<String, dynamic>) transform) {
    return applyToQuery(initial)
        .snapshots()
        .map((value) => value?.docs)
        .asyncMap((event) async {
      if (event?.isNotEmpty == true) {
        final futures = event.map((item) async => await transform(item.data()));
        return await Future.wait(futures);
      } else {
        return [];
      }
    });
  }
}
