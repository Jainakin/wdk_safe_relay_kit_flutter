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

/// Mock bundler client for testing createTransaction and executeTransaction
/// without HTTP.
class _MockBundlerClient extends BundlerClient {
  _MockBundlerClient({
    super.bundlerUrl = 'https://bundler.test',
    super.entryPointAddress,
  });

  UserOperation? lastSentUserOperation;
  String sendUserOpResult = '0xuserophash';

  @override
  Future<String> sendUserOperation({
    required UserOperation userOperation,
    required String entryPoint,
  }) async {
    lastSentUserOperation = userOperation;
    return sendUserOpResult;
  }

  @override
  Future<Map<String, BigInt>> estimateUserOperationGas({
    required UserOperation userOperation,
    required String entryPoint,
  }) async {
    return {
      'callGasLimit': BigInt.from(100000),
      'verificationGasLimit': BigInt.from(150000),
      'preVerificationGas': BigInt.from(21000),
    };
  }

  @override
  Future<List<String>> getSupportedEntryPoints() async =>
      [entryPointAddress ?? defaultEntryPointV07];
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

    test('createTransaction builds SafeOperation with callData from encoder',
        () async {
      // provider is null in tests to avoid real RPC.
      final pack = await Safe4337Pack.init(
        const Safe4337InitOptions(
          provider: null,
          bundlerUrl: 'https://bundler.test',
          options: ExistingSafeOptions(
            safeAddress: '0x0000000000000000000000000000000000000001',
          ),
          customContracts: CustomContracts(
            entryPointAddress: defaultEntryPointV07,
          ),
        ),
      );
      final op = await pack.createTransaction(
        transactions: [
          MetaTransactionData(
            from: pack.safeAddress,
            to: '0x0000000000000000000000000000000000000002',
            value: BigInt.zero,
          ),
        ],
      );
      expect(op.transactions.length, 1);
      expect(op.userOperation.sender, pack.safeAddress);
      expect(op.userOperation.callData, isNotEmpty);
      expect(op.userOperation.callData, startsWith('0x'));
    });

    test('createTransaction with fee estimator updates gas fields', () async {
      final mockBundler = _MockBundlerClient(
        entryPointAddress: defaultEntryPointV07,
      );
      final pack = await Safe4337Pack.init(
        Safe4337InitOptions(
          provider: null,
          bundlerUrl: 'https://bundler.test',
          options: const ExistingSafeOptions(
            safeAddress: '0x0000000000000000000000000000000000000001',
          ),
          customContracts: const CustomContracts(
            entryPointAddress: defaultEntryPointV07,
          ),
          bundlerClient: mockBundler,
        ),
      );
      final op = await pack.createTransaction(
        transactions: [
          MetaTransactionData(
            from: pack.safeAddress,
            to: '0x0000000000000000000000000000000000000002',
            value: BigInt.zero,
          ),
        ],
        options: CreateTransactionOptions(
          feeEstimator: GenericFeeEstimator(null, '0x1'),
        ),
      );
      expect(op.userOperation.callGasLimit, BigInt.from(100000));
      expect(op.userOperation.verificationGasLimit, BigInt.from(150000));
      expect(op.userOperation.preVerificationGas, BigInt.from(21000));
    });

    test('executeTransaction sends UserOperation with encoded signature',
        () async {
      final mockBundler = _MockBundlerClient(
        entryPointAddress: defaultEntryPointV07,
      );
      final pack = await Safe4337Pack.init(
        Safe4337InitOptions(
          provider: null,
          bundlerUrl: 'https://bundler.test',
          options: const PredictedSafeOptions(
            owners: ['0x0000000000000000000000000000000000000001'],
            threshold: 1,
          ),
          customContracts: const CustomContracts(
            entryPointAddress: defaultEntryPointV07,
          ),
          bundlerClient: mockBundler,
        ),
      );
      const owner = '0x0000000000000000000000000000000000000001';
      final sig65 = '0x${'a' * 130}';
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
      )..addSignature(owner, sig65);

      final hash = await pack.executeTransaction(executable: safeOp);

      expect(hash, mockBundler.sendUserOpResult);
      expect(mockBundler.lastSentUserOperation, isNotNull);
      final sent = mockBundler.lastSentUserOperation!;
      expect(sent.signature, startsWith('0x'));
      expect(
        sent.signature.length,
        greaterThan(14),
      ); // 0x + 12 bytes validAfter/validUntil + 65 bytes sig
    });

    test('executeTransaction without signatures sends UserOp as-is', () async {
      final mockBundler = _MockBundlerClient(
        entryPointAddress: defaultEntryPointV07,
      );
      final pack = await Safe4337Pack.init(
        Safe4337InitOptions(
          provider: null,
          bundlerUrl: 'https://bundler.test',
          options: const ExistingSafeOptions(
            safeAddress: '0x0000000000000000000000000000000000000001',
          ),
          customContracts: const CustomContracts(
            entryPointAddress: defaultEntryPointV07,
          ),
          bundlerClient: mockBundler,
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

      await pack.executeTransaction(executable: safeOp);

      expect(mockBundler.lastSentUserOperation!.signature, '0x');
    });
  });
}
