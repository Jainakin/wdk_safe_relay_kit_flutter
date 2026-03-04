import 'package:wdk_safe_relay_kit_flutter/src/bundler_client.dart';
import 'package:wdk_safe_relay_kit_flutter/src/estimators/ifee_estimator.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation.dart';

/// Uses bundler RPC eth_estimateUserOperationGas to fill gas fields.
class GenericFeeEstimator implements IFeeEstimator {
  GenericFeeEstimator(this.provider, this.chainIdHex);

  final dynamic provider;
  final String chainIdHex;

  @override
  Future<UserOperation> preEstimateUserOperationGas(
    EstimateFeeContext context,
  ) async =>
      context.userOperation;

  @override
  Future<UserOperation> postEstimateUserOperationGas(
    EstimateFeeContext context,
  ) async {
    final bundler = BundlerClient(
      bundlerUrl: context.bundlerUrl,
      entryPointAddress: context.entryPoint,
    );
    final gas = await bundler.estimateUserOperationGas(
      userOperation: context.userOperation,
      entryPoint: context.entryPoint,
    );
    final uo = context.userOperation;
    return UserOperation(
      sender: uo.sender,
      nonce: uo.nonce,
      initCode: uo.initCode,
      callData: uo.callData,
      callGasLimit: gas['callGasLimit'] ?? uo.callGasLimit,
      verificationGasLimit:
          gas['verificationGasLimit'] ?? uo.verificationGasLimit,
      preVerificationGas: gas['preVerificationGas'] ?? uo.preVerificationGas,
      maxFeePerGas: uo.maxFeePerGas,
      maxPriorityFeePerGas: uo.maxPriorityFeePerGas,
      paymasterAndData: uo.paymasterAndData,
      signature: uo.signature,
    );
  }
}
