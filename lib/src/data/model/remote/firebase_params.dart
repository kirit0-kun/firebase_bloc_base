import 'package:firebase_bloc_base/firebase_bloc_base.dart';

abstract class FirebaseQueryParams {
  const FirebaseQueryParams();

  FirebaseQuerySwitcher generateSwitcher();
}
