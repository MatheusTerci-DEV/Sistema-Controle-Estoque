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

  bool matches(String query) {
    final term = query.trim().toLowerCase();
    return [
      partNumber,
      name,
      category,
    ].any((value) => value.toLowerCase().contains(term));
  }
}
