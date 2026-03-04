import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client for paymaster service (sponsorship, token exchange rate).
class PaymasterClient {
  PaymasterClient({
    required this.paymasterUrl,
    this.paymasterAddress,
    this.paymasterTokenAddress,
  });

  final String paymasterUrl;
  final String? paymasterAddress;
  final String? paymasterTokenAddress;

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
    } catch (_) {
      // ignore
    }
    return BigInt.from(10).pow(18);
  }
}
