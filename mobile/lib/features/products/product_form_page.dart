import 'package:flutter/material.dart';

import 'product.dart';
import 'product_catalog.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, required this.catalog, this.product});

  final ProductCatalog catalog;
  final Product? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _form = GlobalKey<FormState>();
  late final _partNumber = TextEditingController(
    text: widget.product?.partNumber,
  );
  late final _name = TextEditingController(text: widget.product?.name);
  late final _category = TextEditingController(text: widget.product?.category);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _partNumber.dispose();
    _name.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.catalog.save(
        id: widget.product?.id,
        partNumber: _partNumber.text,
        name: _name.text,
        category: _category.text,
      );
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Não foi possível salvar o material. Confira os campos e tente novamente. '
              'A alteração não foi aplicada.';
        });
      }
    }
  }

  String? _required(String? value, String label, int limit) {
    if (value == null || value.trim().isEmpty) return 'Informe $label.';
    if (value.trim().length > limit) return 'Use até $limit caracteres.';
    return null;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Novo material' : 'Editar material',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Cadastro local para demonstração. Não envia dados para a API.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('partNumberField'),
                controller: _partNumber,
                enabled: !_saving,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                maxLength: 50,
                decoration: const InputDecoration(labelText: 'Part number'),
                validator: (value) => widget.catalog.validatePartNumber(
                  value,
                  excludingId: widget.product?.id,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('nameField'),
                controller: _name,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nome do material',
                ),
                validator: (value) =>
                    _required(value, 'o nome do material', 100),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('categoryField'),
                controller: _category,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                maxLength: 60,
                decoration: const InputDecoration(labelText: 'Categoria'),
                validator: (value) => _required(value, 'a categoria', 60),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('saveProductButton'),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Salvando…' : 'Salvar material'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
