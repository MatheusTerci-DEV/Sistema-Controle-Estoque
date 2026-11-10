import 'package:flutter/material.dart';

import '../products/demo_products.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onOpenProducts});

  final VoidCallback onOpenProducts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = demoProducts.map((p) => p.category).toSet().length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Seu estoque,\nna palma da mão.',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'Consulte o catálogo e encontre materiais pelo part number.',
        ),
        const SizedBox(height: 24),
        Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 36),
                const SizedBox(height: 16),
                Text(
                  'Catálogo de demonstração',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${demoProducts.length} produtos • $categories categorias',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onOpenProducts,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Consultar produtos'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Próximas entregas', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Integração com a API, cadastro de produtos e controle de '
          'movimentações serão adicionados em etapas.',
        ),
      ],
    );
  }
}
