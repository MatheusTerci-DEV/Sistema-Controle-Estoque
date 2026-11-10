import 'product.dart';

/// Materiais fictícios carregados somente quando ainda não existe catálogo salvo.
const demoProducts = <Product>[
  Product(
    id: 1,
    partNumber: 'PIM-1001',
    name: 'Filtro de óleo',
    category: 'Filtros',
  ),
  Product(
    id: 2,
    partNumber: 'PIM-1002',
    name: 'Filtro de ar',
    category: 'Filtros',
  ),
  Product(
    id: 3,
    partNumber: 'PIM-2001',
    name: 'Parafuso M10 × 30',
    category: 'Fixadores',
  ),
  Product(
    id: 4,
    partNumber: 'PIM-2002',
    name: 'Porca M10',
    category: 'Fixadores',
  ),
  Product(
    id: 5,
    partNumber: 'PIM-2003',
    name: 'Arruela M10',
    category: 'Fixadores',
  ),
  Product(
    id: 6,
    partNumber: 'PIM-3001',
    name: 'Rolamento 6204',
    category: 'Rolamentos',
  ),
  Product(
    id: 7,
    partNumber: 'PIM-4001',
    name: 'Correia de transmissão',
    category: 'Transmissão',
  ),
  Product(
    id: 8,
    partNumber: 'PIM-5001',
    name: 'Mangueira hidráulica',
    category: 'Hidráulica',
  ),
];
