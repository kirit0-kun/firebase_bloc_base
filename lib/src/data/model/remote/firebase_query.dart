import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

class FirebaseQuerySwitcher {
  static const l = 10;

  const FirebaseQuerySwitcher({
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

  List<Query> moreThan10(Query initial, {bool arrayContainsAny, bool whereIn}) {
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
    List<Query> newQueries;
    if (arrayContainsAny == true && this.arrayContainsAny != null) {
      newQueries = this
          .arrayContainsAny
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
          .whereIn
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
    return newQueries;
  }

  Future<List<QueryDocumentSnapshot>> moreThan10Future(Query initial,
      {bool arrayContainsAny, bool whereIn}) {
    final futures = moreThan10(initial,
            whereIn: whereIn, arrayContainsAny: arrayContainsAny)
        .map((query) => query.get().then((value) => value?.docs));
    return Future.wait(futures).then((value) => value
        .where((element) => element != null)
        .expand((element) => element)
        .where((element) => element.exists)
        .toList());
  }

  Stream<List<QueryDocumentSnapshot>> moreThan10Stream(Query initial,
      {bool arrayContainsAny, bool whereIn}) {
    final futures = moreThan10(initial,
            whereIn: whereIn, arrayContainsAny: arrayContainsAny)
        .map((query) =>
            query.snapshots().defaultIfEmpty(null).map((value) => value?.docs))
        .toList();
    return CombineLatestStream<List<QueryDocumentSnapshot>,
            List<QueryDocumentSnapshot>>(
        futures,
        (streams) => streams
            .where((element) => element != null)
            .expand((element) => element)
            .where((element) => element.exists)
            .toList());
  }

  Future<List<T>> moreThan10FutureTransform<T>(
      Query initial, T Function(Map<String, dynamic>) transform,
      {bool arrayContainsAny, bool whereIn}) {
    return moreThan10Future(initial,
            arrayContainsAny: arrayContainsAny, whereIn: whereIn)
        .then((value) => value.map((data) => transform(data.data())).toList());
  }

  Stream<List<T>> moreThan10StreamTransform<T>(
      Query initial, T Function(Map<String, dynamic>) transform,
      {bool arrayContainsAny, bool whereIn}) {
    return moreThan10Stream(initial,
            arrayContainsAny: arrayContainsAny, whereIn: whereIn)
        .map((list) => list.map((data) => transform(data.data())));
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
