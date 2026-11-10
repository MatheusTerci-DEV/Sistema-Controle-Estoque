import 'package:pim_estoque/features/products/product_storage.dart';

class MemoryProductStorage implements ProductStorage {
  MemoryProductStorage([this.content]);

  String? content;
  bool failWrite = false;
  bool failRead = false;
  int writes = 0;

  @override
  Future<String?> read() async {
    if (failRead) throw StateError('Falha simulada na leitura');
    return content;
  }

  @override
  Future<void> write(String value) async {
    if (failWrite) throw StateError('Falha simulada na gravação');
    writes++;
    content = value;
  }
}
