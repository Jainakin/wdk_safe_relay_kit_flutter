import 'dart:typed_data';

import 'package:pointycastle/digests/keccak.dart';
import 'package:wdk_safe_relay_kit_flutter/src/constants.dart';
import 'package:wdk_safe_relay_kit_flutter/src/deployments/safe_1_4_1_deployments.dart';
import 'package:wdk_safe_relay_kit_flutter/src/deployments/safe_4337_deployments.dart';
import 'package:wdk_safe_relay_kit_flutter/src/encoding/create2.dart';
import 'package:wdk_safe_relay_kit_flutter/src/encoding/safe_setup_initializer.dart';

/// Predicts the Safe proxy address for given owners, threshold, salt, chain.
///
/// Uses CREATE2 with Safe's proxy factory and singleton (Safe 1.4.1).
/// Initializer is Safe.setup(owners, threshold, ...). Salt is
/// keccak256(abi.encodePacked(keccak256(initializer), saltNonce)).
/// Throws [ArgumentError] if no deployment exists for [chainId] and
/// [safeModulesVersion] in [safe4337Deployments].
Future<String> predictSafeAddress({
  required List<String> owners,
  required int threshold,
  required int chainId,
  required String safeVersion,
  required String safeModulesVersion,
  String? saltNonce,
}) async {
  saltNonce ??= defaultSaltNonce;
  final deployment = safe4337Deployments[chainId]?[safeModulesVersion];
  if (deployment == null) {
    throw ArgumentError(
      'No Safe 4337 deployment for chainId=$chainId '
      'safeModulesVersion=$safeModulesVersion',
    );
  }

  final safe141 = safe141Deployments[chainId];
  if (safe141 == null) {
    throw ArgumentError(
      'No Safe 1.4.1 deployment for chainId=$chainId',
    );
  }

  final initializer = buildSafeSetupInitializer(
    owners: owners,
    threshold: threshold,
  );
  final initializerHash = KeccakDigest(256).process(initializer);

  final saltNonceBigInt = saltNonce.startsWith('0x')
      ? BigInt.parse(saltNonce.substring(2), radix: 16)
      : BigInt.tryParse(saltNonce) ?? BigInt.zero;
  final saltBytes = _keccak256(
    Uint8List.fromList([
      ...initializerHash,
      ..._uint256ToBytes(saltNonceBigInt),
    ]),
  );

  final proxyCode = _hexToBytes(safeProxyCreationCodeHex);
  final singletonPadded = _addressToBytes32(safe141.singletonAddress);
  final initCode = Uint8List.fromList([...proxyCode, ...singletonPadded]);
  final initCodeHash = Uint8List.fromList(KeccakDigest(256).process(initCode));

  return create2Address(
    factoryAddress: safe141.proxyFactoryAddress,
    salt: saltBytes,
    initCodeHash: initCodeHash,
  );
}

List<int> _uint256ToBytes(BigInt n) {
  final hex = n.toRadixString(16).padLeft(64, '0');
  if (hex.length > 64) return List.filled(32, 0);
  return [
    for (var i = 0; i < 32; i++)
      int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
  ];
}

List<int> _addressToBytes32(String addr) {
  final hex = addr.replaceFirst(RegExp('^0x'), '').padLeft(40, '0');
  return List.filled(12, 0) +
      [
        for (var i = 0; i < 20; i++)
          int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      ];
}

Uint8List _keccak256(Uint8List data) {
  return Uint8List.fromList(KeccakDigest(256).process(data));
}

List<int> _hexToBytes(String hex) {
  final s = hex.startsWith('0x') ? hex.substring(2) : hex;
  return [
    for (var i = 0; i < s.length; i += 2)
      int.parse(s.substring(i, i + 2), radix: 16),
  ];
}
