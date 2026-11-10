import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'demo_products.dart';
import 'product.dart';
import 'product_storage.dart';

class ProductCatalog extends ChangeNotifier {
  ProductCatalog(this.storage);

  final ProductStorage storage;
  List<Product> _products = [];
  List<Product> get products => List.unmodifiable(_products);
  bool isLoading = false;
  bool isSaving = false;
  bool isReady = false;
  String? loadError;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (isLoading || isSaving) return;
    isLoading = true;
    isReady = false;
    loadError = null;
    _notify();
    try {
      final raw = await storage.read();
      final List<Product> loaded;
      if (raw == null) {
        loaded = List.of(demoProducts);
        await storage.write(_encode(loaded));
      } else {
        final data = jsonDecode(raw);
        if (data is! Map<String, dynamic> ||
            data['version'] != 1 ||
            data['products'] is! List) {
          throw const FormatException('Formato de catálogo inválido.');
        }
        loaded = (data['products'] as List).map((row) {
          if (row is! Map<String, dynamic>) {
            throw const FormatException('Material inválido.');
          }
          return Product.fromJson(row);
        }).toList();
        if (loaded.map((p) => p.id).toSet().length != loaded.length ||
            loaded.map((p) => p.partNumber.toUpperCase()).toSet().length !=
                loaded.length) {
          throw const FormatException('Materiais duplicados no arquivo.');
        }
      }
      _products = loaded;
      isReady = true;
    } catch (_) {
      loadError =
          'Não foi possível abrir o catálogo local. '
          'Seus dados não foram substituídos. Tente novamente.';
    } finally {
      isLoading = false;
      _notify();
    }
  }

  String? validatePartNumber(String? value, {int? excludingId}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe o part number.';
    if (text.length > 50) return 'Use até 50 caracteres.';
    if (_products.any(
      (p) =>
          p.id != excludingId &&
          p.partNumber.toUpperCase() == text.toUpperCase(),
    )) {
      return 'Já existe um material com este part number.';
    }
    return null;
  }

  Future<void> save({
    int? id,
    required String partNumber,
    required String name,
    required String category,
  }) async {
    if (!isReady || isLoading || isSaving) {
      throw StateError('Catálogo indisponível.');
    }
    final problem = validatePartNumber(partNumber, excludingId: id);
    if (problem != null) throw FormatException(problem);
    if (name.trim().isEmpty ||
        name.trim().length > 100 ||
        category.trim().isEmpty ||
        category.trim().length > 60) {
      throw const FormatException('Confira o nome e a categoria do material.');
    }
    if (id != null && !_products.any((p) => p.id == id)) {
      throw StateError('Material não encontrado.');
    }
    final nextId =
        _products.fold<int>(0, (max, p) => p.id > max ? p.id : max) + 1;
    final product = Product(
      id: id ?? nextId,
      partNumber: partNumber.trim().toUpperCase(),
      name: name.trim(),
      category: category.trim(),
    );
    final updated = id == null
        ? [..._products, product]
        : _products.map((p) => p.id == id ? product : p).toList();
    isSaving = true;
    _notify();
    try {
      await storage.write(_encode(updated));
      _products = updated;
    } finally {
      isSaving = false;
      _notify();
    }
  }

  String _encode(List<Product> products) => jsonEncode({
    'version': 1,
    'products': products.map((p) => p.toJson()).toList(),
  });
}
