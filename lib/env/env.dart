import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'PROXY_URL')
  static final String proxyUrl = _Env.proxyUrl;

  @EnviedField(varName: 'CLIENT_TOKEN')
  static final String clientToken = _Env.clientToken;
}
