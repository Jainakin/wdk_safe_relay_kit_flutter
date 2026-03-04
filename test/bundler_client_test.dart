import 'package:test/test.dart';
import 'package:wdk_safe_relay_kit_flutter/wdk_safe_relay_kit.dart';

void main() {
  group('BundlerClient', () {
    test('userOp to params and back', () {
      final op = UserOperation(
        sender: '0x1234',
        nonce: BigInt.zero,
        initCode: '0x',
        callData: '0x',
        callGasLimit: BigInt.from(100000),
        verificationGasLimit: BigInt.from(150000),
        preVerificationGas: BigInt.from(21000),
        maxFeePerGas: BigInt.from(100000000000),
        maxPriorityFeePerGas: BigInt.from(1000000000),
        paymasterAndData: '0x',
        signature: '0x',
      );
      expect(op.sender, '0x1234');
      expect(op.nonce, BigInt.zero);
    });
  });
}
