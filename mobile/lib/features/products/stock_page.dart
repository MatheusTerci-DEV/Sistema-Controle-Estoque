import 'package:flutter/material.dart';

import 'product_catalog.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key, required this.catalog});
  final ProductCatalog catalog;
  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  int? _productId;
  bool _incoming = true;
  String? _message;
  bool _onlyReplenishment = false;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || widget.catalog.isSaving) return;
    setState(() => _message = null);
    try {
      await widget.catalog.moveStock(
        productId: _productId!,
        quantity: int.parse(_quantity.text.trim()),
        incoming: _incoming,
        reason: _reason.text,
      );
      if (mounted) {
        setState(() {
          _message = 'Movimentação salva localmente.';
          _quantity.clear();
          _reason.clear();
        });
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Não foi possível salvar. O saldo não foi alterado.',
        );
      }
    }
  }

  Widget _summary() {
    final product = widget.catalog.products.firstWhere(
      (p) => p.id == _productId,
    );
    final quantity = int.tryParse(_quantity.text.trim());
    final current = widget.catalog.balance(product.id);
    final valid = quantity != null && quantity > 0 && quantity <= 999999999;
    final next = valid ? current + (_incoming ? quantity : -quantity) : null;
    final insufficient = next != null && next < 0;
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo da movimentação',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('${product.partNumber} • ${product.name}'),
            Text('Operação: ${_incoming ? "Entrada" : "Saída"}'),
            Text('Saldo atual: $current ${product.unit}'),
            Text(
              'Quantidade: ${valid ? "$quantity ${product.unit}" : "Informe uma quantidade válida"}',
            ),
            Text(
              'Saldo previsto: ${next == null ? "—" : "$next ${product.unit}"}',
            ),
            if (insufficient)
              Text(
                'Saldo insuficiente. Esta saída será recusada.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const Text('O saldo só muda após registrar a movimentação.'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    final products = catalog.products;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Controle de estoque',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Demonstração local • quantidades em unidades inteiras. Materiais começam com saldo zero; registre uma entrada para adicionar estoque.',
        ),
        const SizedBox(height: 20),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _productId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Material'),
                items: products
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.partNumber} • ${p.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: catalog.isSaving
                    ? null
                    : (value) => setState(() {
                        _productId = value;
                        _message = null;
                      }),
                validator: (value) =>
                    value == null ? 'Selecione um material.' : null,
              ),
              if (_productId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Saldo disponível: ${catalog.balance(_productId!)} ${products.firstWhere((p) => p.id == _productId).unit}',
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  ChoiceChip(
                    label: const Text('Entrada'),
                    selected: _incoming,
                    onSelected: catalog.isSaving
                        ? null
                        : (_) => setState(() => _incoming = true),
                  ),
                  ChoiceChip(
                    label: const Text('Saída'),
                    selected: !_incoming,
                    onSelected: catalog.isSaving
                        ? null
                        : (_) => setState(() => _incoming = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantity,
                enabled: !catalog.isSaving,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _message = null),
                decoration: const InputDecoration(labelText: 'Quantidade'),
                validator: (value) {
                  final quantity = int.tryParse(value?.trim() ?? '');
                  return quantity == null ||
                          quantity <= 0 ||
                          quantity > 999999999
                      ? 'Informe um número inteiro positivo até 999999999.'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reason,
                enabled: !catalog.isSaving,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Motivo / referência',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o motivo.'
                    : null,
              ),
              const SizedBox(height: 12),
              if (_productId != null) _summary(),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: catalog.isSaving ? null : _save,
                icon: const Icon(Icons.swap_vert),
                label: Text(
                  catalog.isSaving ? 'Salvando…' : 'Registrar movimentação',
                ),
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(liveRegion: true, child: Text(_message!)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Saldos por material',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        FilterChip(
          label: const Text('Somente reposição'),
          selected: _onlyReplenishment,
          onSelected: (value) => setState(() => _onlyReplenishment = value),
        ),
        if (_onlyReplenishment && catalog.replenishment.isEmpty)
          const Text(
            'Nenhum material precisa de reposição com os mínimos configurados.',
          ),
        for (final product
            in (_onlyReplenishment ? catalog.replenishment : products))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(product.name),
            subtitle: Text(
              '${product.partNumber} • ${product.location.isEmpty ? "Sem localização" : product.location}${catalog.needsReplenishment(product) ? " • Repor" : ""}',
            ),
            trailing: Text('${catalog.balance(product.id)} ${product.unit}'),
          ),
        const SizedBox(height: 24),
        Text(
          'Últimas movimentações',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (catalog.movements.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nenhuma movimentação registrada.'),
          ),
        for (final movement in catalog.movements.take(30))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              movement.quantity > 0 ? Icons.south_west : Icons.north_east,
            ),
            title: Text(
              '${products.firstWhere((p) => p.id == movement.productId).partNumber} • ${movement.quantity > 0 ? '+' : ''}${movement.quantity} ${products.firstWhere((p) => p.id == movement.productId).unit}',
            ),
            subtitle: Text(
              '${movement.reason}\n${movement.createdAt.toLocal().toString().substring(0, 16)}',
            ),
          ),
      ],
    );
  }
}
