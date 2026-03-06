import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client for paymaster service (sponsorship, token exchange rate).
class PaymasterClient {
  PaymasterClient({
    required this.paymasterUrl,
    this.paymasterAddress,
    this.paymasterTokenAddress,
    this.isSponsored = false,
    this.sponsorshipPolicyId,
  });

  final String paymasterUrl;
  final String? paymasterAddress;
  final String? paymasterTokenAddress;
  final bool isSponsored;
  final String? sponsorshipPolicyId;

  /// Returns full paymasterAndData hex from paymaster API
  /// (e.g. pm_getPaymasterData). Use when [isSponsored] is true or when using a
  /// provider that returns paymaster + paymasterData.
  Future<String> getPaymasterAndData({
    required Map<String, dynamic> userOpParams,
    required String entryPoint,
    int validAfter = 0,
    int validUntil = 0,
    BigInt? amountToApprove,
    String? paymasterTokenAddress,
  }) async {
    final context = <String, dynamic>{
      if (sponsorshipPolicyId != null && sponsorshipPolicyId!.isNotEmpty)
        'sponsorshipPolicyId': sponsorshipPolicyId,
      if (paymasterTokenAddress != null && paymasterTokenAddress.isNotEmpty)
        'token': paymasterTokenAddress,
      if (amountToApprove != null)
        'amountToApprove': '0x${amountToApprove.toRadixString(16)}',
    };
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'pm_getPaymasterData',
      'params': [
        userOpParams,
        entryPoint,
        if (context.isEmpty) null else context,
      ],
    });
    final uri = Uri.parse(paymasterUrl);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode != 200) {
      throw PaymasterException(
        'Paymaster API error: ${response.statusCode} ${response.body}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data.containsKey('error')) {
      final err = data['error'];
      final msg = err is Map
          ? (err['message']?.toString() ?? 'Unknown')
          : err.toString();
      throw PaymasterException(msg);
    }
    final result = data['result'];
    if (result == null) throw PaymasterException('No result from paymaster');
    final map = result is Map<String, dynamic> ? result : null;
    if (map == null) throw PaymasterException('Invalid paymaster result');
    final paymaster = map['paymaster']?.toString() ?? '';
    final paymasterData = map['paymasterData']?.toString() ?? '';
    final addr = paymaster.replaceFirst(RegExp('^0x'), '').padLeft(40, '0');
    final dataHex = paymasterData.replaceFirst(RegExp('^0x'), '');
    return '0x$addr$dataHex';
  }

  /// Fetches exchange rate: wei cost -> paymaster token amount (token units).
  /// Implementation depends on paymaster API; defaults to 10^18 (18 decimals).
  Future<BigInt> getTokenExchangeRate(String tokenAddress) async {
    final base = paymasterUrl.endsWith('/') ? paymasterUrl : '$paymasterUrl/';
    try {
      final uri = Uri.parse('${base}exchange-rate');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rate = data['exchangeRate'] ?? data['rate'];
        if (rate != null) {
          return BigInt.tryParse(rate.toString()) ?? BigInt.from(10).pow(18);
        }
      }
    } catch (_) {}
    return BigInt.from(10).pow(18);
  }
}

class PaymasterException implements Exception {
  PaymasterException(this.message);
  final String message;
  @override
  String toString() => 'PaymasterException: $message';
}
