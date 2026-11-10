import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pim_estoque/app.dart';
import 'package:pim_estoque/features/products/product_catalog.dart';

import 'support/memory_product_storage.dart';

void main() {
  testWidgets('desktop usa menu lateral e atalho abre movimentação', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = ProductCatalog(MemoryProductStorage());
    addTearDown(catalog.dispose);
    await tester.pumpWidget(PimEstoqueApp(catalog: catalog));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Materiais cadastrados'), findsOneWidget);
    await tester.tap(find.text('Nova movimentação'));
    await tester.pumpAndSettle();
    expect(find.text('Controle de estoque'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('resumo prevê saldo sem alterar estoque antes de confirmar', (
    tester,
  ) async {
    final catalog = ProductCatalog(MemoryProductStorage());
    addTearDown(catalog.dispose);
    await tester.pumpWidget(PimEstoqueApp(catalog: catalog));
    await tester.pumpAndSettle();
    await catalog.moveStock(
      productId: 1,
      quantity: 3,
      incoming: true,
      reason: 'Inicial',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova movimentação'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('47000001 • Filtro de óleo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saída'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantidade'),
      '5',
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Resumo da movimentação'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Saldo previsto: -2 UN'), findsOneWidget);
    expect(
      find.text('Saldo insuficiente. Esta saída será recusada.'),
      findsOneWidget,
    );
    expect(catalog.balance(1), 3);
  });
}
