import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'product_storage_contract.dart';

ProductStorage createProductStorage() => FileProductStorage();

/// Arquivo privado do app. A substituição ocorre somente após a gravação completa.
class FileProductStorage implements ProductStorage {
  FileProductStorage({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directory;

  Future<File> _file() async {
    final directory = await _directory();
    await directory.create(recursive: true);
    return File('${directory.path}/pim_products_v1.json');
  }

  @override
  Future<String?> read() async {
    final file = await _file();
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String content) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(content, flush: true);
    await temporary.rename(file.path);
  }
}
