import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pim_estoque/app.dart';
import 'package:pim_estoque/features/products/product_catalog.dart';

import 'support/memory_product_storage.dart';

void main() {
  testWidgets('registra entrada pela interface e mostra saldo', (tester) async {
    final catalog = ProductCatalog(MemoryProductStorage());
    addTearDown(catalog.dispose);
    await tester.pumpWidget(PimEstoqueApp(catalog: catalog));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.swap_vert).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('47000001 • Filtro de óleo').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantidade'),
      '10',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Motivo / referência'),
      'Recebimento',
    );
    final button = find.text('Registrar movimentação');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(catalog.balance(1), 10);
    expect(find.text('Movimentação salva localmente.'), findsOneWidget);
  });

  test(
    'entrada, saída e edição mantêm histórico e saldo após reabrir',
    () async {
      final storage = MemoryProductStorage();
      final catalog = ProductCatalog(storage);
      addTearDown(catalog.dispose);
      await catalog.load();
      expect(catalog.balance(1), 0);
      await catalog.moveStock(
        productId: 1,
        quantity: 20,
        incoming: true,
        reason: 'NF 123',
      );
      await catalog.moveStock(
        productId: 1,
        quantity: 7,
        incoming: false,
        reason: 'Consumo',
      );
      await catalog.save(
        id: 1,
        partNumber: '47000001',
        name: 'Filtro revisado',
        category: 'Filtros',
      );
      final reopened = ProductCatalog(storage);
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.balance(1), 13);
      expect(reopened.movements.length, 2);
      expect(reopened.movements.first.quantity, -7);
    },
  );
  test('recusa saída sem saldo, quantidade inválida e motivo vazio', () async {
    final catalog = ProductCatalog(MemoryProductStorage());
    addTearDown(catalog.dispose);
    await catalog.load();
    await expectLater(
      catalog.moveStock(
        productId: 1,
        quantity: 1,
        incoming: false,
        reason: 'Venda',
      ),
      throwsFormatException,
    );
    for (final quantity in [0, -1, 1000000000]) {
      await expectLater(
        catalog.moveStock(
          productId: 1,
          quantity: quantity,
          incoming: true,
          reason: 'Teste',
        ),
        throwsFormatException,
      );
    }
    await expectLater(
      catalog.moveStock(
        productId: 999,
        quantity: 1,
        incoming: true,
        reason: 'Teste',
      ),
      throwsFormatException,
    );
    await expectLater(
      catalog.moveStock(productId: 1, quantity: 1, incoming: true, reason: ' '),
      throwsFormatException,
    );
    expect(catalog.movements, isEmpty);
  });
  test('falha de gravação mantém saldo e histórico anteriores', () async {
    final storage = MemoryProductStorage();
    final catalog = ProductCatalog(storage);
    addTearDown(catalog.dispose);
    await catalog.load();
    await catalog.moveStock(
      productId: 1,
      quantity: 5,
      incoming: true,
      reason: 'Recebimento',
    );
    storage.failWrite = true;
    await expectLater(
      catalog.moveStock(
        productId: 1,
        quantity: 2,
        incoming: false,
        reason: 'Saída',
      ),
      throwsStateError,
    );
    expect(catalog.balance(1), 5);
    expect(catalog.movements.length, 1);
  });
}
