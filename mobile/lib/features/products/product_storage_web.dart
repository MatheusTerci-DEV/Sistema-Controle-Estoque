import 'package:web/web.dart' as web;

import 'product_storage_contract.dart';

ProductStorage createProductStorage() => BrowserProductStorage();

/// Catálogo próprio do navegador. Falhas de quota ou acesso são propagadas à UI.
class BrowserProductStorage implements ProductStorage {
  static const key = 'pim_estoque_products_v1';

  @override
  Future<String?> read() async => web.window.localStorage.getItem(key);

  @override
  Future<void> write(String content) async {
    web.window.localStorage.setItem(key, content);
  }
}
