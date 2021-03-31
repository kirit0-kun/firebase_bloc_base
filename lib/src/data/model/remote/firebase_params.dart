import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:json_annotation/json_annotation.dart';

part 'firebase_params.g.dart';

@JsonSerializable(createFactory: false)
class FirebaseParams extends Params {
  const FirebaseParams();

  Map<String, dynamic> toMap() => _$FirebaseParamsToJson(this);
}
