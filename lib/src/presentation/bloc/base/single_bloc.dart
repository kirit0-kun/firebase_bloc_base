import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../firebase_bloc_base.dart';
import 'base_converter_bloc.dart';

class BaseSingleBundle<T> extends Equatable {
  final bool edit;
  final T object;

  const BaseSingleBundle(this.edit, this.object);

  @override
  List<Object> get props => [this.edit, this.object];
}

class SingleBundle<T> extends BaseSingleBundle<T> {
  const SingleBundle(bool edit, T object) : super(edit, object);
}

abstract class SingleBloc<EntityType>
    extends BaseSingleBloc<EntityType, SingleBundle<EntityType>> {
  SingleBloc(
      {String id,
      BaseProviderBloc<dynamic, Map<String, EntityType>> providerBloc})
      : super(id: id, providerBloc: providerBloc);

  @override
  SingleBundle<EntityType> get currentData => SingleBundle(isEdit, object);

  Future<SingleBundle<EntityType>> convert(
      Map<String, EntityType> input) async {
    final object = filter(input);
    if (object != null) {
      return SingleBundle(isEdit, object);
    } else {
      print("couldn't find id ${this.id}");
      throw FlutterError("Couldn't find the requested item");
    }
  }
}

abstract class BaseSingleBloc<EntityType,
        BundleType extends BaseSingleBundle<EntityType>>
    extends BaseConverterBloc<Map<String, EntityType>, BundleType> {
  static const DELETION_OPERATION = 'DELETION_OPERATION';

  final String id;
  EntityType object;
  EntityType temp;

  bool isEdit = false;

  BaseSingleBloc(
      {this.id,
      BaseProviderBloc<dynamic, Map<String, EntityType>> providerBloc})
      : super(sourceBloc: providerBloc);

  @mustCallSuper
  void handleData(BundleType data) {
    temp = data.object;
    object = data.object;
  }

  EntityType filter(Map<String, EntityType> input) {
    final object = input[this.id];
    return object;
  }

  Future<bool> goBack() async {
    if (state is OnGoingOperationState) {
      return false;
    } else {
      if (isEdit) {
        discard();
        return false;
      }
      return true;
    }
  }

  @override
  void onChange(change) {
    if (change.nextState is SuccessfulOperationState) {
      isEdit = false;
    }
    super.onChange(change);
  }

  @mustCallSuper
  void discard() {
    object = temp;
    isEdit = false;
    emitLoaded();
  }

  @mustCallSuper
  void edit() {
    isEdit = true;
    emitLoaded();
  }

  // ignore: invalid_override_different_default_values_named
  bool onCancel({String operationTag}) => false;

  Future<void> delete();
}
