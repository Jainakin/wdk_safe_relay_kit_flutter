import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation_receipt.dart';
import 'package:wdk_safe_relay_kit_flutter/src/types/user_operation_with_payload.dart';

/// Type for injecting HTTP POST in tests (e.g. mock responses).
typedef BundlerHttpPost = Future<http.Response> Function(
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
});

/// Client for ERC-4337 bundler JSON-RPC (eth_sendUserOperation, etc.).
/// Serialization uses the common UserOperation shape; add EntryPoint v0.7
/// fields (e.g. aggregator) to [userOpToParams] when required.
class BundlerClient {
  BundlerClient({
    required this.bundlerUrl,
    this.entryPointAddress,
    this.httpPost,
  });

  final String bundlerUrl;
  final String? entryPointAddress;

  /// Optional HTTP POST; when null, uses [http.post]. Set in tests to mock.
  final BundlerHttpPost? httpPost;

  /// Sends a UserOperation to the bundler.
  /// Returns the userOpHash.
  Future<String> sendUserOperation({
    required UserOperation userOperation,
    required String entryPoint,
  }) async {
    final result = await _rpc('eth_sendUserOperation', [
      _userOpToParams(userOperation),
      entryPoint,
    ]);
    return result as String;
  }

  /// Estimates gas for a UserOperation.
  /// Returns a map with callGasLimit, verificationGasLimit, preVerificationGas.
  Future<Map<String, BigInt>> estimateUserOperationGas({
    required UserOperation userOperation,
    required String entryPoint,
  }) async {
    final result = await _rpc('eth_estimateUserOperationGas', [
      _userOpToParams(userOperation),
      entryPoint,
    ]);
    final map = result as Map<String, dynamic>;
    return {
      'callGasLimit': _toBigInt(map['callGasLimit']),
      'verificationGasLimit': _toBigInt(map['verificationGasLimit']),
      'preVerificationGas': _toBigInt(map['preVerificationGas']),
    };
  }

  /// Returns supported entry points from the bundler.
  Future<List<String>> getSupportedEntryPoints() async {
    final result = await _rpc('eth_supportedEntryPoints', []);
    return (result as List).cast<String>();
  }

  /// Fetches UserOperation by hash.
  Future<UserOperationWithPayload?> getUserOperationByHash(
    String userOpHash,
  ) async {
    final result = await _rpc('eth_getUserOperationByHash', [userOpHash]);
    if (result == null) return null;
    final map = result as Map<String, dynamic>;
    return UserOperationWithPayload(
      userOperation: _paramsToUserOp(
        map['userOperation'] as Map<String, dynamic>,
      ),
      entryPoint: map['entryPoint'] as String,
      transactionHash: map['transactionHash'] as String,
      blockHash: map['blockHash'] as String,
      blockNumber: map['blockNumber'] as String,
    );
  }

  /// Fetches UserOperation receipt by hash.
  Future<UserOperationReceipt?> getUserOperationReceipt(
    String userOpHash,
  ) async {
    final result = await _rpc('eth_getUserOperationReceipt', [userOpHash]);
    if (result == null) return null;
    final map = result as Map<String, dynamic>;
    return UserOperationReceipt(
      userOpHash: map['userOpHash'] as String,
      sender: map['sender'] as String,
      nonce: map['nonce'] as String,
      actualGasUsed: map['actualGasUsed'] as String,
      actualGasCost: map['actualGasCost'] as String,
      success: map['success'] as bool,
      logs: (map['logs'] as List).cast<Map<String, dynamic>>(),
      receipt: map['receipt'] as Map<String, dynamic>,
    );
  }

  Future<dynamic> _rpc(String method, List<dynamic> params) async {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': 1,
      'method': method,
      'params': params,
    });
    final post = httpPost ?? http.post;
    final response = await post(
      Uri.parse(bundlerUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode != 200) {
      throw BundlerRpcException(
        'Bundler RPC error: ${response.statusCode} ${response.body}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.containsKey('error')) {
      final err = data['error'];
      final msg = err is Map
          ? (err['message']?.toString() ?? 'Unknown')
          : err.toString();
      throw BundlerRpcException(msg);
    }
    return data['result'];
  }

  /// Serializes [UserOperation] to JSON-RPC params
  /// (e.g. for paymaster or bundler).
  static Map<String, dynamic> userOpToParams(UserOperation op) {
    return _userOpToParams(op);
  }

  static Map<String, dynamic> _userOpToParams(UserOperation op) {
    return {
      'sender': op.sender,
      'nonce': _fromBigInt(op.nonce),
      'initCode': op.initCode,
      'callData': op.callData,
      'callGasLimit': _fromBigInt(op.callGasLimit),
      'verificationGasLimit': _fromBigInt(op.verificationGasLimit),
      'preVerificationGas': _fromBigInt(op.preVerificationGas),
      'maxFeePerGas': _fromBigInt(op.maxFeePerGas),
      'maxPriorityFeePerGas': _fromBigInt(op.maxPriorityFeePerGas),
      'paymasterAndData': op.paymasterAndData,
      'signature': op.signature,
    };
  }

  static UserOperation _paramsToUserOp(Map<String, dynamic> m) {
    return UserOperation(
      sender: m['sender'] as String,
      nonce: _toBigInt(m['nonce']),
      initCode: m['initCode'] as String,
      callData: m['callData'] as String,
      callGasLimit: _toBigInt(m['callGasLimit']),
      verificationGasLimit: _toBigInt(m['verificationGasLimit']),
      preVerificationGas: _toBigInt(m['preVerificationGas']),
      maxFeePerGas: _toBigInt(m['maxFeePerGas']),
      maxPriorityFeePerGas: _toBigInt(m['maxPriorityFeePerGas']),
      paymasterAndData: m['paymasterAndData'] as String,
      signature: m['signature'] as String,
    );
  }

  static String _fromBigInt(BigInt n) {
    return '0x${n.toRadixString(16)}';
  }

  static BigInt _toBigInt(dynamic v) {
    if (v == null) return BigInt.zero;
    if (v is BigInt) return v;
    final s = v.toString();
    if (s.startsWith('0x')) return BigInt.parse(s.substring(2), radix: 16);
    return BigInt.tryParse(s) ?? BigInt.zero;
  }
}

class BundlerRpcException implements Exception {
  BundlerRpcException(this.message);
  final String message;
  @override
  String toString() => 'BundlerRpcException: $message';
}
