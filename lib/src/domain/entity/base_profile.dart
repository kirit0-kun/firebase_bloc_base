import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseProfile extends Equatable {
  const FirebaseProfile({
    this.isNewUser,
    this.userDetails,
  });

  final User userDetails;
  final bool isNewUser;

  String get id => userDetails?.uid;
  String get email => userDetails?.email;
  String get phoneNumber => userDetails?.phoneNumber;

  bool get emailVerified => userDetails?.emailVerified == true;

  FirebaseProfile copyWith({User userDetails, bool isNewUser, bool active});

  @override
  List<Object> get props => [
        userDetails?.toString(),
        isNewUser,
        id,
        email,
        phoneNumber,
      ];
}
