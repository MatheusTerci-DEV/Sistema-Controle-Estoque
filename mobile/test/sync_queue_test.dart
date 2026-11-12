import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pim_estoque/core/api_client.dart';
import 'package:pim_estoque/features/products/product_catalog.dart';

import 'support/memory_product_storage.dart';

void main() {
  test('fila envia em ordem e 409 não reenvia', () async {
    var online = false;
    var conflict = false;
    final calls = <int>[];
    final client = MockClient((request) async {
      if (!online) return http.Response('offline', 500);
      if (conflict) return http.Response('saldo', 409);
      final body = request.body;
      calls.add(body.contains('"motivo":"x"') ? 1 : 2);
      return http.Response(
        '{"produtoId":1,"quantidade":1,"motivo":"x","criadaEmUtc":"2026-01-01T00:00:00Z"}',
        201,
      );
    });
    final catalog = ProductCatalog(
      MemoryProductStorage(),
      api: ApiClient(client: client, baseUrl: 'http://api', token: 'x'),
    );
    addTearDown(catalog.dispose);
    await catalog.load();
    await catalog.moveStock(
      productId: 1,
      quantity: 1,
      incoming: true,
      reason: 'x',
    );
    await catalog.moveStock(
      productId: 1,
      quantity: 1,
      incoming: true,
      reason: 'y',
    );
    expect(catalog.pendingCount, 2);
    online = true;
    await catalog.sync();
    expect(catalog.pendingCount, 0);
    expect(calls, [1, 2]);
    conflict = true;
    await expectLater(
      catalog.moveStock(productId: 1, quantity: 1, incoming: true, reason: 'z'),
      throwsFormatException,
    );
    expect(catalog.pendingCount, 0);
    await catalog.sync();
    expect(catalog.pendingCount, 0);
  });
}
