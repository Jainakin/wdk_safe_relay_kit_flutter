import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:wdk_safe_relay_kit_flutter/wdk_safe_relay_kit.dart';

void main() {
  final sampleUserOp = UserOperation(
    sender: '0x1234567890123456789012345678901234567890',
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
  const entryPoint = '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789';

  group('BundlerClient', () {
    test('userOp to params and back', () {
      expect(sampleUserOp.sender, '0x1234567890123456789012345678901234567890');
      expect(sampleUserOp.nonce, BigInt.zero);
    });

    test('sendUserOperation stubs HTTP and returns userOpHash', () async {
      String? capturedBody;
      final client = BundlerClient(
        bundlerUrl: 'https://bundler.example.com',
        httpPost: (
          Uri uri, {
          Map<String, String>? headers,
          Object? body,
        }) async {
          if (body is! String) {
            throw StateError('Expected String body');
          }
          capturedBody = body;
          return http.Response(
            jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0xuserophash'}),
            200,
          );
        },
      );
      final hash = await client.sendUserOperation(
        userOperation: sampleUserOp,
        entryPoint: entryPoint,
      );
      expect(hash, '0xuserophash');
      final req = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(req['method'], 'eth_sendUserOperation');
      final params = req['params'] as List;
      expect(params.length, 2);
      expect(params[1], entryPoint);
      expect((params[0] as Map)['sender'], sampleUserOp.sender);
    });

    test('estimateUserOperationGas stubs HTTP and returns gas map', () async {
      final client = BundlerClient(
        bundlerUrl: 'https://bundler.example.com',
        httpPost: (
          Uri uri, {
          Map<String, String>? headers,
          Object? body,
        }) async {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'result': {
                'callGasLimit': '0x186a0',
                'verificationGasLimit': '0x249f0',
                'preVerificationGas': '0x5208',
              },
            }),
            200,
          );
        },
      );
      final gas = await client.estimateUserOperationGas(
        userOperation: sampleUserOp,
        entryPoint: entryPoint,
      );
      expect(gas['callGasLimit'], BigInt.from(100000));
      expect(gas['verificationGasLimit'], BigInt.from(150000));
      expect(gas['preVerificationGas'], BigInt.from(21000));
    });

    test('getSupportedEntryPoints stubs HTTP and returns list', () async {
      final client = BundlerClient(
        bundlerUrl: 'https://bundler.example.com',
        httpPost: (
          Uri uri, {
          Map<String, String>? headers,
          Object? body,
        }) async {
          if (body is! String) {
            throw StateError('Expected String body');
          }
          final req = jsonDecode(body) as Map<String, dynamic>;
          expect(req['method'], 'eth_supportedEntryPoints');
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'result': [entryPoint],
            }),
            200,
          );
        },
      );
      final list = await client.getSupportedEntryPoints();
      expect(list, [entryPoint]);
    });

    test('getUserOperationByHash stubs HTTP and returns payload or null',
        () async {
      final client = BundlerClient(
        bundlerUrl: 'https://bundler.example.com',
        httpPost: (
          Uri uri, {
          Map<String, String>? headers,
          Object? body,
        }) async {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'result': {
                'userOperation': BundlerClient.userOpToParams(sampleUserOp),
                'entryPoint': entryPoint,
                'transactionHash': '0xtx',
                'blockHash': '0xblock',
                'blockNumber': '0x1',
              },
            }),
            200,
          );
        },
      );
      final payload = await client.getUserOperationByHash('0xhash');
      expect(payload, isNotNull);
      expect(payload!.userOperation.sender, sampleUserOp.sender);
      expect(payload.entryPoint, entryPoint);
      expect(payload.transactionHash, '0xtx');
    });

    test('getUserOperationByHash returns null when result is null', () async {
      final client = BundlerClient(
        bundlerUrl: 'https://bundler.example.com',
        httpPost: (
          Uri uri, {
          Map<String, String>? headers,
          Object? body,
        }) async {
          return http.Response(
            jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': null}),
            200,
          );
        },
      );
      final payload = await client.getUserOperationByHash('0xhash');
      expect(payload, isNull);
    });

    test('getUserOperationReceipt stubs HTTP and returns receipt', () async {
      final client = BundlerClient(
        bundlerUrl: 'https://bundler.example.com',
        httpPost: (
          Uri uri, {
          Map<String, String>? headers,
          Object? body,
        }) async {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'result': {
                'userOpHash': '0xhash',
                'sender': sampleUserOp.sender,
                'nonce': '0x0',
                'actualGasUsed': '0x5208',
                'actualGasCost': '0x0',
                'success': true,
                'logs': <Map<String, dynamic>>[],
                'receipt': <String, dynamic>{},
              },
            }),
            200,
          );
        },
      );
      final receipt = await client.getUserOperationReceipt('0xhash');
      expect(receipt, isNotNull);
      expect(receipt!.userOpHash, '0xhash');
      expect(receipt.success, true);
    });

    test('non-200 response throws BundlerRpcException', () async {
      final client = BundlerClient(
        bundlerUrl: 'https://bundler.example.com',
        httpPost: (
          Uri uri, {
          Map<String, String>? headers,
          Object? body,
        }) async {
          return http.Response('Bad Gateway', 502);
        },
      );
      expect(
        () => client.sendUserOperation(
          userOperation: sampleUserOp,
          entryPoint: entryPoint,
        ),
        throwsA(isA<BundlerRpcException>()),
      );
    });

    test('JSON-RPC error throws BundlerRpcException', () async {
      final client = BundlerClient(
        bundlerUrl: 'https://bundler.example.com',
        httpPost: (
          Uri uri, {
          Map<String, String>? headers,
          Object? body,
        }) async {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'error': {'code': -32602, 'message': 'invalid params'},
            }),
            200,
          );
        },
      );
      expect(
        client.getSupportedEntryPoints,
        throwsA(isA<BundlerRpcException>()),
      );
    });
  });
}
