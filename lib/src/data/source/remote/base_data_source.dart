import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDataSource {
  final firestoreInstance = FirebaseFirestore.instance;

  GetOptions? get defaultGetOptions => GetOptions(source: Source.server);

  FirebaseDataSource();

  List<T> getObjects<T>(QuerySnapshot<T> docs) {
    return docs.docs.map((e) => e.data()).toList();
  }

  Future<T?> getSingle<T>(Query<T?> query, [bool fromBack = false]) async {
    final docs = await (fromBack ? query.limitToLast(1): query.limit(1)).get(defaultGetOptions);
    final objects = getObjects(docs);
    if (objects.isEmpty) {
      return null;
    }
    return objects.first;
  }

  Future<T?> getSingleDoc<T>(DocumentReference<T?> query,
      [bool fromBack = false]) async {
    final doc = await query.get(defaultGetOptions);
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }
}
