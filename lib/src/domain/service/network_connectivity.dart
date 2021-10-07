import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:data_connection_checker_tv/data_connection_checker.dart';

abstract class NetworkInfo {
  Stream<bool?> get connectionChange;

  bool? hasConnection;

  void initialize();
  void dispose();

  Future<bool?> checkConnection();
}

class NetworkInfoImpl extends NetworkInfo {
  //This creates the single instance by calling the `_internal` constructor specified below
  static final NetworkInfoImpl _singleton = NetworkInfoImpl._internal();
  NetworkInfoImpl._internal();

  //This is what's used to retrieve the instance through the app
  static NetworkInfoImpl getInstance() => _singleton;

  //This tracks the current connection status
  @override
  bool? hasConnection = true;

  //This is how we'll allow subscribing to connection changes
  StreamController<bool?> _connectionChangeController =
      StreamController.broadcast();

  //flutter_connectivity
  final Connectivity _connectivity = Connectivity();

  //Hook into flutter_connectivity's Stream to listen for changes
  //And check the connection status out of the gate
  @override
  void initialize() {
    _connectivity.onConnectivityChanged.listen(_connectionChange);
    checkConnection();
  }

  @override
  Stream<bool?> get connectionChange => _connectionChangeController.stream
      .asBroadcastStream(onCancel: (sub) => sub.cancel());

  //A clean up method to close our StreamController
  //   Because this is meant to exist through the entire application life cycle this isn't
  //   really an issue
  @override
  void dispose() {
    _connectionChangeController.close();
  }

  //flutter_connectivity's listener
  void _connectionChange(ConnectivityResult result) {
    checkConnection();
  }

  //The test to actually see if there is a connection
  @override
  Future<bool?> checkConnection() async {
    bool? previousConnection = hasConnection;
    var connectivityResult = await (Connectivity().checkConnectivity());
    hasConnection = await _isInternet(connectivityResult);

    //The connection status changed send out an update to all listeners
    if (previousConnection != hasConnection) {
      _connectionChangeController.add(hasConnection);
    }

    return hasConnection;
  }

  Future<bool> _isInternet(ConnectivityResult connectivityResult) async {
    if (connectivityResult == ConnectivityResult.mobile) {
      // I am connected to a mobile network, make sure there is actually a net connection.
      if (await DataConnectionChecker().hasConnection) {
        // Mobile data detected & internet connection confirmed.
        return true;
      } else {
        // Mobile data detected but no internet connection found.
        return false;
      }
    } else if (connectivityResult == ConnectivityResult.wifi) {
      // I am connected to a WIFI network, make sure there is actually a net connection.
      if (await DataConnectionChecker().hasConnection) {
        // Wifi detected & internet connection confirmed.
        return true;
      } else {
        // Wifi detected but no internet connection found.
        return false;
      }
    } else {
      // Neither mobile data or WIFI detected, not internet connection found.
      return false;
    }
  }
}
