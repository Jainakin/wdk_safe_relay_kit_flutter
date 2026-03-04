/// Paymaster configuration for Safe4337Pack.
class PaymasterOptions {
  const PaymasterOptions({
    required this.paymasterUrl,
    required this.paymasterAddress,
    this.paymasterTokenAddress,
    this.isSponsored = false,
    this.sponsorshipPolicyId,
    this.amountToApprove,
    this.skipApproveTransaction = false,
  });

  final String paymasterUrl;
  final String paymasterAddress;
  final String? paymasterTokenAddress;
  final bool isSponsored;
  final String? sponsorshipPolicyId;
  final BigInt? amountToApprove;
  final bool skipApproveTransaction;
}
