import 'package:wdk_safe_relay_kit_flutter/src/bundler_client.dart';
import 'package:wdk_safe_relay_kit_flutter/src/constants.dart';
import 'package:wdk_safe_relay_kit_flutter/src/encoding/call_data_encoder.dart';
import 'package:wdk_safe_relay_kit_flutter/src/encoding/signature_encoder.dart';
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
import 'package:web3dart/web3dart.dart' show Web3Client;

/// Safe ERC-4337 pack: create, sign, execute UserOperations for Safe accounts.
class Safe4337Pack {
  Safe4337Pack._({
    required this.bundlerClient,
    required this.entryPointAddress,
    required this.safeAddress,
    this.paymasterClient,
    this.signer,
    this.chainId,
    List<String>? owners,
    int? threshold,
  })  : _owners = owners,
        _threshold = threshold;

  final BundlerClient bundlerClient;
  final String entryPointAddress;
  final String safeAddress;
  final PaymasterClient? paymasterClient;
  dynamic signer;
  final int? chainId;

  /// Owners (ascending order) and threshold from init when using
  /// PredictedSafeOptions. Used to encode SafeOperation.signatures into
  /// UserOperation.signature.
  final List<String>? _owners;
  final int? _threshold;

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
    final bundler =
        options.bundlerClient ?? BundlerClient(bundlerUrl: bundlerUrl);

    var entryPoint =
        options.customContracts?.entryPointAddress ?? defaultEntryPointV07;
    if (options.customContracts?.entryPointAddress == null) {
      final supported = await bundler.getSupportedEntryPoints();
      if (supported.isNotEmpty) entryPoint = supported.first;
    }

    final resolvedChainId = await _chainIdFromProvider(options.provider);

    String safeAddr;
    if (options.options is ExistingSafeOptions) {
      safeAddr = (options.options as ExistingSafeOptions).safeAddress;
    } else {
      final pred = options.options as PredictedSafeOptions;
      safeAddr = await safe_address_prediction.predictSafeAddress(
        owners: pred.owners,
        threshold: pred.threshold,
        chainId: resolvedChainId,
        safeVersion: pred.safeVersion,
        safeModulesVersion: options.safeModulesVersion,
        saltNonce: pred.saltNonce,
      );
    }

    PaymasterClient? pm;
    if (options.paymasterOptions != null) {
      final po = options.paymasterOptions!;
      pm = PaymasterClient(
        paymasterUrl: po.paymasterUrl,
        paymasterAddress: po.paymasterAddress,
        paymasterTokenAddress: po.paymasterTokenAddress,
        isSponsored: po.isSponsored,
        sponsorshipPolicyId: po.sponsorshipPolicyId,
      );
    }

    List<String>? owners;
    int? threshold;
    if (options.options is PredictedSafeOptions) {
      final pred = options.options as PredictedSafeOptions;
      owners = List<String>.from(pred.owners)..sort(_addressCompare);
      threshold = pred.threshold;
    }

