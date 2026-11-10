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
    final id = data['productId'];
    final quantity = data['quantity'];
    final reason = data['reason'];
    final date = DateTime.tryParse(
      data['createdAt'] is String ? data['createdAt'] as String : '',
    );
    if (id is! int ||
        id <= 0 ||
        quantity is! int ||
        quantity == 0 ||
        reason is! String ||
        reason.trim().isEmpty ||
        reason.length > 150 ||
        date == null) {
      throw const FormatException('Movimentação inválida.');
    }
    return StockMovement(
      productId: id,
      quantity: quantity,
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
}
