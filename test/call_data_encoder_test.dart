import 'package:test/test.dart';
import 'package:wdk_safe_relay_kit_flutter/src/encoding/call_data_encoder.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/meta_transaction_data.dart';

void main() {
  group('encodeSafe4337CallData', () {
    test('returns 0x for empty list', () {
      expect(encodeSafe4337CallData([]), '0x');
    });

    test('single tx produces non-empty calldata with 0x prefix', () {
      final tx = MetaTransactionData(
        from: '0x0000000000000000000000000000000000000001',
        to: '0x0000000000000000000000000000000000000002',
        value: BigInt.zero,
        data: '0x',
      );
      final calldata = encodeSafe4337CallData([tx]);
      expect(calldata.startsWith('0x'), isTrue);
      expect(calldata.length, greaterThan(10));
    });

    test('batch of two txs produces non-empty calldata', () {
      final txs = [
        MetaTransactionData(
          from: '0x0000000000000000000000000000000000000001',
          to: '0x0000000000000000000000000000000000000002',
          value: BigInt.zero,
          data: '0x',
        ),
        MetaTransactionData(
          from: '0x0000000000000000000000000000000000000001',
          to: '0x0000000000000000000000000000000000000003',
          value: BigInt.from(100),
          data: '0x1234',
        ),
      ];
      final calldata = encodeSafe4337CallData(txs);
      expect(calldata.startsWith('0x'), isTrue);
      expect(calldata.length, greaterThan(10));
    });
  });
}
