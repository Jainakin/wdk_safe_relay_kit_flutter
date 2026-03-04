/// Receipt returned by bundler for a UserOperation.
class UserOperationReceipt {
  const UserOperationReceipt({
    required this.userOpHash,
    required this.sender,
    required this.nonce,
    required this.actualGasUsed,
    required this.actualGasCost,
    required this.success,
    required this.logs,
    required this.receipt,
  });

  final String userOpHash;
  final String sender;
  final String nonce;
  final String actualGasUsed;
  final String actualGasCost;
  final bool success;
  final List<Map<String, dynamic>> logs;
  final Map<String, dynamic> receipt;
}
