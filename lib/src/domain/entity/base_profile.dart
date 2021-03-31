import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseProfile extends BaseProfile {
  const FirebaseProfile({
    bool active,
    this.isNewUser,
    this.userDetails,
  }) : super(active: active);

  final User userDetails;
  final bool isNewUser;

  @override
  String get id => userDetails?.uid;
  String get email => userDetails?.email;
  String get phoneNumber => userDetails?.phoneNumber;

  @override
  get accessToken => userDetails?.refreshToken;

  FirebaseProfile copyWith({User userDetails, bool isNewUser, bool active});

  @override
  List<Object> get props => super.props
    ..addAll([
      this.userDetails?.toString(),
    ]);
}
