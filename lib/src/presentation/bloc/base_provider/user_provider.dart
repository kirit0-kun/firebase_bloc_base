import 'package:firebase_bloc_base/src/domain/entity/base_profile.dart';
import 'package:firebase_bloc_base/src/presentation/bloc/base_provider/base_provider_bloc.dart';
import 'package:firebase_bloc_base/src/presentation/bloc/base_provider/lifecycle_observer.dart';
import 'package:firebase_bloc_base/src/presentation/bloc/user/user_bloc.dart';
import 'package:firebase_bloc_base/src/presentation/bloc/user/user_state.dart';
import 'package:rxdart/rxdart.dart';

class UserProvider<UserType extends FirebaseProfile>
    extends BaseProviderBloc<dynamic, UserType> {
  final BaseUserBloc<UserType> userBloc;

  UserProvider(this.userBloc, LifecycleObserver observer)
      : super(getOnCreate: true, observer: observer);

  @override
  get additionalSources => [
        userBloc.stream.map((userState) {
          if (userState is UserLoadingState) {
            return BaseLoadingState<UserType>();
          } else if (userState is SignedOutState) {
            return BaseErrorState<UserType>(null);
          } else if (userState is SignedInState<UserType>) {
            return BaseLoadedState<UserType>(userState.userAccount);
          }
          return null;
        }).whereType<BaseProviderState<UserType>>()
      ];

  @override
  convert(input) async {
    return userBloc.currentUser!;
  }
}
