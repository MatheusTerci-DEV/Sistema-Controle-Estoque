import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pim_estoque/app.dart';
import 'package:pim_estoque/features/products/product_catalog.dart';

import 'support/memory_product_storage.dart';

void main() {
  Future<ProductCatalog> openApp(
    WidgetTester tester,
    MemoryProductStorage storage,
  ) async {
    final catalog = ProductCatalog(storage);
    addTearDown(catalog.dispose);
    await tester.pumpWidget(PimEstoqueApp(catalog: catalog));
    await tester.pumpAndSettle();
    return catalog;
  }

  Future<void> openProducts(WidgetTester tester) async {
    await tester.tap(find.text('Consultar produtos'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    final button = find.byKey(const Key('saveProductButton'));
    await tester.scrollUntilVisible(
      button,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(button), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    if (find.text('Novo material').evaluate().isNotEmpty ||
        find.text('Editar material').evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        find.byKey(const Key('partNumberField')),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> fill(
    WidgetTester tester, {
    String pn = '86009001',
    String name = 'Sensor de pressão',
  }) async {
    await tester.enterText(find.byKey(const Key('partNumberField')), pn);
    await tester.enterText(find.byKey(const Key('nameField')), name);
    await tester.enterText(find.byKey(const Key('categoryField')), 'Elétrica');
  }

  testWidgets('abre catálogo, pesquisa, mostra detalhes e limpa busca', (
    tester,
  ) async {
    await openApp(tester, MemoryProductStorage());
    expect(find.textContaining('Demonstração •'), findsOneWidget);
    await openProducts(tester);
    expect(find.text('8 produto(s) encontrado(s)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '47000001');
    await tester.pumpAndSettle();
    expect(find.text('1 produto(s) encontrado(s)'), findsOneWidget);
    await tester.tap(find.text('Filtro de óleo'));
    await tester.pumpAndSettle();
    expect(find.text('Part number: 47000001'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();
    expect(find.textContaining('Nenhum produto encontrado.'), findsOneWidget);
    await tester.tap(find.byTooltip('Limpar pesquisa'));
    await tester.pumpAndSettle();
    expect(find.text('8 produto(s) encontrado(s)'), findsOneWidget);
  });

  testWidgets('cadastra, edita e reabre app mantendo material e totais', (
    tester,
  ) async {
    final storage = MemoryProductStorage();
    final catalog = await openApp(tester, storage);
    await openProducts(tester);
    await tester.tap(find.text('Cadastrar material'));
    await tester.pumpAndSettle();
    await fill(tester);
    await save(tester);
    expect(find.text('9 produto(s) encontrado(s)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '86009001');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sensor de pressão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar material'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('nameField')),
      'Sensor revisado',
    );
    await save(tester);
    expect(catalog.products.length, 9);
    expect(catalog.products.last.name, 'Sensor revisado');
    await tester.pumpWidget(const SizedBox());
    await openApp(tester, storage);
    expect(find.text('9 produtos • 6 categorias'), findsOneWidget);
    await openProducts(tester);
    await tester.enterText(find.byType(TextField), '86009001');
    await tester.pumpAndSettle();
    expect(find.text('Sensor revisado'), findsOneWidget);
  });

  testWidgets('valida obrigatórios e duplicidade sem cadastrar', (
    tester,
  ) async {
    final catalog = await openApp(tester, MemoryProductStorage());
    await openProducts(tester);
    await tester.tap(find.text('Cadastrar material'));
    await tester.pumpAndSettle();
    await save(tester);
    expect(find.text('Informe o part number.'), findsOneWidget);
    expect(find.text('Informe o nome do material.'), findsOneWidget);
    expect(find.text('Informe a categoria.'), findsOneWidget);
    await fill(tester, pn: '  47000001  ');
    await save(tester);
    expect(
      find.text('Já existe um material com este part number.'),
      findsOneWidget,
    );
    expect(catalog.products.length, 8);
  });

  testWidgets('falha ao salvar mantém formulário e permite tentar novamente', (
    tester,
  ) async {
    final storage = MemoryProductStorage();
    final catalog = await openApp(tester, storage);
    storage.failWrite = true;
    await openProducts(tester);
    await tester.tap(find.text('Cadastrar material'));
    await tester.pumpAndSettle();
    await fill(tester);
    await save(tester);
    expect(
      find.textContaining('Não foi possível salvar o material.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('partNumberField')), findsOneWidget);
    expect(catalog.products.length, 8);
    storage.failWrite = false;
    await save(tester);
    expect(find.text('9 produto(s) encontrado(s)'), findsOneWidget);
  });

  testWidgets('cancelar cadastro não altera catálogo', (tester) async {
    final catalog = await openApp(tester, MemoryProductStorage());
    await openProducts(tester);
    await tester.tap(find.text('Cadastrar material'));
    await tester.pumpAndSettle();
    await fill(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(catalog.products.length, 8);
    expect(find.text('8 produto(s) encontrado(s)'), findsOneWidget);
  });

  testWidgets('erro ao abrir mostra recuperação e bloqueia cadastro', (
    tester,
  ) async {
    final storage = MemoryProductStorage()..failRead = true;
    await openApp(tester, storage);
    expect(
      find.textContaining('Não foi possível abrir o catálogo local.'),
      findsOneWidget,
    );
    expect(find.text('Cadastrar material'), findsNothing);
    storage.failRead = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('8 produtos • 5 categorias'), findsOneWidget);
  });

  testWidgets('navegação e formulário em tela pequena com texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openApp(tester, MemoryProductStorage());
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.inventory_2_outlined).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar material'));
    await tester.pumpAndSettle();
    await fill(tester);
    await save(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('9 produto(s) encontrado(s)'), findsOneWidget);
  });
}
