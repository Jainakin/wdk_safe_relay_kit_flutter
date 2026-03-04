import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation.dart';

/// UserOperation plus bundler payload (tx hash, block info).
class UserOperationWithPayload {
  const UserOperationWithPayload({
    required this.userOperation,
    required this.entryPoint,
    required this.transactionHash,
    required this.blockHash,
    required this.blockNumber,
  });

  final UserOperation userOperation;
  final String entryPoint;
  final String transactionHash;
  final String blockHash;
  final String blockNumber;
}
