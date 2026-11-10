import 'package:flutter/material.dart';

import '../products/product.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onOpenProducts,
    required this.products,
  });

  final VoidCallback onOpenProducts;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = products.map((p) => p.category).toSet().length;
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
                  'Materiais neste aparelho',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${products.length} produtos • $categories categorias'),
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
          'Integração com a API e controle de movimentações serão adicionados em etapas. '
          'Os cadastros atuais ficam salvos somente neste aparelho.',
        ),
      ],
    );
  }
}
