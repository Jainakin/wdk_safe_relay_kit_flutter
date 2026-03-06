import 'package:wdk_safe_relay_kit_flutter/src/bundler_client.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation.dart';

/// Context passed to fee estimator.
class EstimateFeeContext {
  const EstimateFeeContext({
    required this.userOperation,
    required this.bundlerUrl,
    required this.entryPoint,
    this.paymasterUrl,
    this.sponsorshipPolicyId,
    this.bundlerClient,
  });

  final UserOperation userOperation;
  final String bundlerUrl;
  final String entryPoint;
  final String? paymasterUrl;
  final String? sponsorshipPolicyId;

  /// Optional bundler client. When set, estimators should use it instead of
  /// creating a new one (avoids duplicate RPC).
  final BundlerClient? bundlerClient;
}

/// Fee estimator for UserOperation gas (pre/post bundler estimation).
abstract class IFeeEstimator {
  /// Optional: run before calling eth_estimateUserOperationGas.
  Future<UserOperation> preEstimateUserOperationGas(EstimateFeeContext context);

  /// Optional: run after eth_estimateUserOperationGas to adjust.
  Future<UserOperation> postEstimateUserOperationGas(
    EstimateFeeContext context,
  );
}
