import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

class FirebaseParams {
  const FirebaseParams({
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.orderBy,
    this.isNull,
    this.limit,
    this.startAfter,
  });

  final int limit;
  final Map<String, dynamic> isEqualTo;
  final Map<String, dynamic> isNotEqualTo;
  final Map<String, dynamic> isLessThan;
  final Map<String, dynamic> isLessThanOrEqualTo;
  final Map<String, dynamic> isGreaterThan;
  final Map<String, dynamic> isGreaterThanOrEqualTo;
  final Map<String, dynamic> arrayContains;
  final Map<String, List<dynamic>> arrayContainsAny;
  final Map<String, List<dynamic>> whereIn;
  final Map<String, List<dynamic>> whereNotIn;
  final List<Tuple2<String, bool>> orderBy;
  final Map<String, bool> isNull;
  final DocumentSnapshot startAfter;

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
    arrayContainsAny?.forEach((key, value) {
      finalQuery = finalQuery.where(key, arrayContainsAny: value);
    });
    whereIn?.forEach((key, value) {
      finalQuery = finalQuery.where(key, whereIn: value);
    });
    whereNotIn?.forEach((key, value) {
      finalQuery = finalQuery.where(key, whereNotIn: value);
    });
    isNull?.forEach((key, value) {
      finalQuery = finalQuery.where(key, isNull: value);
    });
    orderBy?.forEach((element) {
      final key = element.value1;
      final descending = element.value2;
      finalQuery = finalQuery.orderBy(key, descending: descending);
    });
    if (startAfter != null) {
      finalQuery = finalQuery.startAfterDocument(startAfter);
    }
    if (limit != null) {
      finalQuery = finalQuery.limit(limit);
    }
    return finalQuery;
  }
}
