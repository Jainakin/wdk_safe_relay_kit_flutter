import 'dart:typed_data';

import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

/// ABI for Safe4337Module.getOperationHash
/// (EntryPoint v0.7 packed struct).
const String _getOperationHashAbiJson = '''
[
  {
    "type": "function",
    "name": "getOperationHash",
    "inputs": [
      {
        "name": "userOp",
        "type": "tuple",
        "components": [
          {"name": "sender", "type": "address"},
          {"name": "nonce", "type": "uint256"},
          {"name": "initCode", "type": "bytes"},
          {"name": "callData", "type": "bytes"},
          {"name": "accountGasLimits", "type": "bytes32"},
          {"name": "preVerificationGas", "type": "uint256"},
          {"name": "gasFees", "type": "bytes32"},
          {"name": "paymasterAndData", "type": "bytes"},
          {"name": "signature", "type": "bytes"}
        ]
      }
    ],
    "outputs": [{"type": "bytes32"}],
    "stateMutability": "view"
  }
]
''';

/// Packs two uint128 values into one bytes32.
Uint8List _packU128Pair(BigInt a, BigInt b) {
  final out = Uint8List(32);
  final aHex = a.toRadixString(16).padLeft(32, '0');
  final bHex = b.toRadixString(16).padLeft(32, '0');
  final aHex16 =
      aHex.length > 32 ? aHex.substring(aHex.length - 32) : aHex;
  final bHex16 =
      bHex.length > 32 ? bHex.substring(bHex.length - 32) : bHex;
  final aBytes = hexToBytes('0x$aHex16');
  final bBytes = hexToBytes('0x$bHex16');
  final aStart = 16 - aBytes.length;
  final bStart = 16 - bBytes.length;
  for (var i = 0; i < aBytes.length; i++) {
    out[aStart + i] = aBytes[i];
  }
  for (var i = 0; i < bBytes.length; i++) {
    out[16 + bStart + i] = bBytes[i];
  }
  return out;
}

/// Converts [UserOperation] to the packed tuple for
/// Safe4337Module.getOperationHash.
List<dynamic> _userOpToPackedTuple(UserOperation op) {
  final accountGasLimits =
      _packU128Pair(op.verificationGasLimit, op.callGasLimit);
  final gasFees = _packU128Pair(op.maxPriorityFeePerGas, op.maxFeePerGas);
  final initCode = op.initCode.isEmpty || op.initCode == '0x'
      ? Uint8List(0)
      : hexToBytes(op.initCode);
  final callData = op.callData.isEmpty || op.callData == '0x'
      ? Uint8List(0)
      : hexToBytes(op.callData);
  final paymasterAndData =
      op.paymasterAndData.isEmpty || op.paymasterAndData == '0x'
          ? Uint8List(0)
          : hexToBytes(op.paymasterAndData);
  final signature = op.signature.isEmpty || op.signature == '0x'
      ? Uint8List(0)
      : hexToBytes(op.signature);
  return [
    EthereumAddress.fromHex(op.sender),
    op.nonce,
    initCode,
    callData,
    accountGasLimits,
    op.preVerificationGas,
    gasFees,
    paymasterAndData,
    signature,
  ];
}

ContractFunction _getOperationHashFunction() {
  final abi = ContractAbi.fromJson(_getOperationHashAbiJson, 'Safe4337Module');
  final f = abi.functions.where((e) => e.name == 'getOperationHash').first;
  return f;
}

/// Returns the Safe operation hash (bytes32) by calling the Safe 4337 module's
/// getOperationHash view (Safe4337Module.sol).
///
/// [provider] must support eth_call (e.g. Web3Client.makeRPCCall).
/// [moduleAddress] is the Safe4337Module for the chain.
///
/// Returns the bytes32 operation hash hex to pass to signSafeOperation.
Future<String> getOperationHash(
  dynamic provider,
  String moduleAddress,
  UserOperation userOp,
) async {
  final fn = _getOperationHashFunction();
  final packed = _userOpToPackedTuple(userOp);
  final encoded = fn.encodeCall([packed]);
  final dataHex = bytesToHex(encoded, include0x: true);

  final callObject = {
    'to': moduleAddress,
    'data': dataHex,
  };
  final raw = await (provider as dynamic).makeRPCCall(
    'eth_call',
    [callObject, 'latest'],
  );
  final result =
      raw is String ? raw : (raw as Map)['result'] as String? ?? '';
  if (result.isEmpty || result == '0x') {
    throw OperationHashException('getOperationHash returned empty');
  }
  return result;
}

class OperationHashException implements Exception {
  OperationHashException(this.message);
  final String message;
  @override
  String toString() => 'OperationHashException: $message';
}
