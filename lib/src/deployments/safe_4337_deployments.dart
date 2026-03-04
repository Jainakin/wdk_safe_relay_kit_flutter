/// Safe 4337 module and SafeModuleSetup deployment addresses per chain.
///
/// Source: [safe-modules-deployments](https://github.com/safe-global/safe-modules-deployments).
/// Keys: chainId (int). Sub-keys: safeModulesVersion (e.g. '0.3.0').
///
/// To support a new chain or module version, add an entry to
/// [safe4337Deployments] with the Safe4337Module and SafeModuleSetup
/// addresses from safe-modules-deployments assets (e.g.
/// `src/assets/safe-4337-module/v0.3.0/safe-4337-module.json` and
/// `safe-module-setup.json`). Address prediction throws [ArgumentError]
/// when no deployment exists for the given chainId and safeModulesVersion.
final Map<int, Map<String, Safe4337Deployment>> safe4337Deployments = {
  // Ethereum mainnet (chainId 1)
  1: {
    '0.3.0': const Safe4337Deployment(
      safe4337ModuleAddress: '0x75cf11467937ce3F2f357CE24ffc3DBF8fD5c226',
      safeModulesSetupAddress: '0x2dd68b007B46fBe91B9A7c3EDa5A7a1063cB5b47',
    ),
  },
  // Sepolia testnet (chainId 11155111)
  11155111: {
    '0.3.0': const Safe4337Deployment(
      safe4337ModuleAddress: '0x75cf11467937ce3F2f357CE24ffc3DBF8fD5c226',
      safeModulesSetupAddress: '0x2dd68b007B46fBe91B9A7c3EDa5A7a1063cB5b47',
    ),
  },
};

/// Deployment addresses for a given chain and safeModulesVersion.
class Safe4337Deployment {
  const Safe4337Deployment({
    required this.safe4337ModuleAddress,
    required this.safeModulesSetupAddress,
  });

  /// Safe4337Module contract address.
  final String safe4337ModuleAddress;

  /// SafeModuleSetup (AddModulesLib) contract address.
  final String safeModulesSetupAddress;
}
