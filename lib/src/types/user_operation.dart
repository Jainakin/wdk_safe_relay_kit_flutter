/// ERC-4337 UserOperation (EntryPoint v0.6 / v0.7 common shape).
///
/// Covers the shared fields used by most bundlers. EntryPoint v0.7-specific
/// fields (e.g. signature aggregator address/data) can be added here and in
/// bundler serialization when a bundler or chain requires them.
/// See https://eips.ethereum.org/EIPS/eip-4337
class UserOperation {
  const UserOperation({
    required this.sender,
    required this.nonce,
    required this.initCode,
    required this.callData,
    required this.callGasLimit,
    required this.verificationGasLimit,
    required this.preVerificationGas,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.paymasterAndData,
    required this.signature,
  });

  final String sender;
  final BigInt nonce;
  final String initCode;
  final String callData;
  final BigInt callGasLimit;
  final BigInt verificationGasLimit;
  final BigInt preVerificationGas;
  final BigInt maxFeePerGas;
  final BigInt maxPriorityFeePerGas;
  final String paymasterAndData;
  final String signature;
}
