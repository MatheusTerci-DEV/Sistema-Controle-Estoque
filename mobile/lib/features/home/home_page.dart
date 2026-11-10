import 'package:flutter/material.dart';

import '../products/product.dart';
import '../products/product_catalog.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onOpenProducts,
    required this.onOpenStock,
    required this.products,
    required this.catalog,
  });
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenStock;
  final List<Product> products;
  final ProductCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = products.map((p) => p.category).toSet().length;
    final noStock = products.where((p) => catalog.balance(p.id) == 0).length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Visão geral do almoxarifado',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text('${products.length} produtos • $categories categorias'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onOpenStock,
              icon: const Icon(Icons.swap_vert),
              label: const Text('Nova movimentação'),
            ),
            OutlinedButton.icon(
              onPressed: onOpenProducts,
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Consultar produtos'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 850
                ? 4
                : constraints.maxWidth >= 480
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _indicator(
                  context,
                  width,
                  'Materiais cadastrados',
                  products.length,
                  Icons.inventory_2_outlined,
                  theme.colorScheme.primary,
                ),
                _indicator(
                  context,
                  width,
                  'Categorias',
                  categories,
                  Icons.category_outlined,
                  const Color(0xFF3D5A96),
                ),
                _indicator(
                  context,
                  width,
                  'Materiais sem saldo',
                  noStock,
                  Icons.remove_circle_outline,
                  const Color(0xFF88651B),
                ),
                _indicator(
                  context,
                  width,
                  'Precisam de reposição',
                  catalog.replenishment.length,
                  Icons.notification_important_outlined,
                  const Color(0xFF9F403E),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reposição: ${catalog.replenishment.length} material(is)',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saldo igual ou abaixo do mínimo. Mínimo zero desativa o alerta.',
                ),
                if (catalog.replenishment.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Nenhuma reposição indicada pelos mínimos configurados.',
                    ),
                  ),
                for (final product in catalog.replenishment)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.partNumber} • ${product.location.isEmpty ? "Sem localização" : product.location}',
                    ),
                    trailing: Text(
                      '${catalog.balance(product.id)} / ${product.minimumStock} ${product.unit}',
                    ),
                  ),
                TextButton.icon(
                  onPressed: onOpenStock,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Abrir controle de estoque'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Atividade recente', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  '${catalog.movements.length} movimentação(ões) registrada(s)',
                ),
                if (catalog.movements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Registre a primeira entrada para iniciar o saldo dos materiais.',
                    ),
                  ),
                for (final movement in catalog.movements.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      movement.quantity > 0
                          ? Icons.south_west
                          : Icons.north_east,
                    ),
                    title: Text(
                      '${products.firstWhere((p) => p.id == movement.productId).partNumber} • ${movement.quantity > 0 ? "Entrada" : "Saída"}',
                    ),
                    subtitle: Text(movement.reason),
                    trailing: Text(
                      '${movement.quantity.abs()} ${products.firstWhere((p) => p.id == movement.productId).unit}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Dados salvos neste navegador ou aparelho. Banco central e acesso por equipe ainda estão em desenvolvimento.',
        ),
      ],
    );
  }

  Widget _indicator(
    BuildContext context,
    double width,
    String label,
    int value,
    IconData icon,
    Color color,
  ) => SizedBox(
    width: width,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: color),
            ),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    ),
  );
}
