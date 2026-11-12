import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'auth_storage.dart';

AuthStorage createPlatformAuthStorage() => _FileAuthStorage();

class _FileAuthStorage implements AuthStorage {
  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}/pim_auth_v1.json');
  }

  @override
  Future<String?> read() async {
    final file = await _file;
    return file.existsSync() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String value) async => (await _file).writeAsString(value);

  @override
  Future<void> clear() async {
    final file = await _file;
    if (file.existsSync()) await file.delete();
  }
}
