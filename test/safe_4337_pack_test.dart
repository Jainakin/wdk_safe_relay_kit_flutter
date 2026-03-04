import 'package:test/test.dart';
import 'package:wdk_safe_relay_kit_flutter/wdk_safe_relay_kit.dart';

/// Mock signer for testing signSafeOperation.
class _MockSafe4337Signer implements Safe4337Signer {
  _MockSafe4337Signer({
    this.address = '0x0000000000000000000000000000000000000001',
  });
  @override
  final String address;
  @override
  Future<String> signOperationHash(String operationHashHex) async =>
      '0xmock_sig_$operationHashHex';
}

void main() {
  group('Safe4337Pack', () {
    test('predictSafeAddress returns 42-char hex', () async {
      final addr = await Safe4337Pack.predictSafeAddress(
        owners: ['0x636e9c21f27d9401ac180666bf8DC0D3FcEb0D24'],
        threshold: 1,
        chainId: 1,
      );
      expect(addr.startsWith('0x'), isTrue);
      expect(addr.length, 42);
    });

    test('predictSafeAddress throws for unsupported chain', () async {
      await expectLater(
        Safe4337Pack.predictSafeAddress(
          owners: ['0x636e9c21f27d9401ac180666bf8DC0D3FcEb0D24'],
          threshold: 1,
          chainId: 99999,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('signSafeOperation adds signature when signer and hash provided',
        () async {
      final pack = await Safe4337Pack.init(
        const Safe4337InitOptions(
          provider: null,
          bundlerUrl: 'https://bundler.example.com',
          options: ExistingSafeOptions(
            safeAddress: '0x0000000000000000000000000000000000000001',
          ),
          customContracts: CustomContracts(
            entryPointAddress: defaultEntryPointV07,
          ),
        ),
      );
      final safeOp = SafeOperation(
        transactions: [],
        userOperation: UserOperation(
          sender: pack.safeAddress,
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
      const owner = '0xAbC0000000000000000000000000000000000001';
      final signed = await pack.signSafeOperation(
        safeOp,
        signer: _MockSafe4337Signer(address: owner),
        operationHashHex: '0xhash123',
      );
      expect(signed.signatures[owner.toLowerCase()], '0xmock_sig_0xhash123');
    });

    test('signSafeOperation returns unchanged when operationHashHex empty',
        () async {
      final pack = await Safe4337Pack.init(
        const Safe4337InitOptions(
          provider: null,
          bundlerUrl: 'https://bundler.example.com',
          options: ExistingSafeOptions(
            safeAddress: '0x0000000000000000000000000000000000000001',
          ),
          customContracts: CustomContracts(
            entryPointAddress: defaultEntryPointV07,
          ),
        ),
      );
      final safeOp = SafeOperation(
        transactions: [],
        userOperation: UserOperation(
          sender: pack.safeAddress,
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
      final signed = await pack.signSafeOperation(
        safeOp,
        signer: _MockSafe4337Signer(),
        operationHashHex: '',
      );
      expect(signed.signatures, isEmpty);
    });
  });
}
