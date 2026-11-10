import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pim_estoque/features/products/product_catalog.dart';
import 'package:pim_estoque/features/products/product_storage.dart';

import 'support/memory_product_storage.dart';

void main() {
  test('carrega oito materiais apenas na primeira abertura', () async {
    final storage = MemoryProductStorage();
    final first = ProductCatalog(storage);
    final second = ProductCatalog(storage);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await first.load();
    expect(first.products.length, 8);
    expect(first.products.map((p) => p.partNumber).toSet().length, 8);
    expect(first.products.map((p) => p.category).toSet().length, 5);
    await second.load();
    expect(storage.writes, 1);
    expect(second.products.length, 8);
  });

  test(
    'cria e edita material preservando id após reabrir arquivo real',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'pim_catalog_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final storage = FileProductStorage(directory: () async => directory);
      final first = ProductCatalog(storage);
      addTearDown(first.dispose);
      await first.load();
      await first.save(
        partNumber: '  pim-9001  ',
        name: '  Sensor  ',
        category: '  Elétrica  ',
      );
      final created = first.products.last;
      expect(created.partNumber, 'PIM-9001');
      expect(created.name, 'Sensor');
      await first.save(
        id: created.id,
        partNumber: 'pim-9001',
        name: 'Sensor de pressão',
        category: 'Elétrica',
      );
      final reopened = ProductCatalog(
        FileProductStorage(directory: () async => directory),
      );
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.products.length, 9);
      expect(reopened.products.last.id, created.id);
      expect(reopened.products.last.name, 'Sensor de pressão');
      expect(
        await File('${directory.path}/pim_products_v1.json.tmp').exists(),
        isFalse,
      );
    },
  );

  test(
    'recusa part number duplicado sem diferenciar caixa ou espaços',
    () async {
      final storage = MemoryProductStorage();
      final catalog = ProductCatalog(storage);
      addTearDown(catalog.dispose);
      await catalog.load();
      await expectLater(
        catalog.save(
          partNumber: '  pim-1001 ',
          name: 'Outro filtro',
          category: 'Filtros',
        ),
        throwsFormatException,
      );
      await expectLater(
        catalog.save(
          id: 2,
          partNumber: 'PIM-1001',
          name: 'Filtro',
          category: 'Filtros',
        ),
        throwsFormatException,
      );
      expect(catalog.products.length, 8);
      expect(storage.writes, 1);
    },
  );

  test('recusa campos vazios e limites inválidos sem gravar', () async {
    final storage = MemoryProductStorage();
    final catalog = ProductCatalog(storage);
    addTearDown(catalog.dispose);
    await catalog.load();
    for (final fields in [
      ['', 'Nome', 'Categoria'],
      ['PN', '   ', 'Categoria'],
      ['PN', 'Nome', ' '],
      ['P' * 51, 'Nome', 'Categoria'],
      ['PN', 'N' * 101, 'Categoria'],
      ['PN', 'Nome', 'C' * 61],
    ]) {
      await expectLater(
        catalog.save(
          partNumber: fields[0],
          name: fields[1],
          category: fields[2],
        ),
        throwsFormatException,
      );
    }
    expect(storage.writes, 1);
  });

  test(
    'falha ao salvar preserva catálogo anterior e permite nova tentativa',
    () async {
      final storage = MemoryProductStorage();
      final catalog = ProductCatalog(storage);
      addTearDown(catalog.dispose);
      await catalog.load();
      final before = storage.content;
      storage.failWrite = true;
      await expectLater(
        catalog.save(
          partNumber: 'PIM-9001',
          name: 'Sensor',
          category: 'Elétrica',
        ),
        throwsStateError,
      );
      expect(catalog.products.length, 8);
      expect(storage.content, before);
      expect(catalog.isSaving, isFalse);
      storage.failWrite = false;
      await catalog.save(
        partNumber: 'PIM-9001',
        name: 'Sensor',
        category: 'Elétrica',
      );
      expect(catalog.products.length, 9);
    },
  );

  test('catálogo corrompido não é substituído pelos exemplos', () async {
    for (final raw in [
      '{inválido',
      '{"version":2,"products":[]}',
      '{"version":1,"products":[{"id":1}]}',
      jsonEncode({
        'version': 1,
        'products': List.filled(2, {
          'id': 1,
          'partNumber': 'PN',
          'nomeProduto': 'Nome',
          'categoria': 'Categoria',
        }),
      }),
    ]) {
      final storage = MemoryProductStorage(raw);
      final catalog = ProductCatalog(storage);
      await catalog.load();
      expect(catalog.isReady, isFalse);
      expect(catalog.loadError, isNotNull);
      expect(storage.content, raw);
      expect(storage.writes, 0);
      catalog.dispose();
    }
  });

  test('catálogo vazio salvo permanece vazio', () async {
    final storage = MemoryProductStorage('{"version":1,"products":[]}');
    final catalog = ProductCatalog(storage);
    addTearDown(catalog.dispose);
    await catalog.load();
    expect(catalog.isReady, isTrue);
    expect(catalog.products, isEmpty);
    expect(storage.writes, 0);
  });

  test(
    'erro de leitura pode ser recuperado sem gravar enquanto indisponível',
    () async {
      final storage = MemoryProductStorage()..failRead = true;
      final catalog = ProductCatalog(storage);
      addTearDown(catalog.dispose);
      await catalog.load();
      expect(catalog.isReady, isFalse);
      await expectLater(
        catalog.save(partNumber: 'PN', name: 'Nome', category: 'Categoria'),
        throwsStateError,
      );
      expect(storage.writes, 0);
      storage.failRead = false;
      await catalog.load();
      expect(catalog.isReady, isTrue);
    },
  );

  test(
    'bloqueia gravações simultâneas para evitar perda de alterações',
    () async {
      final storage = DelayedStorage();
      final catalog = ProductCatalog(storage);
      addTearDown(catalog.dispose);
      await catalog.load();
      storage.delay = Completer<void>();
      final saving = catalog.save(
        partNumber: 'PN-A',
        name: 'A',
        category: 'Teste',
      );
      await expectLater(
        catalog.save(partNumber: 'PN-B', name: 'B', category: 'Teste'),
        throwsStateError,
      );
      storage.delay!.complete();
      await saving;
      expect(catalog.products.length, 9);
    },
  );
}

class DelayedStorage extends MemoryProductStorage {
  Completer<void>? delay;

  @override
  Future<void> write(String content) async {
    if (delay != null) await delay!.future;
    await super.write(content);
  }
}
