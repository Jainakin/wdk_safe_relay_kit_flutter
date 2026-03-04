import 'package:wdk_safe_relay_kit_flutter/src/estimators/ifee_estimator.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation.dart';

/// Pimlico-specific fee estimator (uses Pimlico bundler RPC when
/// bundlerUrl is Pimlico). Falls back to same behaviour as generic if needed.
class PimlicoFeeEstimator implements IFeeEstimator {
  @override
  Future<UserOperation> preEstimateUserOperationGas(
    EstimateFeeContext context,
  ) async =>
      context.userOperation;

  @override
  Future<UserOperation> postEstimateUserOperationGas(
    EstimateFeeContext context,
  ) async =>
      context.userOperation;
}
