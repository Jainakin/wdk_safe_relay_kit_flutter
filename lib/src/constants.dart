/// Well-known EntryPoint v0.7 address (EIP-4337).
const String defaultEntryPointV07 =
    '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789';

/// Default salt nonce used by wdk-wallet-evm-erc-4337 for Safe prediction.
const String defaultSaltNonce =
    '0x69b348339eea4ed93f9d11931c3b894c8f9d8c7663a053024b11cb7eb4e5a1f6';

/// MultiSendCallOnly contract address (Safe v1.3.0 canonical).
/// Used when encoding batch callData for Safe 4337 module.
/// Source: safe-deployments multi_send_call_only.json.
const String defaultMultiSendCallOnlyAddress =
    '0x40A2aCCbd92BCA938b02010E17A5b8929b49130D';

/// SafeProxy creation code (type(SafeProxy).creationCode) for Safe 1.4.1.
/// Source: SafeProxyFactory.proxyCreationCode() / safe-smart-account.
/// Used for CREATE2 address prediction. Append uint256(singleton) to get full
/// initCode.
const String safeProxyCreationCodeHex = '''
608060405234801561001057600080fd5b506040516101e63803806101e68339818101604052602081101561003357600080fd5b8101908080519060200190929190505050600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff1614156100ca576040517f08c379a0000000000000000000000000000000000000000000000000000000008152'''
    '''
6004018080602001828103825260228152602001806101c46022913960400191505060405180910390fd5b806000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505060ab806101196000396000f3fe608060405273ffffffffffffffffffffffffffffffffffffffff600054167fa619486e000000000000'''
    '''
0000000000000000000000000000000000000000000060003514156050578060005260206000f35b3660008037600080366000845af43d6000803e60008114156070573d6000fd5b3d6000f3fea264697066735822122003d1488ee65e08fa41e58e888a9865554c535f2c77126a82cb4c0f917f31441364736f6c63430007060033496e76616c69642073696e676c65746f6e20616464726573732070726f7669'''
    '646564';
