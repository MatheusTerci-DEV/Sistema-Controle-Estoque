import 'package:flutter_test/flutter_test.dart';
import 'package:pim_estoque/app.dart';

void main() {
  testWidgets('mostra login e opção de demonstração', (tester) async {
    await tester.pumpWidget(const PimEstoqueApp());
    await tester.pump();
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Usar sem servidor (demonstração)'), findsOneWidget);
  });
}
