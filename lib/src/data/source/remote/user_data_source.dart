import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_bloc_base/firebase_bloc_base.dart';

abstract class BaseUserDataSource<T extends FirebaseProfile>
    extends FirebaseDataSource {
  Future<T?> getUser(User user);
  Stream<T?> listenToUser(User user);
  Stream<T?> createUser(User user,
      {String? firstName, String? lastName, bool? requireConfirmation});
  Future<T?> updateUserAccount(T userAccount);
}
