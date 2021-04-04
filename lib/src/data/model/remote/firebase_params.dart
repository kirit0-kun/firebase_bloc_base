import 'package:json_annotation/json_annotation.dart';

import 'params.dart';

part 'firebase_params.g.dart';

@JsonSerializable(createFactory: false)
class FirebaseParams extends Params {
  const FirebaseParams();

  Map<String, dynamic> toMap() => _$FirebaseParamsToJson(this);
}
