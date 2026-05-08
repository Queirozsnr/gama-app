// TODO: use --dart-define=BASE_URL=https://sua-api.com para ambientes diferentes
// 10.0.2.2 é o localhost do host no emulador Android; para Windows/web use localhost diretamente
const kBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:5181');

const kConnectTimeout = Duration(seconds: 10);
const kReceiveTimeout = Duration(seconds: 15);
