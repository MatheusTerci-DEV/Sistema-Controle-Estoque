import 'package:web/web.dart' as web;

import 'auth_storage.dart';

AuthStorage createPlatformAuthStorage() => _BrowserAuthStorage();

class _BrowserAuthStorage implements AuthStorage {
  static const key = 'pim_estoque_auth_v1';
  @override
  Future<String?> read() async => web.window.localStorage.getItem(key);
  @override
  Future<void> write(String value) async =>
      web.window.localStorage.setItem(key, value);
  @override
  Future<void> clear() async => web.window.localStorage.removeItem(key);
}
