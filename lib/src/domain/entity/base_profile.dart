import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseProfile extends Equatable {
  const FirebaseProfile({
    this.firstTime,
    this.userDetails,
  });

  final User userDetails;
  final bool firstTime;

  String get id => userDetails?.uid;
  String get email => userDetails?.email;
  String get phoneNumber => userDetails?.phoneNumber;

  bool get emailVerified => userDetails?.emailVerified == true;

  FirebaseProfile copyWith({User userDetails, bool firstTime});

  @override
  List<Object> get props => [
        userDetails?.toString(),
        firstTime,
        id,
        email,
        phoneNumber,
      ];
}
