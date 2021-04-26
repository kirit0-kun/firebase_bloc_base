import 'dart:async';

import 'package:worker_manager/src/cancelable.dart';
import 'package:worker_manager/worker_manager.dart';

export 'package:worker_manager/src/cancelable.dart';

class CustomExecutor implements Executor {
  final bool separateIsolate;

  static const CustomExecutor _isolateInstance = CustomExecutor._(true);
  static const CustomExecutor _instance = CustomExecutor._(false);
  static const String isolate = 'isolate';

  const CustomExecutor._([this.separateIsolate = false]);

  factory CustomExecutor([bool separateIsolate = false]) {
    CustomExecutor executor;
    if (separateIsolate) {
      executor = _isolateInstance;
    } else {
      executor = _instance;
    }
    return executor;
  }

  @override
  Future<void> warmUp({bool log = false, int isolatesCount}) =>
      Executor().warmUp(log: log, isolatesCount: isolatesCount);

  @override
  Cancelable<O> execute<A, B, C, D, O>(
      {A arg1,
      B arg2,
      C arg3,
      D arg4,
      fun1,
      fun2,
      fun3,
      fun4,
      WorkPriority priority = WorkPriority.high}) {
    if (separateIsolate) {
      return Executor().execute<A, B, C, D, O>(
          arg1: arg1,
          arg2: arg2,
          arg3: arg3,
          arg4: arg4,
          fun1: fun1,
          fun2: fun2,
          fun3: fun3,
          fun4: fun4,
          priority: priority);
    } else {
      return fakeExecute<A, B, C, D, O>(
          arg1: arg1,
          arg2: arg2,
          arg3: arg3,
          arg4: arg4,
          fun1: fun1,
          fun2: fun2,
          fun3: fun3,
          fun4: fun4,
          priority: priority);
    }
  }

  @override
  Cancelable<O> fakeExecute<A, B, C, D, O>(
      {A arg1,
      B arg2,
      C arg3,
      D arg4,
      fun1,
      fun2,
      fun3,
      fun4,
      WorkPriority priority = WorkPriority.high}) {
    return Executor().fakeExecute<A, B, C, D, O>(
        arg1: arg1,
        arg2: arg2,
        arg3: arg3,
        arg4: arg4,
        fun1: fun1,
        fun2: fun2,
        fun3: fun3,
        fun4: fun4,
        priority: priority);
  }
}

// class _SameIsolateExecutor implements Executor {
//   @override
//   Cancelable<O> execute<A, B, C, D, O>({A arg1, B arg2, C arg3, D arg4, fun1, fun2, fun3, fun4, WorkPriority priority = WorkPriority.high}) {
//     final completer = Completer<O>();
//     if (fun1 != null) {
//       completer.complete(fun1(arg1));
//     } else if (fun2 != null) {
//       completer.complete(fun2(arg1, arg2));
//     } else if (fun3 != null) {
//       completer.complete(fun3(arg1, arg2, arg3));
//     } else if (fun4 != null) {
//       completer.complete(fun4(arg1, arg2, arg3, arg4));
//     }
//     return Cancelable(completer, () {});
//   }
//
//   @override
//   Cancelable<O> fakeExecute<A, B, C, D, O>({A arg1, B arg2, C arg3, D arg4, fun1, fun2, fun3, fun4, WorkPriority priority = WorkPriority.high}) {
//     return execute<A, B, C, D, O>(arg1: arg1, arg2: arg2, arg3: arg3, arg4: arg4, fun1: fun1, fun2: fun2, fun3: fun3, fun4: fun4, priority: priority);
//   }
//
//   @override
//   Future<void> warmUp({bool log = false}) => Executor().warmUp(log: log);
// }
