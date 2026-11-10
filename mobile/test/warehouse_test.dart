import 'package:flutter_test/flutter_test.dart';
import 'package:pim_estoque/features/products/product.dart';
import 'package:pim_estoque/features/products/product_catalog.dart';

import 'support/memory_product_storage.dart';

void main() {
  test(
    'cadastro antigo mantém unidade padrão, mínimo zero e localização vazia',
    () {
      final product = Product.fromJson({
        'id': 1,
        'partNumber': 'LEGADO',
        'nomeProduto': 'Material',
        'categoria': 'Geral',
      });
      expect(product.unit, 'UN');
      expect(product.minimumStock, 0);
      expect(product.location, '');
    },
  );
  test(
    'configuração preservada, busca por endereço e reposição no limite',
    () async {
      final storage = MemoryProductStorage();
      final catalog = ProductCatalog(storage);
      addTearDown(catalog.dispose);
      await catalog.load();
      await catalog.save(
        id: 1,
        partNumber: '47000001',
        name: 'Filtro',
        category: 'Filtros',
        unit: 'PC',
        minimumStock: 5,
        location: ' A-01 ',
      );
      expect(catalog.replenishment.length, 1);
      expect(catalog.products.first.matches('a-01'), isTrue);
      await catalog.moveStock(
        productId: 1,
        quantity: 6,
        incoming: true,
        reason: 'Recebimento',
      );
      expect(catalog.replenishment, isEmpty);
      await catalog.moveStock(
        productId: 1,
        quantity: 1,
        incoming: false,
        reason: 'Consumo',
      );
      expect(catalog.replenishment.length, 1);
      await catalog.save(
        id: 1,
        partNumber: '47000001',
        name: 'Filtro novo',
        category: 'Filtros',
      );
      final reopened = ProductCatalog(storage);
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.products.first.location, 'A-01');
      expect(reopened.products.first.unit, 'PC');
      expect(reopened.products.first.minimumStock, 5);
      expect(reopened.balance(1), 5);
    },
  );
  test(
    'impede unidade inválida, mínimo negativo e troca após movimentação',
    () async {
      final catalog = ProductCatalog(MemoryProductStorage());
      addTearDown(catalog.dispose);
      await catalog.load();
      await expectLater(
        catalog.save(
          id: 1,
          partNumber: '47000001',
          name: 'Filtro',
          category: 'Filtros',
          unit: 'INVALIDA',
        ),
        throwsFormatException,
      );
      await expectLater(
        catalog.save(
          id: 1,
          partNumber: '47000001',
          name: 'Filtro',
          category: 'Filtros',
          minimumStock: -1,
        ),
        throwsFormatException,
      );
      await catalog.moveStock(
        productId: 1,
        quantity: 1,
        incoming: true,
        reason: 'Saldo inicial',
      );
      await expectLater(
        catalog.save(
          id: 1,
          partNumber: '47000001',
          name: 'Filtro',
          category: 'Filtros',
          unit: 'CX',
        ),
        throwsFormatException,
      );
      expect(catalog.balance(1), 1);
      expect(catalog.products.first.unit, 'UN');
    },
  );
}
