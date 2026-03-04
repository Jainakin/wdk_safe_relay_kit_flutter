import 'package:wdk_safe_relay_kit_flutter/src/types/paymaster_options.dart';

/// Options for an existing deployed Safe.
class ExistingSafeOptions {
  const ExistingSafeOptions({required this.safeAddress});
  final String safeAddress;
}

/// Options for a predicted (not yet deployed) Safe.
class PredictedSafeOptions {
  const PredictedSafeOptions({
    required this.owners,
    required this.threshold,
    this.safeVersion = '1.4.1',
    this.saltNonce,
  });

  final List<String> owners;
  final int threshold;
  final String safeVersion;
  final String? saltNonce;
}

/// Custom contract addresses (override defaults).
class CustomContracts {
  const CustomContracts({
    this.entryPointAddress,
    this.safe4337ModuleAddress,
    this.safeModulesSetupAddress,
  });

  final String? entryPointAddress;
  final String? safe4337ModuleAddress;
  final String? safeModulesSetupAddress;
}

/// Init options for Safe4337Pack.init.
class Safe4337InitOptions {
  const Safe4337InitOptions({
    required this.provider,
    required this.bundlerUrl,
    required this.options,
    this.signer,
    this.safeModulesVersion = '0.3.0',
    this.customContracts,
    this.paymasterOptions,
  });

  /// RPC provider (e.g. Web3Client or custom client).
  final dynamic provider;

  /// Bundler service URL.
  final String bundlerUrl;

  /// Either ExistingSafeOptions or PredictedSafeOptions.
  final Object options;

  /// Optional signer (owner) for signing operations.
  final dynamic signer;

  /// Safe modules version (e.g. 0.3.0 for EntryPoint v0.7).
  final String safeModulesVersion;

  final CustomContracts? customContracts;
  final PaymasterOptions? paymasterOptions;
}
