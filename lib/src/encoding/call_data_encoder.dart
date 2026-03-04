import 'dart:typed_data';

import 'package:pointycastle/digests/keccak.dart';
import 'package:wdk_safe_relay_kit_flutter/src/constants.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/meta_transaction_data.dart';

/// Encodes callData for the Safe 4337 module: executeUserOp (single or batch).
///
/// Single tx: executeUserOp(to, value, data, 0).
/// Batch: executeUserOp(multiSendAddress, 0, multiSend(packed), 0).
String encodeSafe4337CallData(
  List<MetaTransactionData> transactions, {
  String? multiSendAddress,
}) {
  if (transactions.isEmpty) return '0x';
  multiSendAddress ??= defaultMultiSendCallOnlyAddress;

  if (transactions.length == 1) {
    final tx = transactions.single;
    final data = tx.data ?? '0x';
    return _encodeExecuteUserOp(tx.to, tx.value, data, 0);
  }

  final packed = _encodeMultiSendPacked(transactions);
  final multiSendCalldata = _encodeMultiSend(packed);
  return _encodeExecuteUserOp(
    multiSendAddress,
    BigInt.zero,
    multiSendCalldata,
    0,
  );
}

/// executeUserOp(address to, uint256 value, bytes data, uint8 operation)
String _encodeExecuteUserOp(
  String to,
  BigInt value,
  String dataHex,
  int operation,
) {
  final selector = _selector('executeUserOp(address,uint256,bytes,uint8)');
  final dataBytes = _hexToBytes(dataHex);
  final encoded = _abiEncodeExecuteUserOp(to, value, dataBytes, operation);
  return '0x${_bytesToHex(selector)}${_bytesToHex(encoded)}';
}

/// multiSend(bytes memory transactions) — returns full calldata hex.
String _encodeMultiSend(Uint8List packedTransactions) {
  final selector = _selector('multiSend(bytes)');
  final encoded = _abiEncodeBytes(packedTransactions);
  return '0x${_bytesToHex(selector)}${_bytesToHex(encoded)}';
}

/// Packed format per Safe MultiSendCallOnly: op(1) + to(20) + value(32) +
/// dataLength(32) + data.
Uint8List _encodeMultiSendPacked(List<MetaTransactionData> transactions) {
  final out = <int>[];
  for (final tx in transactions) {
    out
      ..add(0) // operation: 0 = CALL (MultiSendCallOnly)
      ..addAll(_addressToBytes(tx.to))
      ..addAll(_uint256ToBytes(tx.value));
    final data = _hexToBytes(tx.data ?? '0x');
    out
      ..addAll(_uint256ToBytes(BigInt.from(data.length)))
      ..addAll(data);
  }
  return Uint8List.fromList(out);
}

Uint8List _selector(String signature) {
  final h = KeccakDigest(256).process(Uint8List.fromList(signature.codeUnits));
  return h.sublist(0, 4);
}

Uint8List _abiEncodeExecuteUserOp(
  String to,
  BigInt value,
  Uint8List data,
  int operation,
) {
  final head = <int>[
    ..._addressToBytesPadded(to),
    ..._uint256ToBytes(value),
    ..._uint256ToBytes(BigInt.from(0x80)), // offset to bytes
    ..._uint256ToBytes(BigInt.from(operation)),
  ];

  final tail = <int>[
    ..._uint256ToBytes(BigInt.from(data.length)),
    ...data,
  ];
  while (tail.length % 32 != 0) {
    tail.add(0);
  }

  return Uint8List.fromList([...head, ...tail]);
}

Uint8List _abiEncodeBytes(Uint8List data) {
  final head = _uint256ToBytes(BigInt.from(0x20)); // offset to bytes
  final tail = <int>[
    ..._uint256ToBytes(BigInt.from(data.length)),
    ...data,
  ];
  while (tail.length % 32 != 0) {
    tail.add(0);
  }
  return Uint8List.fromList([...head, ...tail]);
}

List<int> _addressToBytes(String addr) {
  final hex = addr.startsWith('0x') ? addr.substring(2) : addr;
  return [
    for (var i = 0; i < 20; i++)
      int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
  ];
}

List<int> _addressToBytesPadded(String addr) {
  final b = _addressToBytes(addr);
  return List.filled(12, 0) + b; // 32 bytes total
}

List<int> _uint256ToBytes(BigInt n) {
  final hex = n.toRadixString(16).padLeft(64, '0');
  if (hex.length > 64) {
    return List.filled(32, 0);
  }
  return [
    for (var i = 0; i < 32; i++)
      int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
  ];
}

Uint8List _hexToBytes(String hex) {
  final s = hex.startsWith('0x') ? hex.substring(2) : hex;
  if (s.isEmpty) return Uint8List(0);
  return Uint8List.fromList([
    for (var i = 0; i < s.length; i += 2)
      int.parse(s.substring(i, i + 2), radix: 16),
  ]);
}

String _bytesToHex(Uint8List b) {
  return b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
}
