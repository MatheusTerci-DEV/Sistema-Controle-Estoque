import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late final _location = TextEditingController(text: widget.product?.location);
  late final _minimum = TextEditingController(
    text: (widget.product?.minimumStock ?? 0).toString(),
  );
  late String _unit = widget.product?.unit ?? 'UN';
  bool get _unitLocked =>
      widget.product != null &&
      widget.catalog.movements.any((m) => m.productId == widget.product!.id);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _partNumber.dispose();
    _name.dispose();
    _category.dispose();
    _location.dispose();
    _minimum.dispose();
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
        unit: _unit,
        minimumStock: int.parse(_minimum.text.trim()),
        location: _location.text,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  maxLength: 8,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Part number',
                    helperText: '8 dígitos • prefixos 47, 48, 84 ou 86',
                  ),
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Unidade de medida',
                  ),
                  items: Product.units
                      .map(
                        (unit) =>
                            DropdownMenuItem(value: unit, child: Text(unit)),
                      )
                      .toList(),
                  onChanged: _saving || _unitLocked
                      ? null
                      : (value) => setState(() => _unit = value!),
                ),
                const SizedBox(height: 8),
                Text(
                  _unitLocked
                      ? 'Unidade bloqueada: este material já possui movimentações.'
                      : 'UN: unidade • PC: peça • PAR: par • CX: caixa • PCT: pacote • RL: rolo. Quantidades inteiras; sem conversão automática.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('locationField'),
                  controller: _location,
                  enabled: !_saving,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Localização',
                    hintText: 'Ex.: A-01-02',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('minimumStockField'),
                  controller: _minimum,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estoque mínimo',
                    helperText: '0 desativa o alerta de reposição.',
                  ),
                  validator: (value) {
                    final minimum = int.tryParse(value?.trim() ?? '');
                    return minimum == null || minimum < 0 || minimum > 999999999
                        ? 'Informe um inteiro entre 0 e 999999999.'
                        : null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
    ),
  );
}
