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
  final List<MapEntry<String, dynamic>> isEqualTo;
  final List<MapEntry<String, dynamic>> isNotEqualTo;
  final List<MapEntry<String, dynamic>> isLessThan;
  final List<MapEntry<String, dynamic>> isLessThanOrEqualTo;
  final List<MapEntry<String, dynamic>> isGreaterThan;
  final List<MapEntry<String, dynamic>> isGreaterThanOrEqualTo;
  final List<MapEntry<String, dynamic>> arrayContains;
  final List<MapEntry<String, bool>> orderBy;
  final List<MapEntry<String, bool>> isNull;

  Query applyToQuery(Query initial) {
    Query finalQuery = initial;
    isEqualTo?.forEach((item) {
      final key = item.key;
      final value = item.value;
      finalQuery = finalQuery.where(key, isEqualTo: value);
    });
    isNotEqualTo?.forEach((item) {
      final key = item.key;
      final value = item.value;
      finalQuery = finalQuery.where(key, isNotEqualTo: value);
    });
    isLessThan?.forEach((item) {
      final key = item.key;
      final value = item.value;
      finalQuery = finalQuery.where(key, isLessThan: value);
    });
    isLessThanOrEqualTo?.forEach((item) {
      final key = item.key;
      final value = item.value;
      finalQuery = finalQuery.where(key, isLessThanOrEqualTo: value);
    });
    isGreaterThan?.forEach((item) {
      final key = item.key;
      final value = item.value;
      finalQuery = finalQuery.where(key, isGreaterThan: value);
    });
    isGreaterThanOrEqualTo?.forEach((item) {
      final key = item.key;
      final value = item.value;
      finalQuery = finalQuery.where(key, isGreaterThanOrEqualTo: value);
    });
    arrayContains?.forEach((item) {
      final key = item.key;
      final value = item.value;
      finalQuery = finalQuery.where(key, arrayContains: value);
    });
    isNull?.forEach((item) {
      final key = item.key;
      final value = item.value;
      finalQuery = finalQuery.where(key, isNull: value);
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
