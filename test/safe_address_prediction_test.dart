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
}
