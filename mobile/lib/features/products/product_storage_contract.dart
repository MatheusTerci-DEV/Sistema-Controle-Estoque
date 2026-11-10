abstract interface class ProductStorage {
  Future<String?> read();
  Future<void> write(String content);
}
