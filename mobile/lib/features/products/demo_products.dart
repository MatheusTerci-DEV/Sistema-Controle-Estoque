import 'product.dart';

/// Materiais fictícios carregados somente quando ainda não existe catálogo salvo.
const demoProducts = <Product>[
  Product(
    id: 1,
    partNumber: '47000001',
    name: 'Filtro de óleo',
    category: 'Filtros',
  ),
  Product(
    id: 2,
    partNumber: '47000002',
    name: 'Filtro de ar',
    category: 'Filtros',
  ),
  Product(
    id: 3,
    partNumber: '48000001',
    name: 'Parafuso M10 × 30',
    category: 'Fixadores',
  ),
  Product(
    id: 4,
    partNumber: '48000002',
    name: 'Porca M10',
    category: 'Fixadores',
  ),
  Product(
    id: 5,
    partNumber: '48000003',
    name: 'Arruela M10',
    category: 'Fixadores',
  ),
  Product(
    id: 6,
    partNumber: '84000001',
    name: 'Rolamento 6204',
    category: 'Rolamentos',
  ),
  Product(
    id: 7,
    partNumber: '86000001',
    name: 'Correia de transmissão',
    category: 'Transmissão',
  ),
  Product(
    id: 8,
    partNumber: '86000002',
    name: 'Mangueira hidráulica',
    category: 'Hidráulica',
  ),
];
