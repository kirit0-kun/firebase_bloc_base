import 'package:equatable/equatable.dart';

class GroupedItemHeader<T> extends Equatable {
  final String title;
  final String? subtitle;
  final List<T> items;

  GroupedItemHeader(this.title, this.items, [this.subtitle]);

  int get length => items.length;

  @override
  List<Object?> get props => [this.title, this.items, this.subtitle];
}
