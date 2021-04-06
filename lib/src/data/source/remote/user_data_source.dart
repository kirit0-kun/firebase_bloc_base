import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_bloc_base/firebase_bloc_base.dart';

abstract class UserDataSource<T extends FirebaseProfile>
    extends FirebaseDataSource {
  Future<T> getUser(String id);
  Stream<T> listenToUser(String id);
  Stream<T> createUser(User user,
      {String firstName, String lastName, bool requireConfirmation});
  Future<T> updateUserAccount(T userAccount, bool bool);
}
