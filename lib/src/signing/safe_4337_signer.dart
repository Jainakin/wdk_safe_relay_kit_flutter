/// Interface for signing the Safe 4337 operation hash.
///
/// The operation hash is the value returned by the Safe 4337 module's
/// `getOperationHash(PackedUserOperation)` view. The app should obtain it
/// via an RPC call to the module contract, then pass it to
/// Safe4337Pack.signSafeOperation as operationHashHex.
abstract class Safe4337Signer {
  /// The owner address (used as key in SafeOperation.signatures).
  String get address;

  /// Signs the operation hash (32 bytes, typically as hex with 0x prefix).
  /// Returns the signature as hex (0x-prefixed, 65 or 64 bytes: r, s, v).
  Future<String> signOperationHash(String operationHashHex);
}
