import 'package:wdk_safe_relay_kit_flutter/src/bundler_client.dart';
import 'package:wdk_safe_relay_kit_flutter/src/constants.dart';
import 'package:wdk_safe_relay_kit_flutter/src/encoding/call_data_encoder.dart';
import 'package:wdk_safe_relay_kit_flutter/src/estimators/ifee_estimator.dart';
import 'package:wdk_safe_relay_kit_flutter/src/paymaster_client.dart';
import 'package:wdk_safe_relay_kit_flutter/src/safe_address_prediction.dart'
    as safe_address_prediction;
import 'package:wdk_safe_relay_kit_flutter/src/safe_operation.dart';
import 'package:wdk_safe_relay_kit_flutter/src/signing/safe_4337_signer.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/create_transaction_options.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/init_options.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/meta_transaction_data.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation_receipt.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation_with_payload.dart';

/// Safe ERC-4337 pack: create, sign, execute UserOperations for Safe accounts.
class Safe4337Pack {
  Safe4337Pack._({
    required this.bundlerClient,
    required this.entryPointAddress,
    required this.safeAddress,
    this.paymasterClient,
    this.signer,
    this.chainId,
  });

  final BundlerClient bundlerClient;
  final String entryPointAddress;
  final String safeAddress;
  final PaymasterClient? paymasterClient;
  dynamic signer;
  final int? chainId;

  /// Predicts the Safe proxy address (static).
  static Future<String> predictSafeAddress({
    required List<String> owners,
    required int threshold,
    required int chainId,
    String safeVersion = '1.4.1',
    String safeModulesVersion = '0.3.0',
    String? saltNonce,
  }) async {
    return safe_address_prediction.predictSafeAddress(
      owners: owners,
      threshold: threshold,
      chainId: chainId,
      safeVersion: safeVersion,
      safeModulesVersion: safeModulesVersion,
      saltNonce: saltNonce,
    );
  }

  /// Creates a [Safe4337Pack] instance (async init).
  static Future<Safe4337Pack> init(Safe4337InitOptions options) async {
    final bundlerUrl = options.bundlerUrl;
    final bundler = BundlerClient(bundlerUrl: bundlerUrl);

    var entryPoint =
        options.customContracts?.entryPointAddress ?? defaultEntryPointV07;
    if (options.customContracts?.entryPointAddress == null) {
      final supported = await bundler.getSupportedEntryPoints();
      if (supported.isNotEmpty) entryPoint = supported.first;
    }

    String safeAddr;
    if (options.options is ExistingSafeOptions) {
      safeAddr = (options.options as ExistingSafeOptions).safeAddress;
    } else {
      final pred = options.options as PredictedSafeOptions;
      safeAddr = await safe_address_prediction.predictSafeAddress(
        owners: pred.owners,
        threshold: pred.threshold,
        chainId: _chainIdFromProvider(options.provider),
        safeVersion: pred.safeVersion,
        safeModulesVersion: options.safeModulesVersion,
        saltNonce: pred.saltNonce,
      );
    }

    PaymasterClient? pm;
    if (options.paymasterOptions != null) {
      pm = PaymasterClient(
        paymasterUrl: options.paymasterOptions!.paymasterUrl,
        paymasterAddress: options.paymasterOptions!.paymasterAddress,
        paymasterTokenAddress: options.paymasterOptions!.paymasterTokenAddress,
      );
    }

    return Safe4337Pack._(
      bundlerClient: bundler,
      entryPointAddress: entryPoint,
      safeAddress: safeAddr,
      paymasterClient: pm,
      signer: options.signer,
      chainId: _chainIdFromProvider(options.provider),
    );
  }

  static int _chainIdFromProvider(dynamic provider) {
    return 1;
  }

