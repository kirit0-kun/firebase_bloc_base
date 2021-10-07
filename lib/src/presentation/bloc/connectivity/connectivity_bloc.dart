import 'package:firebase_bloc_base/src/domain/service/network_connectivity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_state.dart';

class ConnectivityBloc extends Cubit<ConnectivityState> {
  final NetworkInfo networkInfo;

  ConnectivityBloc(this.networkInfo)
      : super(mapConnectionState(networkInfo.hasConnection!)) {
    networkInfo.connectionChange.listen((event) {
      if (event != null) emit(mapConnectionState(event));
    });
    networkInfo.initialize();
  }

  void checkInternetConnection() {
    emit(ConnectionLoadingState());
    networkInfo.checkConnection();
  }

  static ConnectivityState mapConnectionState(bool isConnected) {
    if (isConnected) {
      return ConnectedState();
    } else {
      return NotConnectedState();
    }
  }

  @override
  Future<void> close() {
    networkInfo.dispose();
    return super.close();
  }
}
