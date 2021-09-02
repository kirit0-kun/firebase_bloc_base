import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDataSource {
  final firestoreInstance = FirebaseFirestore.instance;

  GetOptions? get defaultGetOptions => GetOptions(source: Source.server);
  
  FirebaseDataSource();
}
