class StockMovement {
  const StockMovement({
    required this.productId,
    required this.quantity,
    required this.reason,
    required this.createdAt,
  });
  final int productId;

  /// Positivo para entrada e negativo para saída; nesta etapa, unidades inteiras.
  final int quantity;
  final String reason;
  final DateTime createdAt;

  factory StockMovement.fromJson(Map<String, dynamic> data) {
    final id = data['productId'] ?? data['produtoId'];
    final rawQuantity = data['quantity'] ?? data['quantidade'];
    final type = data['tipo'];
    final quantity = rawQuantity is int
        ? rawQuantity
        : (rawQuantity is num ? rawQuantity.toInt() : null);
    final normalizedQuantity = type == 'saida' && quantity != null
        ? -quantity.abs()
        : quantity;
    final reason = data['reason'] ?? data['motivo'];
    final rawDate = data['createdAt'] ?? data['criadaEmUtc'];
    final date = DateTime.tryParse(rawDate is String ? rawDate : '');
    if (id is! int ||
        id <= 0 ||
        normalizedQuantity is! int ||
        normalizedQuantity == 0 ||
        reason is! String ||
        reason.trim().isEmpty ||
        reason.length > 150 ||
        date == null) {
      throw const FormatException('Movimentação inválida.');
    }
    return StockMovement(
      productId: id,
      quantity: normalizedQuantity,
      reason: reason,
      createdAt: date,
    );
  }

  Map<String, Object> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
  };

  Map<String, Object> toApiJson() => {
    'produtoId': productId,
    'quantidade': quantity.abs(),
    'tipo': quantity > 0 ? 'entrada' : 'saida',
    'motivo': reason,
  };
}
