# Changelog

## 1.0.0-beta.1

- Initial port of @tetherto/wdk-safe-relay-kit.
- **Safe4337Pack**: `init`, `predictSafeAddress`, `createTransaction`, `signSafeOperation`, `executeTransaction`, `getUserOperationByHash`, `getUserOperationReceipt`, `getTokenExchangeRate`, `setSigner`.
- **BundlerClient**: `sendUserOperation`, `estimateUserOperationGas`, `getSupportedEntryPoints`, `getUserOperationByHash`, `getUserOperationReceipt`.
- **PaymasterClient**: `getTokenExchangeRate`.
- **Fee estimators**: `IFeeEstimator`, `GenericFeeEstimator`, `PimlicoFeeEstimator`.
- **Types**: UserOperation, UserOperationReceipt, UserOperationWithPayload, SafeOperation, MetaTransactionData, init and paymaster options.
- **Safe address prediction**: placeholder implementation (deterministic from params); full CREATE2 logic TODO.
