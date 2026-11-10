import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'demo_products.dart';
import 'product.dart';
import 'product_storage.dart';
import 'stock_movement.dart';

class ProductCatalog extends ChangeNotifier {
  ProductCatalog(this.storage);

  final ProductStorage storage;
  List<Product> _products = [];
  List<StockMovement> _movements = [];
  List<StockMovement> get movements => List.unmodifiable(_movements.reversed);
  int balance(int productId) => _movements
      .where((m) => m.productId == productId)
      .fold(0, (sum, m) => sum + m.quantity);
  bool needsReplenishment(Product product) =>
      product.minimumStock > 0 && balance(product.id) <= product.minimumStock;
  List<Product> get replenishment =>
      _products.where(needsReplenishment).toList();
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
      List<StockMovement> loadedMovements = [];
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
          final old = row['partNumber'];
          const demoCodes = {
            'PIM-1001': '47000001',
            'PIM-1002': '47000002',
            'PIM-2001': '48000001',
            'PIM-2002': '48000002',
            'PIM-2003': '48000003',
            'PIM-3001': '84000001',
            'PIM-4001': '86000001',
            'PIM-5001': '86000002',
          };
          final replacement = demoCodes[old];
          final collision =
              replacement != null &&
              (data['products'] as List).any(
                (other) => other is Map && other['partNumber'] == replacement,
              );
          // Manter o id, unidade e histórico; não criar colisão com códigos existentes.
          return Product.fromJson(
            replacement == null || collision
                ? row
                : {...row, 'partNumber': replacement},
          );
        }).toList();
        if (loaded.map((p) => p.id).toSet().length != loaded.length ||
            loaded.map((p) => p.partNumber.toUpperCase()).toSet().length !=
                loaded.length) {
          throw const FormatException('Materiais duplicados no arquivo.');
        }
        final rows = data['movements'] ?? [];
        if (rows is! List) throw const FormatException('Histórico inválido.');
        final running = <int, int>{};
        loadedMovements = rows.map((row) {
          if (row is! Map<String, dynamic>) {
            throw const FormatException('Histórico inválido.');
          }
          final movement = StockMovement.fromJson(row);
          if (!loaded.any((p) => p.id == movement.productId)) {
            throw const FormatException('Produto ausente.');
          }
          final saldo = (running[movement.productId] ?? 0) + movement.quantity;
          if (saldo < 0) {
            throw const FormatException('Saldo inválido no histórico.');
          }
          running[movement.productId] = saldo;
          return movement;
        }).toList();
      }
      _movements = loadedMovements;
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
    if (!Product.validPartNumber(text)) {
      return 'Use 8 dígitos, começando por 47, 48, 84 ou 86.';
    }
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
    String? unit,
    int? minimumStock,
    String? location,
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
    final previous = id == null
        ? null
        : _products.firstWhere((p) => p.id == id);
    final selectedUnit = unit ?? previous?.unit ?? 'UN';
    final minimum = minimumStock ?? previous?.minimumStock ?? 0;
    final selectedLocation = (location ?? previous?.location ?? '').trim();
    if (!Product.units.contains(selectedUnit) ||
        minimum < 0 ||
        minimum > 999999999 ||
        selectedLocation.length > 60) {
      throw const FormatException(
        'Confira unidade, estoque mínimo e localização.',
      );
    }
    if (previous != null &&
        selectedUnit != previous.unit &&
        _movements.any((m) => m.productId == id)) {
      throw const FormatException(
        'A unidade não pode ser alterada após movimentações.',
      );
    }
    final nextId =
        _products.fold<int>(0, (max, p) => p.id > max ? p.id : max) + 1;
    final product = Product(
      id: id ?? nextId,
      partNumber: partNumber.trim().toUpperCase(),
      name: name.trim(),
      category: category.trim(),
      unit: selectedUnit,
      minimumStock: minimum,
      location: selectedLocation,
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

  Future<void> moveStock({
    required int productId,
    required int quantity,
    required bool incoming,
    required String reason,
  }) async {
    if (!isReady || isLoading || isSaving) {
      throw StateError('Catálogo indisponível.');
    }
    if (!_products.any((p) => p.id == productId)) {
      throw const FormatException('Selecione um material válido.');
    }
    if (_products.firstWhere((p) => p.id == productId).needsCodeReview) {
      throw const FormatException(
        'Atualize o part number deste material para o padrão de 8 dígitos antes de movimentar.',
      );
    }
    if (quantity <= 0 || quantity > 999999999) {
      throw const FormatException(
        'Informe uma quantidade inteira entre 1 e 999999999.',
      );
    }
    if (reason.trim().isEmpty || reason.trim().length > 150) {
      throw const FormatException('Informe o motivo com até 150 caracteres.');
    }
    if (!incoming && quantity > balance(productId)) {
      throw const FormatException('Saldo insuficiente para esta saída.');
    }
    final updated = [
      ..._movements,
      StockMovement(
        productId: productId,
        quantity: incoming ? quantity : -quantity,
        reason: reason.trim(),
        createdAt: DateTime.now().toUtc(),
      ),
    ];
    isSaving = true;
    _notify();
    try {
      await storage.write(_encode(_products, movements: updated));
      _movements = updated;
    } finally {
      isSaving = false;
      _notify();
    }
  }

  String _encode(List<Product> products, {List<StockMovement>? movements}) =>
      jsonEncode({
        'version': 1,
        'movements': (movements ?? _movements).map((m) => m.toJson()).toList(),
        'products': products.map((p) => p.toJson()).toList(),
      });
}
