import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../firebase_bloc_base.dart';
import 'base_converter_bloc.dart';

abstract class BaseFormBundle<T> extends Equatable {
  final int pageNum;

  const BaseFormBundle(this.pageNum);

  @override
  List<Object?> get props => [this.pageNum];
}

class DefaultFormBundle<T> extends BaseFormBundle<T> {
  final T? object;

  const DefaultFormBundle(int pageNum, this.object) : super(pageNum);

  @override
  List<Object?> get props => [...super.props, this.object];
}

abstract class BaseFormBloc<EntityType, InputType,
        FormBundleType extends BaseFormBundle<EntityType>>
    extends BaseConverterBloc<InputType, FormBundleType> {
  static const _OPERATION = 'DEFAULT_OPERATION';

  final int startPageNum;
  EntityType? object;
  EntityType? initial;

  late int statePageNum;
  int get maxPages;

  bool get canSave => object != initial;
  bool get isLastPage => statePageNum + 1 == maxPages;

  BaseFormBundle<EntityType> get bundle =>
      DefaultFormBundle<EntityType>(statePageNum, object);

  FormBundleType get currentData => bundle as FormBundleType;

  @override
  Future<FormBundleType> convert(InputType? input) async {
    return currentData;
  }

  @override
  void onChange(change) {
    checkState(change.nextState);
    super.onChange(change);
  }

  Future<void> checkState(BlocState<FormBundleType?> nextState) async {
    return;
  }

  BaseFormBloc(
      {int? startPageNum,
      EntityType? initialObject,
      BaseProviderBloc<dynamic, InputType>? sourceBloc})
      : startPageNum = startPageNum ?? 0,
        super(sourceBloc: sourceBloc) {
    statePageNum = this.startPageNum;
    initial = initialObject;
    object = initialObject;
  }

  void updateObject(EntityType newObject, [bool updateState = true]) {
    this.object = newObject;
    if (updateState) {
      emitLoaded();
    }
  }

  void next() {
    if (!isLastPage) {
      statePageNum += 1;
      emitLoaded();
    } else {
      save();
    }
  }

  Future<void> save() async {
    fixStatus();
    await saveObject();
  }

  void fixStatus() {}

  @protected
  Future<void> saveObject();

  Future<bool> goBack() async {
    return state is! Operation;
  }

  bool cancel();

  // ignore: invalid_override_different_default_values_named
  bool onCancel({String? operationTag}) => cancel();
}
