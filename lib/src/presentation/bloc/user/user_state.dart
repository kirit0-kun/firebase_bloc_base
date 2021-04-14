import 'package:equatable/equatable.dart';
import 'package:firebase_bloc_base/firebase_bloc_base.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

class UserLoadingState extends UserState {
  const UserLoadingState();

  @override
  List<Object> get props => [];
}

class SignedInState<UserType extends FirebaseProfile> extends UserState {
  final UserType userAccount;
  const SignedInState(this.userAccount);

  @override
  List<Object> get props => [this.userAccount];
}

class SignedUpState<UserType extends FirebaseProfile> extends SignedInState {
  const SignedUpState(UserType userAccount) : super(userAccount);
}

class SignedInWithNoVerifiedEmailState<UserType extends FirebaseProfile>
    extends SignedInState {
  const SignedInWithNoVerifiedEmailState(UserType userAccount)
      : super(userAccount);
}

class SignedOutState extends UserState {
  const SignedOutState();
}
