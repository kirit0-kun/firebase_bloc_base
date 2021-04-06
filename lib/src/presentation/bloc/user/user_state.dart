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

class SignedInState extends UserState {
  final FirebaseProfile userAccount;
  const SignedInState(this.userAccount);

  @override
  List<Object> get props => [this.userAccount];
}

class SignedUpState extends SignedInState {
  const SignedUpState(FirebaseProfile userAccount) : super(userAccount);
}

class SignedInWithNoVerifiedEmailState extends SignedInState {
  const SignedInWithNoVerifiedEmailState(FirebaseProfile userAccount)
      : super(userAccount);
}

class SignedOutState extends UserState {
  const SignedOutState();
}
