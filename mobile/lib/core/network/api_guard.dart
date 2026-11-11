import '../errors/failure_mapper.dart';

/// Runs a data-layer call and rethrows anything as an `AppFailure`.
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } catch (error) {
    throw mapToFailure(error);
  }
}
