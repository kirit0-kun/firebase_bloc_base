import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:flutter/foundation.dart';

abstract class PaginatedProviderBloc<Data>
    extends BaseProviderBloc<List<Data>> {
  PaginatedProviderBloc(
      {List<Data> initialDate,
      bool enableRetry = true,
      bool getOnCreate = true,
      LifecycleObserver observer})
      : super(
            observer: observer,
            initialDate: initialDate,
            getOnCreate: getOnCreate,
            enableRetry: enableRetry);

  void interceptResponse(Result<ResponseEntity> result,
      {void onSuccess(), void onFailure()}) {
    result.resultFuture.then((value) {
      if (value is Success) {
        onSuccess?.call();
      } else if (value is Failure) {
        onFailure?.call();
      }
    });
  }

  @mustCallSuper
  void getData({bool refresh = false}) {
    if (green && shouldBeGreen) {
      if (dataSource != null) {
        handleOperation(dataSource, refresh);
      } else if (dataSourceStream != null) {
        handleStream(dataSourceStream, refresh);
      }
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
