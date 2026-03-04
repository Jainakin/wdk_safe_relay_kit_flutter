/// A single transaction in a batch for Safe / ERC-4337.
class MetaTransactionData {
  const MetaTransactionData({
    required this.from,
    required this.to,
    required this.value,
    this.data,
  });

  /// Sender (e.g. Safe address).
  final String from;

  /// Recipient address.
  final String to;

  /// Value in wei.
  final BigInt value;

  /// Optional calldata (hex with 0x prefix).
  final String? data;
}
