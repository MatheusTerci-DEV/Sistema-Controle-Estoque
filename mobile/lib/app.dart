import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/home/home_page.dart';
import 'features/products/products_page.dart';

class PimEstoqueApp extends StatelessWidget {
  const PimEstoqueApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PIM Estoque',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const AppShell(),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
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
              'Demonstração • dados fictícios, sem conexão com a API.',
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                HomePage(onOpenProducts: () => setState(() => _index = 1)),
                const ProductsPage(),
              ],
            ),
          ),
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
  );
}
