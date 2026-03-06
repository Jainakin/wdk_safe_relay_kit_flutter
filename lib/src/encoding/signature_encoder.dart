// Encodes SafeOperation.signatures into UserOperation.signature for
// Safe4337Module.
//
// Safe4337Module expects:
// `abi.encodePacked(validAfter, validUntil, signatures)`, where
// validAfter/validUntil are uint48 (6 bytes each), and signatures are Safe's
// checkSignatures format: EOA signatures in ascending owner order, each 65
// bytes (r, s, v).

/// Encodes signatures for the Safe 4337 module UserOperation.signature field.
///
/// [validAfter] and [validUntil] are uint48 (6 bytes). Use 0 for validUntil to
/// mean "no expiry". [sortedOwners] must be the Safe owners in ascending
/// address order. [signatures] maps owner address (any case) to hex signature
/// (0x-prefixed, 65 bytes r,s,v or 64 bytes compact).
///
/// Returns 0x-prefixed hex: 6 bytes validAfter + 6 bytes validUntil + 65 bytes
/// per signer in [sortedOwners] order (only owners present in [signatures]).
String encodeSafe4337Signature({
  required List<String> sortedOwners,
  required Map<String, String> signatures,
  int validAfter = 0,
  int validUntil = 0,
}) {
  final out = <int>[
    ..._uint48ToBytes(validAfter),
    ..._uint48ToBytes(validUntil),
  ];

  // Signatures in ascending owner order; each EOA sig 65 bytes (r, s, v)
  final sigMap = <String, String>{};
  for (final e in signatures.entries) {
    sigMap[e.key.toLowerCase()] = e.value;
  }
  for (final owner in sortedOwners) {
    final sig = sigMap[owner.toLowerCase()];
    if (sig == null || sig.isEmpty) continue;
    out.addAll(_signatureTo65Bytes(sig));
  }

  final hex = out.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  return '0x$hex';
}

List<int> _uint48ToBytes(int n) {
  final hex = n.toRadixString(16).padLeft(12, '0');
  if (hex.length > 12) return List.filled(6, 0);
  return [
    for (var i = 0; i < 6; i++)
      int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
  ];
}

/// Normalize signature to 65 bytes (r, s, v). Handles 64-byte compact form.
List<int> _signatureTo65Bytes(String hexSig) {
  var hex = hexSig.startsWith('0x') ? hexSig.substring(2) : hexSig;
  hex = hex.replaceAll(' ', '');
  if (hex.length == 130) {
    return [
      for (var i = 0; i < 65; i++)
        int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    ];
  }
  if (hex.length == 128) {
    final r = hex.substring(0, 64);
    final s = hex.substring(64, 128);
    const v = 27; // default recovery id
    return [
      ...[
        for (var i = 0; i < 32; i++)
          int.parse(r.substring(i * 2, i * 2 + 2), radix: 16),
      ],
      ...[
        for (var i = 0; i < 32; i++)
          int.parse(s.substring(i * 2, i * 2 + 2), radix: 16),
      ],
      v,
    ];
  }
  throw ArgumentError(
    'Signature must be 64 or 65 bytes; got ${hex.length ~/ 2}',
  );
}
