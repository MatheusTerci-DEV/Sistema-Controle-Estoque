/// Cadastro de material do almoxarifado; campos novos aceitam registros legados.
class Product {
  const Product({
    required this.id,
    required this.partNumber,
    required this.name,
    required this.category,
    this.unit = 'UN',
    this.minimumStock = 0,
    this.location = '',
  });

  final int id;
  final String partNumber;
  final String name;
  final String category;
  static const units = ['UN', 'PC', 'PAR', 'CX', 'PCT', 'RL'];
  final String unit;
  final int minimumStock;
  final String location;

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final partNumber = json['partNumber'];
    final name = json['nomeProduto'];
    final category = json['categoria'];
    final unit = json['unit'] ?? 'UN';
    final minimum = json['minimumStock'] ?? 0;
    final location = json['location'] ?? '';
    if (unit is! String ||
        !units.contains(unit) ||
        minimum is! int ||
        minimum < 0 ||
        minimum > 999999999 ||
        location is! String ||
        location.length > 60) {
      throw const FormatException('Dados de almoxarifado inválidos.');
    }
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
      unit: unit,
      minimumStock: minimum,
      location: location.trim(),
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'partNumber': partNumber,
    'nomeProduto': name,
    'categoria': category,
    'unit': unit,
    'minimumStock': minimumStock,
    'location': location,
  };

  bool matches(String query) {
    final term = query.trim().toLowerCase();
    return [
      partNumber,
      name,
      category,
      location,
    ].any((value) => value.toLowerCase().contains(term));
  }
}
