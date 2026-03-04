import 'package:wdk_safe_relay_kit_flutter/src/estimators/ifee_estimator.dart';

/// Options when creating a SafeOperation via Safe4337Pack.createTransaction.
class CreateTransactionOptions {
  const CreateTransactionOptions({
    this.feeEstimator,
    this.amountToApprove,
    this.paymasterTokenAddress,
    this.validUntil,
    this.validAfter,
    this.customNonce,
  });

  final IFeeEstimator? feeEstimator;
  final BigInt? amountToApprove;
  final String? paymasterTokenAddress;
  final int? validUntil;
  final int? validAfter;
  final BigInt? customNonce;
}
