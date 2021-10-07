import 'package:equatable/equatable.dart';

abstract class ConnectivityState extends Equatable {}

class ConnectionLoadingState extends ConnectivityState {
  @override
  get props => [];
}

class ConnectedState extends ConnectivityState {
  @override
  get props => [];
}

class NotConnectedState extends ConnectivityState {
  @override
  get props => [];
}
