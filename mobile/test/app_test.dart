import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pim_estoque/app.dart';

void main() {
  testWidgets('abre catálogo, pesquisa, mostra detalhes e limpa busca', (
    tester,
  ) async {
    await tester.pumpWidget(const PimEstoqueApp());
    expect(find.textContaining('Demonstração •'), findsOneWidget);
    await tester.tap(find.text('Consultar produtos'));
    await tester.pumpAndSettle();
    expect(find.text('8 produto(s) encontrado(s)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'PIM-1001');
    await tester.pumpAndSettle();
    expect(find.text('1 produto(s) encontrado(s)'), findsOneWidget);
    await tester.tap(find.text('Filtro de óleo'));
    await tester.pumpAndSettle();
    expect(find.text('Part number: PIM-1001'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();
    expect(find.textContaining('Nenhum produto encontrado.'), findsOneWidget);
    await tester.tap(find.byTooltip('Limpar pesquisa'));
    await tester.pumpAndSettle();
    expect(find.text('8 produto(s) encontrado(s)'), findsOneWidget);
  });

  testWidgets('navegação funciona em tela pequena com texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const PimEstoqueApp());
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.inventory_2_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
