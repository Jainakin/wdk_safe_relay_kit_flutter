import 'package:wdk_safe_relay_kit_flutter/src/estimators/generic_fee_estimator.dart';
import 'package:wdk_safe_relay_kit_flutter/src/estimators/ifee_estimator.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation.dart';

/// Pimlico-specific fee estimator.
///
/// This estimator is intended for use when the bundler is a Pimlico endpoint.
/// It delegates gas estimation to [GenericFeeEstimator], which calls
/// `eth_estimateUserOperationGas` on the configured bundler. Pimlico bundlers
/// fully support this RPC, so gas fields are populated correctly.
///
/// For Pimlico paymaster flows (sponsorship or ERC-20 paymaster), combine this
/// estimator with `PaymasterOptions` / `PaymasterClient` so that
/// `paymasterAndData` is built via `pm_getPaymasterData`.
class PimlicoFeeEstimator implements IFeeEstimator {
  PimlicoFeeEstimator(this.provider, this.chainIdHex);

  final dynamic provider;
  final String chainIdHex;

  @override
  Future<UserOperation> preEstimateUserOperationGas(
    EstimateFeeContext context,
  ) async {
    // No pre-processing needed; rely on GenericFeeEstimator after bundler
    // estimation. UserOperation is returned unchanged here.
    return context.userOperation;
  }

  @override
  Future<UserOperation> postEstimateUserOperationGas(
    EstimateFeeContext context,
  ) async {
    final generic = GenericFeeEstimator(provider, chainIdHex);
    return generic.postEstimateUserOperationGas(context);
  }
}
