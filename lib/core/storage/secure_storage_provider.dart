import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const kTokenStorageKey = 'gama_auth_token';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'gama_secure', publicKey: 'gama_key'),
  ),
);
