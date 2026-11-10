import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/home/home_page.dart';
import 'features/products/products_page.dart';
import 'features/products/product_catalog.dart';
import 'features/products/product_storage.dart';

class PimEstoqueApp extends StatelessWidget {
  const PimEstoqueApp({super.key, this.catalog});

  final ProductCatalog? catalog;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PIM Estoque',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: AppShell(catalog: catalog),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.catalog});

  final ProductCatalog? catalog;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final ProductCatalog _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = widget.catalog ?? ProductCatalog(FileProductStorage());
    _catalog.load();
  }

  @override
  void dispose() {
    if (widget.catalog == null) _catalog.dispose();
    super.dispose();
  }

  Widget _content() {
    if (_catalog.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_catalog.isReady) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_catalog.loadError ?? 'Catálogo indisponível.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _catalog.load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    return IndexedStack(
      index: _index,
      children: [
        HomePage(
          products: _catalog.products,
          onOpenProducts: () => setState(() => _index = 1),
        ),
        ProductsPage(catalog: _catalog),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _catalog,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('PIM Estoque'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Chip(label: Text('NOV • 2026')),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const Text(
                'Demonstração • catálogo local, sem conexão com a API.',
              ),
            ),
            Expanded(child: _content()),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Produtos',
          ),
        ],
      ),
    ),
  );
}
