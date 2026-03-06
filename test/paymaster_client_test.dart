import 'package:test/test.dart';
import 'package:wdk_safe_relay_kit_flutter/src/paymaster_client.dart';

void main() {
  group('PaymasterClient', () {
    test('getTokenExchangeRate returns 10^18 on failure or bad response',
        () async {
      final client = PaymasterClient(
        paymasterUrl: 'http://localhost:99999',
        paymasterAddress: '0x0000000000000000000000000000000000000001',
      );
      final rate = await client.getTokenExchangeRate(
        '0x0000000000000000000000000000000000000002',
      );
      expect(rate, BigInt.from(10).pow(18));
    });
  });
}
