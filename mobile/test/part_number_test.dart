import 'package:flutter_test/flutter_test.dart';
import 'package:pim_estoque/features/products/product.dart';
import 'package:pim_estoque/features/products/product_catalog.dart';

import 'support/memory_product_storage.dart';

void main() {
  test('aceita apenas oito dígitos ASCII com os quatro prefixos', () {
    for (final code in ['47000001', '48000001', '84000001', '86000001']) {
      expect(Product.validPartNumber(code), isTrue);
    }
    for (final code in [
      '4700000',
      '470000001',
      '49000001',
      '47A00001',
      '４７０００００１',
      '47000001\n',
      'PIM-1001',
    ]) {
      expect(Product.validPartNumber(code), isFalse);
    }
  });
  test(
    'converte exemplo antigo mantendo saldo e não inventa código personalizado',
    () async {
      final storage = MemoryProductStorage(
        '{"version":1,"products":[{"id":1,"partNumber":"PIM-1001","nomeProduto":"Filtro","categoria":"Filtros"},{"id":2,"partNumber":"ANTIGO","nomeProduto":"Outro","categoria":"Geral"}],"movements":[{"productId":1,"quantity":5,"reason":"Inicial","createdAt":"2026-11-10T12:00:00Z"}]}',
      );
      final catalog = ProductCatalog(storage);
      addTearDown(catalog.dispose);
      await catalog.load();
      expect(catalog.products.first.partNumber, '47000001');
      expect(catalog.balance(1), 5);
      expect(catalog.products.last.needsCodeReview, isTrue);
      await expectLater(
        catalog.moveStock(
          productId: 2,
          quantity: 1,
          incoming: true,
          reason: 'Entrada',
        ),
        throwsFormatException,
      );
      await catalog.save(
        id: 2,
        partNumber: '84009001',
        name: 'Outro',
        category: 'Geral',
      );
      expect(catalog.products.last.needsCodeReview, isFalse);
    },
  );
}
