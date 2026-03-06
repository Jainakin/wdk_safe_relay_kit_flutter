import 'package:test/test.dart';
import 'package:wdk_safe_relay_kit_flutter/wdk_safe_relay_kit.dart';

class _FakeBundlerClient extends BundlerClient {
  _FakeBundlerClient()
      : super(
          bundlerUrl: 'https://bundler.test',
        );

  @override
  Future<Map<String, BigInt>> estimateUserOperationGas({
    required UserOperation userOperation,
    required String entryPoint,
  }) async {
    return {
      'callGasLimit': BigInt.from(111),
      'verificationGasLimit': BigInt.from(222),
      'preVerificationGas': BigInt.from(333),
    };
  }
}

void main() {
  group('GenericFeeEstimator', () {
    test('preEstimate returns context userOperation unchanged', () async {
      final est = GenericFeeEstimator(null, '0x1');
      final uo = UserOperation(
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
      );
      final result = await est.preEstimateUserOperationGas(
        EstimateFeeContext(
          userOperation: uo,
          bundlerUrl: 'https://bundler.test',
          entryPoint: '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789',
        ),
      );
      expect(result, uo);
    });
  });

  group('PimlicoFeeEstimator', () {
    test('preEstimate returns context userOperation unchanged', () async {
      final est = PimlicoFeeEstimator(null, '0x1');
      final uo = UserOperation(
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
      );
      final context = EstimateFeeContext(
        userOperation: uo,
        bundlerUrl: 'https://bundler.test',
        entryPoint: '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789',
      );
      expect(await est.preEstimateUserOperationGas(context), uo);
    });

    test('postEstimate delegates to GenericFeeEstimator and updates gas',
        () async {
      final est = PimlicoFeeEstimator(null, '0x1');
      final uo = UserOperation(
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
      );
      final context = EstimateFeeContext(
        userOperation: uo,
        bundlerUrl: 'https://bundler.test',
        entryPoint: '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789',
        bundlerClient: _FakeBundlerClient(),
      );
      final updated = await est.postEstimateUserOperationGas(context);
      expect(updated.callGasLimit, BigInt.from(111));
      expect(updated.verificationGasLimit, BigInt.from(222));
      expect(updated.preVerificationGas, BigInt.from(333));
    });
  });
}
