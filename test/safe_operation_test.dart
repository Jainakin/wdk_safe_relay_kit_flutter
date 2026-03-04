import 'package:test/test.dart';
import 'package:wdk_safe_relay_kit_flutter/wdk_safe_relay_kit.dart';

void main() {
  group('SafeOperation', () {
    late SafeOperation op;

    setUp(() {
      op = SafeOperation(
        transactions: [],
        userOperation: UserOperation(
          sender: '0x0000000000000000000000000000000000000001',
          nonce: BigInt.zero,
          initCode: '0x',
          callData: '0x',
          callGasLimit: BigInt.zero,
          verificationGasLimit: BigInt.zero,
          preVerificationGas: BigInt.zero,
          maxFeePerGas: BigInt.zero,
          maxPriorityFeePerGas: BigInt.zero,
          paymasterAndData: '0x',
          signature: '0x',
        ),
      );
    });

    test('addSignature stores signature under lowercased owner address', () {
      expect(op.signatures, isEmpty);
      op.addSignature('0xABC0000000000000000000000000000000000001', '0xdead');
      expect(
        op.signatures['0xabc0000000000000000000000000000000000001'],
        '0xdead',
      );
      expect(op.signatures.length, 1);
    });

    test('addSignature overwrites same owner', () {
      op
        ..addSignature('0xowner1', '0xsig1')
        ..addSignature('0xOWNER1', '0xsig2');
      expect(op.signatures['0xowner1'], '0xsig2');
      expect(op.signatures.length, 1);
    });
  });
}
