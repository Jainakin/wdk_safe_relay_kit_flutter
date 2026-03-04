# wdk_safe_relay_kit_flutter

Safe smart accounts with ERC-4337 (Account Abstraction) and relay support for Flutter/Dart. Port of [@tetherto/wdk-safe-relay-kit](https://www.npmjs.com/package/@tetherto/wdk-safe-relay-kit).

## Features

- **Safe4337Pack**: Create, sign, and execute UserOperations for Safe accounts via a bundler.
- **Safe address prediction**: Predict Safe address from owners, threshold, salt nonce, and chain.
- **Fee estimators**: Generic (bundler RPC) and Pimlico-specific.
- **Paymaster**: Token paymaster and sponsorship support.

## Usage

```dart
import 'package:wdk_safe_relay_kit_flutter/wdk_safe_relay_kit.dart';

// Predict Safe address
final safeAddress = await Safe4337Pack.predictSafeAddress(
  owners: ['0x...'],
  threshold: 1,
  saltNonce: '0x...',
  chainId: 1,
  safeVersion: '1.4.1',
  safeModulesVersion: '0.3.0',
);

// Init pack (with RPC client and bundler URL)
final pack = await Safe4337Pack.init(
  provider: rpcClient,
  bundlerUrl: 'https://...',
  options: PredictedSafeOptions(
    owners: ['0x...'],
    threshold: 1,
    saltNonce: '0x...',
  ),
  customContracts: CustomContracts(
    entryPointAddress: '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789',
  ),
);

// Create, sign, execute
final op = await pack.createTransaction(
  transactions: [MetaTransactionData(to: '0x...', value: BigInt.zero, data: null)],
  options: CreateTransactionOptions(feeEstimator: myEstimator),
);
final signed = await pack.signSafeOperation(op, signer: mySigner);
final userOpHash = await pack.executeTransaction(executable: signed);
```

## Dependencies

- `web3dart` for RPC and ABI
- `http` for bundler/paymaster HTTP

No dependency on `wdk_wallet_flutter` or `wdk_wallet_evm_flutter`; the ERC-4337 wallet package will depend on this kit.
