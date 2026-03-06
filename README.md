# wdk_safe_relay_kit_flutter

Safe smart accounts with ERC-4337 (Account Abstraction) and relay support for Flutter/Dart. Port of [@tetherto/wdk-safe-relay-kit](https://www.npmjs.com/package/@tetherto/wdk-safe-relay-kit).

## Features

- **Safe4337Pack**: Create, sign, and execute UserOperations for Safe accounts via a bundler.
- **Safe address prediction**: Predict Safe address from owners, threshold, salt nonce, and chain.
- **Fee estimators**: Generic (bundler RPC) and Pimlico-specific. Use `PimlicoFeeEstimator` when your bundler is a Pimlico endpoint; it delegates gas estimation to `eth_estimateUserOperationGas` via the configured bundler.
- **Paymaster**: Token paymaster and sponsorship support (including Pimlico-style verifying paymasters via `pm_getPaymasterData` when configured).

## Usage

```dart
import 'package:wdk_safe_relay_kit_flutter/wdk_safe_relay_kit.dart';

// Predict Safe address
final safeAddress = await Safe4337Pack.predictSafeAddress(
  owners: ['0x...'],
  threshold: 1,
  chainId: 1,
  safeVersion: '1.4.1',
  safeModulesVersion: '0.3.0',
  saltNonce: '0x...',
);

// Init pack (with RPC client and bundler URL)
final pack = await Safe4337Pack.init(
  Safe4337InitOptions(
    provider: rpcClient,
    bundlerUrl: 'https://...',
    options: const PredictedSafeOptions(
      owners: ['0x...'],
      threshold: 1,
      saltNonce: '0x...',
    ),
    customContracts: CustomContracts(
      entryPointAddress: '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789',
    ),
  ),
);

// Create, sign, execute
final op = await pack.createTransaction(
  transactions: [
    MetaTransactionData(
      from: pack.safeAddress,
      to: '0x...',
      value: BigInt.zero,
      data: null,
    ),
  ],
  options: const CreateTransactionOptions(),
);
// Get operation hash from Safe 4337 module: getOperationHash(userOp) via RPC, then pass to signSafeOperation.
final signed = await pack.signSafeOperation(
  op,
  signer: mySigner,
  operationHashHex: operationHashFromRpc,
);
final userOpHash = await pack.executeTransaction(executable: signed);
```

**Operation hash:** `signSafeOperation` requires `operationHashHex` from the Safe 4337 module's `getOperationHash(PackedUserOperation)` view. Use the helper `getOperationHash(provider, moduleAddress, userOp)` from the package (e.g. `getOperationHash(rpcClient, safe4337Deployments[chainId]!['0.3.0']!.safe4337ModuleAddress, op.userOperation)`), or call the module view via your RPC provider (e.g. `eth_call` to the module address) with the packed UserOperation; pass the returned bytes32 hex to `signSafeOperation`.

## Dependencies

- `web3dart` for RPC and ABI
- `http` for bundler/paymaster HTTP

No dependency on `wdk_wallet_flutter` or `wdk_wallet_evm_flutter`; the ERC-4337 wallet package will depend on this kit.
