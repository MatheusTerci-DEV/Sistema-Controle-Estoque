import 'package:flutter_test/flutter_test.dart';
import 'package:pim_estoque/features/products/product.dart';

void main() {
  const product = Product(
    id: 1,
    partNumber: 'DEMO-1001',
    name: 'Filtro de óleo',
    category: 'Filtros',
  );

  test('pesquisa por nome, part number e categoria sem diferenciar caixa', () {
    expect(product.matches('  FILTRO  '), isTrue);
    expect(product.matches('demo-1001'), isTrue);
    expect(product.matches('filtros'), isTrue);
    expect(product.matches('parafuso'), isFalse);
    expect(product.matches(''), isTrue);
  });
}
