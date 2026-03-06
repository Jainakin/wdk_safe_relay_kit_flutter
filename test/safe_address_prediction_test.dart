import 'package:test/test.dart';
import 'package:wdk_safe_relay_kit_flutter/wdk_safe_relay_kit.dart';

void main() {
  test('predictSafeAddress returns valid hex address', () async {
    final addr = await predictSafeAddress(
      owners: ['0x636e9c21f27d9401ac180666bf8DC0D3FcEb0D24'],
      threshold: 1,
      chainId: 1,
      safeVersion: '1.4.1',
      safeModulesVersion: '0.3.0',
    );
    expect(addr.startsWith('0x'), isTrue);
    expect(addr.length, 42);
  });

  test('predictSafeAddress is deterministic for same inputs', () async {
    const owners = ['0x636e9c21f27d9401ac180666bf8DC0D3FcEb0D24'];
    final a = await predictSafeAddress(
      owners: owners,
      threshold: 1,
      chainId: 1,
      safeVersion: '1.4.1',
      safeModulesVersion: '0.3.0',
      saltNonce: '0x0',
    );
    final b = await predictSafeAddress(
      owners: owners,
      threshold: 1,
      chainId: 1,
      safeVersion: '1.4.1',
      safeModulesVersion: '0.3.0',
      saltNonce: '0x0',
    );
    expect(a, b);
  });

  test('predictSafeAddress throws for unsupported chainId', () async {
    expect(
      () => predictSafeAddress(
        owners: ['0x636e9c21f27d9401ac180666bf8DC0D3FcEb0D24'],
        threshold: 1,
        chainId: 99999,
        safeVersion: '1.4.1',
        safeModulesVersion: '0.3.0',
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('predictSafeAddress vector: fixed inputs yield known-good address',
      () async {
    const owners = ['0x636e9c21f27d9401ac180666bf8DC0D3FcEb0D24'];
    const saltNonce = '0x0';
    const chainId = 1;
    const safeVersion = '1.4.1';
    const safeModulesVersion = '0.3.0';
    const knownGoodAddress = '0x0154d1ae2b280847fbdc4c56784e297f8f728712';
    final addr = await predictSafeAddress(
      owners: owners,
      threshold: 1,
      chainId: chainId,
      safeVersion: safeVersion,
      safeModulesVersion: safeModulesVersion,
      saltNonce: saltNonce,
    );
    expect(addr, knownGoodAddress);
  });
}
