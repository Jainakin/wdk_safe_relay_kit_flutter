/// Safe 1.4.1 ProxyFactory and Safe (singleton) addresses per chain.
///
/// Source: [safe-deployments](https://github.com/safe-global/safe-deployments)
/// v1.4.1, canonical deployment. Used for CREATE2 address prediction.
final Map<int, Safe141Deployment> safe141Deployments = {
  1: const Safe141Deployment(
    proxyFactoryAddress: '0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67',
    singletonAddress: '0x41675C099F32341bf84BFc5382aF534df5C7461a',
  ),
  11155111: const Safe141Deployment(
    proxyFactoryAddress: '0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67',
    singletonAddress: '0x41675C099F32341bf84BFc5382aF534df5C7461a',
  ),
};

class Safe141Deployment {
  const Safe141Deployment({
    required this.proxyFactoryAddress,
    required this.singletonAddress,
  });

  final String proxyFactoryAddress;
  final String singletonAddress;
}
