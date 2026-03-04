import 'package:test/test.dart';
import 'package:wdk_safe_relay_kit_flutter/src/deployments/safe_4337_deployments.dart';

/// Expected v0.3.0 addresses from safe-modules-deployments
/// (mainnet and Sepolia).
const String expectedModuleV030 = '0x75cf11467937ce3F2f357CE24ffc3DBF8fD5c226';
const String expectedSetupV030 = '0x2dd68b007B46fBe91B9A7c3EDa5A7a1063cB5b47';

void main() {
  group('safe4337Deployments', () {
    test('contains Ethereum mainnet (1) for 0.3.0', () {
      final byChain = safe4337Deployments[1];
      expect(byChain, isNotNull);
      final d = byChain!['0.3.0'];
      expect(d, isNotNull);
      expect(d!.safe4337ModuleAddress, expectedModuleV030);
      expect(d.safeModulesSetupAddress, expectedSetupV030);
    });

    test('contains Sepolia (11155111) for 0.3.0', () {
      final byChain = safe4337Deployments[11155111];
      expect(byChain, isNotNull);
      final d = byChain!['0.3.0'];
      expect(d, isNotNull);
      expect(d!.safe4337ModuleAddress, expectedModuleV030);
      expect(d.safeModulesSetupAddress, expectedSetupV030);
    });

    test('Safe4337Deployment has non-empty addresses', () {
      final d = safe4337Deployments[1]!['0.3.0']!;
      expect(d.safe4337ModuleAddress.length, 42);
      expect(d.safe4337ModuleAddress.startsWith('0x'), isTrue);
      expect(d.safeModulesSetupAddress.length, 42);
      expect(d.safeModulesSetupAddress.startsWith('0x'), isTrue);
    });
  });
}
