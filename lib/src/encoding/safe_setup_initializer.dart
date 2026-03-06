import 'dart:typed_data';

import 'package:pointycastle/digests/keccak.dart';

/// Builds the initializer bytes for Safe.setup(owners, threshold, ...).
/// Used for CREATE2 salt: keccak256(initializer).
Uint8List buildSafeSetupInitializer({
  required List<String> owners,
  required int threshold,
}) {
  // setup(address[] _owners, uint256 _threshold, address to, bytes data,
  //       address fallbackHandler, address paymentToken, uint256 payment,
  //       address paymentReceiver)
  final selector = _selector(
    'setup(address[],uint256,address,bytes,address,address,uint256,address)',
  );
  final out = <int>[...selector];

  final ownersEncoded = _encodeAddressArray(owners);
  final offsetTo = 32 * 8 + ownersEncoded.length;
  final offsetData = offsetTo + 32;

  final head = <int>[
    ..._uint256ToBytes(BigInt.from(0x20)), // offset to _owners
    ..._uint256ToBytes(BigInt.from(threshold)),
    ..._uint256ToBytes(BigInt.from(offsetTo)),
    ..._uint256ToBytes(BigInt.from(offsetData)),
    ..._addressToBytesPadded('0x0000000000000000000000000000000000000000'),
    ..._addressToBytesPadded('0x0000000000000000000000000000000000000000'),
    ..._uint256ToBytes(BigInt.zero),
    ..._addressToBytesPadded('0x0000000000000000000000000000000000000000'),
  ];
  out
    ..addAll(head)
    ..addAll(ownersEncoded)
    ..addAll(
      _addressToBytesPadded(
        '0x0000000000000000000000000000000000000000',
      ),
    )
    ..addAll(_uint256ToBytes(BigInt.zero)); // data length 0
  while (out.length % 32 != 0) {
    out.add(0);
  }

  return Uint8List.fromList(out);
}

List<int> _encodeAddressArray(List<String> addresses) {
  final out = <int>[
    ..._uint256ToBytes(BigInt.from(addresses.length)),
  ];
  for (final a in addresses) {
    out.addAll(_addressToBytesPadded(a));
  }
  return out;
}

List<int> _addressToBytesPadded(String addr) {
  final hex = addr.replaceFirst(RegExp('^0x'), '').padLeft(40, '0');
  return List.filled(12, 0) +
      [
        for (var i = 0; i < 20; i++)
          int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      ];
}

List<int> _uint256ToBytes(BigInt n) {
  final hex = n.toRadixString(16).padLeft(64, '0');
  if (hex.length > 64) return List.filled(32, 0);
  return [
    for (var i = 0; i < 32; i++)
      int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
  ];
}

List<int> _selector(String signature) {
  final h = KeccakDigest(256).process(Uint8List.fromList(signature.codeUnits));
  return h.sublist(0, 4);
}
