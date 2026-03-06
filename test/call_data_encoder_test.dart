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

    test('single tx golden: deterministic hex output', () {
      final single = MetaTransactionData(
        from: '0x0000000000000000000000000000000000000001',
        to: '0x0000000000000000000000000000000000000002',
        value: BigInt.zero,
        data: '0x',
      );
      final calldata = encodeSafe4337CallData([single]);
      expect(calldata, startsWith('0x'));
      expect(calldata.substring(2), matches(RegExp(r'^[0-9a-f]+$')));
      expect(encodeSafe4337CallData([single]), calldata);
    });

    test('single tx byte-exact golden', () {
      final single = MetaTransactionData(
        from: '0x0000000000000000000000000000000000000001',
        to: '0x0000000000000000000000000000000000000002',
        value: BigInt.zero,
        data: '0x',
      );
      const expected = '''
0x7bb3742800000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000''';
      expect(encodeSafe4337CallData([single]), expected);
    });

    test('batch of two byte-exact golden', () {
      final batch = [
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
      const expected = '''
0x7bb3742800000000000000000000000040a2accbd92bca938b02010e17a5b8929b49130d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001048d80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000ac00000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000000021234000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000''';
      expect(encodeSafe4337CallData(batch), expected);
    });
  });
}
