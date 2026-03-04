import 'package:wdk_safe_relay_kit_flutter/src/types/meta_transaction_data.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation.dart';

/// Safe-specific operation (batch of txs + UserOp fields) before signing.
class SafeOperation {
  SafeOperation({
    required this.transactions,
    required this.userOperation,
    this.signatures = const {},
  });

  final List<MetaTransactionData> transactions;
  UserOperation userOperation;
  Map<String, String> signatures;

  /// Add a signature (owner address -> hex signature).
  void addSignature(String ownerAddress, String signature) {
    signatures = Map.from(signatures)..[ownerAddress.toLowerCase()] = signature;
  }
}
