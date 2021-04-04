import 'package:equatable/equatable.dart';

class ResponseEntity extends Equatable {
  final String message;

  const ResponseEntity(this.message);

  @override
  List<Object> get props => [this.message];
}

class Success extends ResponseEntity {
  const Success([String message = '']) : super(message);

  @override
  List<Object> get props => [...super.props];
}

class Failure extends ResponseEntity {
  const Failure(String message) : super(message);

  @override
  List<Object> get props => [...super.props];
}

class InternetFailure extends Failure {
  const InternetFailure(String message) : super(message);
}
