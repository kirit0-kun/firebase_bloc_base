import 'paginated_mixin.dart';
import 'working_state.dart';

abstract class PaginatedState<T> {
  PaginatedData<T>? get paginatedData;
}

class PaginatedLoadedState<T> extends LoadedState<T>
    implements PaginatedState<T> {
  final PaginatedData<T>? paginatedData;

  const PaginatedLoadedState(this.paginatedData, T data) : super(data);
}

class LoadingNextPageState<T> extends LoadedState<T> {
  const LoadingNextPageState(T data) : super(data);
}

class ErrorGettingNextPageState<T> extends LoadedState<T> {
  final String? message;

  const ErrorGettingNextPageState(T data, this.message) : super(data);

  @override
  List<Object?> get props => [...super.props, this.message];
}
