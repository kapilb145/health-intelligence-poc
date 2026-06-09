import '../result/result.dart';

abstract class UseCase<ResultType, Params> {
  Future<Result<ResultType>> call(Params params);
}

class NoParams {
  const NoParams();
}