# PIM Estoque Mobile

Primeira etapa mobile, iniciada em 10/11/2026. Aplicativo Flutter/Dart com foco em Android. Interface em português, Material 3 e navegação entre início e consulta de produtos.

## Disponível

- Catálogo de demonstração explicitamente identificado.
- Pesquisa por nome, part number ou categoria.
- Detalhes de produto e mensagem para busca sem resultados.
- Testes da pesquisa e do fluxo de navegação.

Não há conexão com API, persistência, autenticação ou movimentação de estoque nesta etapa. Reiniciar o app não altera o catálogo fictício. Os campos seguem o modelo histórico da API: Id, PartNumber, NomeProduto e Categoria.

## Executar

Base gerada com Flutter 3.47.9 / Dart 3.13.7 (canal stable). Instale uma versão compatível com o pubspec.yaml e o Android SDK. Na pasta mobile:

```bash
flutter doctor
flutter pub get
flutter devices
flutter run
```

## Verificar e gerar APK

```bash
flutter analyze
flutter test
flutter build apk --debug
```

O APK de debug é destinado a testes locais. Distribuição final e assinatura serão tratadas em outra etapa.

## Organização

```text
lib/
  main.dart
  app.dart
  core/app_theme.dart
  features/home/home_page.dart
  features/products/
    product.dart
    demo_products.dart
    products_page.dart
```

A evolução será feita em commits pequenos. Consulte ../docs/PLANO_MOBILE_2026-11.md para o diagnóstico da API e as próximas entregas.
