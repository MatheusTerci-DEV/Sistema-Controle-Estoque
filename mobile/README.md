# PIM Estoque Mobile

Aplicativo Flutter/Dart com foco em Android. Entrega de 10/11/2026 para demonstração acadêmica: consulta, cadastro e edição de materiais com persistência local.

## Funcionalidades

- Oito materiais fictícios na primeira abertura: filtros, fixadores, rolamento, correia e mangueira.
- Pesquisa por nome, part number ou categoria e consulta de detalhes.
- Cadastro e edição, com campos obrigatórios e limites de tamanho.
- Part number único, ignorando caixa e espaços nas extremidades; salvo em maiúsculas.
- Totais de produtos e categorias atualizados no início.
- Gravação local em arquivo JSON versionado no diretório de documentos do aplicativo.
- Recuperação de falhas sem substituir dados existentes por exemplos.

O catálogo de exemplos é salvo apenas se o arquivo ainda não existir. As gravações usam um arquivo temporário, seguido de renomeação, e a interface só confirma o salvamento após a conclusão. As operações de gravação são serializadas pelo catálogo.

Os dados ficam somente no aparelho: não há sincronização, autenticação ou conexão com a API. Limpar os dados ou desinstalar o app pode remover os cadastros. Saldo, endereços, exclusão e movimentações ainda não fazem parte desta entrega.

## Executar

Base validada com Flutter 3.47.9 / Dart 3.13.7. Instale uma versão compatível com o pubspec.yaml e o Android SDK. Na pasta mobile:

```bash
flutter doctor
flutter pub get
flutter run
```

## Verificar e gerar APK

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

A automação `.github/workflows/mobile.yml` executa análise, testes e build Android. Quando a execução terminar com sucesso, o APK estará no artefato `pim-estoque-demo-android`, na aba Actions. O APK de debug é destinado a testes locais, não à publicação em loja.

## Organização

- `lib/app.dart`: carregamento, falha de abertura e navegação.
- `lib/features/home/`: resumo do catálogo salvo.
- `lib/features/products/product_catalog.dart`: validações, estado e operações.
- `lib/features/products/product_storage.dart`: persistência em arquivo.
- `lib/features/products/product_form_page.dart`: cadastro e edição.
- `lib/features/products/products_page.dart`: pesquisa e detalhes.
- `test/`: regras, persistência em arquivo real e fluxos de interface.

Consulte `../docs/APRESENTACAO_TESTES_MOBILE.md` para o roteiro de demonstração e `../docs/PLANO_MOBILE_2026-11.md` para as próximas entregas.
