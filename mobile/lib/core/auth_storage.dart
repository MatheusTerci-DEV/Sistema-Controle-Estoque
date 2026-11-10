import 'auth_storage_io.dart'
    if (dart.library.js_interop) 'auth_storage_web.dart';

abstract interface class AuthStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

AuthStorage createAuthStorage() => createPlatformAuthStorage();