  /// Creates a SafeOperation from a batch of transactions.
  Future<SafeOperation> createTransaction({
    required List<MetaTransactionData> transactions,
    CreateTransactionOptions? options,
  }) async {
    options ??= const CreateTransactionOptions();
    final feeEstimator = options.feeEstimator;

    var userOp = UserOperation(
      sender: safeAddress,
      nonce: options.customNonce ?? BigInt.zero,
      initCode: '0x',
      callData: _encodeBatchCallData(transactions),
      callGasLimit: BigInt.from(100000),
      verificationGasLimit: BigInt.from(150000),
      preVerificationGas: BigInt.from(21000),
      maxFeePerGas: BigInt.from(100000000000),
      maxPriorityFeePerGas: BigInt.from(1000000000),
      paymasterAndData: '0x',
      signature: '0x',
    );

    if (feeEstimator != null) {
      userOp = await feeEstimator.preEstimateUserOperationGas(
        EstimateFeeContext(
          userOperation: userOp,
          bundlerUrl: bundlerClient.bundlerUrl,
          entryPoint: entryPointAddress,
        ),
      );
      final gas = await bundlerClient.estimateUserOperationGas(
        userOperation: userOp,
        entryPoint: entryPointAddress,
      );
      userOp = UserOperation(
        sender: userOp.sender,
        nonce: userOp.nonce,
        initCode: userOp.initCode,
        callData: userOp.callData,
        callGasLimit: gas['callGasLimit'] ?? userOp.callGasLimit,
        verificationGasLimit:
            gas['verificationGasLimit'] ?? userOp.verificationGasLimit,
        preVerificationGas:
            gas['preVerificationGas'] ?? userOp.preVerificationGas,
        maxFeePerGas: userOp.maxFeePerGas,
        maxPriorityFeePerGas: userOp.maxPriorityFeePerGas,
        paymasterAndData: userOp.paymasterAndData,
        signature: userOp.signature,
      );
      userOp = await feeEstimator.postEstimateUserOperationGas(
        EstimateFeeContext(
          userOperation: userOp,
          bundlerUrl: bundlerClient.bundlerUrl,
          entryPoint: entryPointAddress,
        ),
      );
    }

    return SafeOperation(transactions: transactions, userOperation: userOp);
  }

  String _encodeBatchCallData(List<MetaTransactionData> transactions) {
    return encodeSafe4337CallData(transactions);
  }

  /// Signs a SafeOperation (adds signer's signature).
  ///
  /// When [signer] implements [Safe4337Signer] and [operationHashHex] is
  /// provided, calls [Safe4337Signer.signOperationHash] and adds the result
  /// via [SafeOperation.addSignature]. The [operationHashHex] must be the
  /// value from the Safe 4337 module's `getOperationHash(userOp)` view (obtain
  /// via RPC).
  Future<SafeOperation> signSafeOperation(
    SafeOperation safeOperation, {
    dynamic signer,
    String? operationHashHex,
  }) async {
    final s = signer ?? this.signer;
    if (s == null) return safeOperation;
    if (operationHashHex == null || operationHashHex.isEmpty) {
      return safeOperation;
    }
    if (s is Safe4337Signer) {
      final sig = await s.signOperationHash(operationHashHex);
      safeOperation.addSignature(s.address, sig);
      return safeOperation;
    }
    return safeOperation;
  }

  /// Sends the signed SafeOperation to the bundler; returns userOpHash.
  Future<String> executeTransaction({required SafeOperation executable}) async {
    final hash = await bundlerClient.sendUserOperation(
      userOperation: executable.userOperation,
      entryPoint: entryPointAddress,
    );
    return hash;
  }

  /// Fetches UserOperation by hash.
  Future<UserOperationWithPayload?> getUserOperationByHash(String userOpHash) =>
      bundlerClient.getUserOperationByHash(userOpHash);

  /// Fetches UserOperation receipt by hash.
  Future<UserOperationReceipt?> getUserOperationReceipt(String userOpHash) =>
      bundlerClient.getUserOperationReceipt(userOpHash);

  /// Token (e.g. USDT) to wei exchange rate for paymaster.
  Future<BigInt> getTokenExchangeRate(String paymasterTokenAddress) async {
    if (paymasterClient == null) return BigInt.from(10).pow(18);
    return paymasterClient!.getTokenExchangeRate(paymasterTokenAddress);
  }

  /// Exposes a context so consumer can set signer
  /// (mirrors protocolKit.getSafeProvider().signer).
  // ignore: use_setters_to_change_properties - setter would shadow field
  void setSigner(dynamic s) {
    signer = s;
  }
}
