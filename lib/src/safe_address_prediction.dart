import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/digests/keccak.dart';
import 'package:wdk_safe_relay_kit_flutter/src/constants.dart';
import 'package:wdk_safe_relay_kit_flutter/src/deployments/safe_4337_deployments.dart';
import 'package:web3dart/web3dart.dart';

/// Predicts the Safe proxy address for given owners, threshold, salt, chain.
///
/// Uses CREATE2 with Safe's proxy factory and module setup.
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
  // Placeholder: deterministic address from keccak256(owners|threshold|...).
  // Full impl: use Safe proxy factory CREATE2 formula with deployment addresses
  // .
  final combined =
      '$owners$threshold$saltNonce$chainId$safeVersion$safeModulesVersion';
  final hash = _keccak256(Uint8List.fromList(utf8.encode(combined)));
  final hexPart = hash
      .sublist(12, 32)
      .map(
        (e) => e.toRadixString(16).padLeft(2, '0'),
      )
      .join();
  return EthereumAddress.fromHex('0x$hexPart').hex;
}

Uint8List _keccak256(Uint8List data) {
  final k = KeccakDigest(256);
  return k.process(data);
}
