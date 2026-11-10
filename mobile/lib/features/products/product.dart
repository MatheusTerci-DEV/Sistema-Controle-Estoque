/// Campos existentes no modelo histórico da API .NET.
class Product {
  const Product({
    required this.id,
    required this.partNumber,
    required this.name,
    required this.category,
  });

  final int id;
  final String partNumber;
  final String name;
  final String category;

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final partNumber = json['partNumber'];
    final name = json['nomeProduto'];
    final category = json['categoria'];
    if (id is! int ||
        id <= 0 ||
        partNumber is! String ||
        partNumber.trim().isEmpty ||
        partNumber.length > 50 ||
        name is! String ||
        name.trim().isEmpty ||
        name.length > 100 ||
        category is! String ||
        category.trim().isEmpty ||
        category.length > 60) {
      throw const FormatException('Material salvo inválido.');
    }
    return Product(
      id: id,
      partNumber: partNumber.trim().toUpperCase(),
      name: name.trim(),
      category: category.trim(),
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'partNumber': partNumber,
    'nomeProduto': name,
    'categoria': category,
  };

  bool matches(String query) {
    final term = query.trim().toLowerCase();
    return [
      partNumber,
      name,
      category,
    ].any((value) => value.toLowerCase().contains(term));
  }
}
