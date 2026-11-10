import 'package:flutter/material.dart';

import 'demo_products.dart';
import 'product.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showProduct(Product product) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text('Part number: ${product.partNumber}'),
              const SizedBox(height: 8),
              Text('Categoria: ${product.category}'),
              const SizedBox(height: 20),
              const Text(
                'Produto fictício. Saldo e localização ainda não estão disponíveis.',
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = demoProducts
        .where((p) => p.matches(_search.text))
        .toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produtos',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Nome, part number ou categoria',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar pesquisa',
                            onPressed: () => setState(_search.clear),
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('${products.length} produto(s) encontrado(s)'),
              ],
            ),
          ),
        ),
        if (products.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum produto encontrado. Tente outro nome ou part number.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            sliver: SliverList.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.partNumber}\n${product.category}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showProduct(product),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