    return Safe4337Pack._(
      bundlerClient: bundler,
      entryPointAddress: entryPoint,
      safeAddress: safeAddr,
      paymasterClient: pm,
      signer: options.signer,
      chainId: resolvedChainId,
      owners: owners,
      threshold: threshold,
    );
  }

  static int _addressCompare(String a, String b) {
    final ah = a.toLowerCase().replaceFirst(RegExp('^0x'), '');
    final bh = b.toLowerCase().replaceFirst(RegExp('^0x'), '');
    return ah.compareTo(bh);
  }

  /// Resolves chain ID from provider (e.g. web3dart Web3Client.getChainId()).
  /// Returns 1 when provider is null or does not support getChainId.
  static Future<int> _chainIdFromProvider(dynamic provider) async {
    if (provider == null) return 1;
    try {
      if (provider is Web3Client) {
        final result = await provider.getChainId();
        return result.toInt();
      }
    } catch (_) {}
    return 1;
  }

  /// Creates a SafeOperation from a batch of transactions.
  Future<SafeOperation> createTransaction({
    required List<MetaTransactionData> transactions,
    CreateTransactionOptions? options,
  }) async {
    options ??= const CreateTransactionOptions();
    final feeEstimator = options.feeEstimator;

    final paymasterAndData = _buildPaymasterAndData(options);

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
      paymasterAndData: paymasterAndData,
      signature: '0x',
    );

    if (paymasterClient != null && paymasterClient!.isSponsored) {
      final pmData = await paymasterClient!.getPaymasterAndData(
        userOpParams: BundlerClient.userOpToParams(userOp),
        entryPoint: entryPointAddress,
        amountToApprove: options.amountToApprove,
        paymasterTokenAddress: options.paymasterTokenAddress ??
            paymasterClient!.paymasterTokenAddress,
      );
      userOp = UserOperation(
        sender: userOp.sender,
        nonce: userOp.nonce,
        initCode: userOp.initCode,
        callData: userOp.callData,
        callGasLimit: userOp.callGasLimit,
        verificationGasLimit: userOp.verificationGasLimit,
        preVerificationGas: userOp.preVerificationGas,
        maxFeePerGas: userOp.maxFeePerGas,
        maxPriorityFeePerGas: userOp.maxPriorityFeePerGas,
        paymasterAndData: pmData,
        signature: userOp.signature,
      );
    }

    if (feeEstimator != null) {
      final context = EstimateFeeContext(
        userOperation: userOp,
        bundlerUrl: bundlerClient.bundlerUrl,
        entryPoint: entryPointAddress,
        bundlerClient: bundlerClient,
      );
      userOp = await feeEstimator.preEstimateUserOperationGas(context);
      userOp = await feeEstimator.postEstimateUserOperationGas(context);
    }

    return SafeOperation(transactions: transactions, userOperation: userOp);
  }

  String _encodeBatchCallData(List<MetaTransactionData> transactions) {
    return encodeSafe4337CallData(transactions);
  }

  /// Builds paymasterAndData when pack has a paymaster and options
  /// provide validity.
  String _buildPaymasterAndData(CreateTransactionOptions options) {
    final pm = paymasterClient;
    if (pm == null || pm.paymasterAddress == null) return '0x';
    final addr = pm.paymasterAddress!;
    final validAfter = options.validAfter ?? 0;
    final validUntil = options.validUntil ?? 0;
    return _encodePaymasterAndData(
      addr,
      validAfter,
      validUntil,
      amountToApprove: options.amountToApprove,
      paymasterTokenAddress: options.paymasterTokenAddress,
    );
  }

  static String _encodePaymasterAndData(
    String paymasterAddress,
    int validAfter,
    int validUntil, {
    BigInt? amountToApprove,
    String? paymasterTokenAddress,
  }) {
    final hex =
        paymasterAddress.replaceFirst(RegExp('^0x'), '').padLeft(40, '0');
    final a = validAfter.toRadixString(16).padLeft(12, '0');
    final u = validUntil.toRadixString(16).padLeft(12, '0');
    var result = '0x$hex$a$u';
    if (paymasterTokenAddress != null && paymasterTokenAddress.isNotEmpty) {
      final tokenHex = paymasterTokenAddress
          .replaceFirst(RegExp('^0x'), '')
          .padLeft(40, '0');
      result = '$result$tokenHex';
    }
    if (amountToApprove != null) {
      result = '$result${amountToApprove.toRadixString(16).padLeft(64, '0')}';
    }
    return result;
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
  ///
  /// Encodes [SafeOperation.signatures] into [UserOperation.signature] using
  /// [owners] and [threshold]. When null, uses the pack's stored owners/threshold
  /// from init (PredictedSafeOptions). For an existing Safe, pass [owners] and
  /// [threshold] so signatures are encoded in the correct order.
  Future<String> executeTransaction({
    required SafeOperation executable,
    List<String>? owners,
    int? threshold,
    int validAfter = 0,
    int validUntil = 0,
  }) async {
    final uo = executable.userOperation;
    final sortedOwners = owners ?? _owners;
    final th = threshold ?? _threshold;

    var signature = uo.signature;
    if (executable.signatures.isNotEmpty &&
        sortedOwners != null &&
        sortedOwners.isNotEmpty &&
        th != null &&
        th > 0) {
      signature = encodeSafe4337Signature(
        validAfter: validAfter,
        validUntil: validUntil,
        sortedOwners: sortedOwners,
        signatures: executable.signatures,
      );
    }

    final userOp = UserOperation(
      sender: uo.sender,
      nonce: uo.nonce,
      initCode: uo.initCode,
      callData: uo.callData,
      callGasLimit: uo.callGasLimit,
      verificationGasLimit: uo.verificationGasLimit,
      preVerificationGas: uo.preVerificationGas,
      maxFeePerGas: uo.maxFeePerGas,
      maxPriorityFeePerGas: uo.maxPriorityFeePerGas,
      paymasterAndData: uo.paymasterAndData,
      signature: signature,
    );

    return bundlerClient.sendUserOperation(
      userOperation: userOp,
      entryPoint: entryPointAddress,
    );
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
  void setSigner(dynamic s) {
    if (identical(signer, s)) return;
    signer = s;
  }
}
