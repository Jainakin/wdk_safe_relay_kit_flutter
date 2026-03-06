import 'dart:typed_data';

import 'package:pointycastle/digests/keccak.dart';

/// CREATE2 address: last 20 bytes of
/// keccak256(0xff ++ factory ++ salt ++ keccak256(initCode)).
String create2Address({
  required String factoryAddress,
  required Uint8List salt,
  required Uint8List initCodeHash,
}) {
  final factory = _addressToBytes(factoryAddress);
  if (salt.length != 32) {
    throw ArgumentError('salt must be 32 bytes');
  }
  if (initCodeHash.length != 32) {
    throw ArgumentError('initCodeHash must be 32 bytes');
  }

  final payload = Uint8List.fromList([
    0xff,
    ...factory,
    ...salt,
    ...initCodeHash,
  ]);
  final hash = KeccakDigest(256).process(payload);
  final addrBytes = hash.sublist(12, 32);
  final hex = addrBytes
      .map((e) => e.toRadixString(16).padLeft(2, '0'))
      .join();
  return '0x$hex';
}

List<int> _addressToBytes(String addr) {
  final hex = addr.startsWith('0x') ? addr.substring(2) : addr;
  return [
    for (var i = 0; i < 20; i++)
      int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
  ];
}
