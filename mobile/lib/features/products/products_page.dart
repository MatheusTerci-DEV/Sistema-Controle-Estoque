import 'package:flutter/material.dart';

import 'product_catalog.dart';
import 'product_form_page.dart';
import 'product.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.catalog});

  final ProductCatalog catalog;

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

  Future<void> _openForm([Product? product]) async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductFormPage(catalog: widget.catalog, product: product),
      ),
    );
    if (saved == true && mounted) {
      // Mostrar o material recém-cadastrado mesmo que uma pesquisa anterior o excluísse.
      setState(_search.clear);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material salvo localmente.')),
      );
    }
  }

  Future<void> _showProduct(Product product) async {
    final edit = await showModalBottomSheet<bool>(
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
              if (product.needsCodeReview)
                const Text(
                  'Código antigo fora do padrão. Edite para informar o código correto de 8 dígitos.',
                ),
              const SizedBox(height: 8),
              Text('Categoria: ${product.category}'),
              const SizedBox(height: 12),
              Text(
                'Saldo: ${widget.catalog.balance(product.id)} ${product.unit}',
              ),
              Text('Estoque mínimo: ${product.minimumStock} ${product.unit}'),
              Text(
                'Localização: ${product.location.isEmpty ? "Não informada" : product.location}',
              ),
              if (widget.catalog.needsReplenishment(product))
                const Text('Reposição necessária'),
              const SizedBox(height: 20),
              const Text('Cadastro de almoxarifado. Dados salvos localmente.'),
              const SizedBox(height: 20),
              if (widget.catalog.canWrite)
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar material'),
                ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showHistory(product);
                },
                icon: const Icon(Icons.history),
                label: const Text('Ver histórico'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      ),
    );
    if (edit == true && mounted) await _openForm(product);
  }

  Future<void> _showHistory(Product product) async {
    try {
      final history = await widget.catalog.history(product.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Histórico: ${product.name}'),
          content: history.isEmpty
              ? const Text('Nenhuma movimentação registrada.')
              : SizedBox(
                  width: 360,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final movement in history)
                        ListTile(
                          title: Text(
                            '${movement.quantity > 0 ? 'Entrada' : 'Saída'}: ${movement.quantity.abs()} ${product.unit}',
                          ),
                          subtitle: Text(movement.reason),
                        ),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível carregar o histórico.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.catalog.products
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
                if (widget.catalog.canWrite)
                  FilledButton.icon(
                    onPressed: widget.catalog.isSaving
                        ? null
                        : () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Cadastrar material'),
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
