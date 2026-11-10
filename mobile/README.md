# PIM Estoque Mobile

Aplicativo Flutter/Dart para Android e navegador. Entrega de 10/11/2026 para demonstração acadêmica: consulta, cadastro e edição de materiais com persistência local.

## Funcionalidades

- Oito materiais fictícios na primeira abertura: filtros, fixadores, rolamento, correia e mangueira.
- Pesquisa por nome, part number ou categoria e consulta de detalhes.
- Cadastro e edição, com campos obrigatórios e limites de tamanho.
- Part number único, ignorando caixa e espaços nas extremidades; salvo em maiúsculas.
- Totais de produtos e categorias atualizados no início.
- Android: gravação em arquivo JSON versionado no diretório do aplicativo.
- Web: gravação do mesmo catálogo no armazenamento local do navegador.
- Recuperação de falhas sem substituir dados existentes por exemplos.

O catálogo de exemplos é salvo apenas se o arquivo ainda não existir. As gravações usam um arquivo temporário, seguido de renomeação, e a interface só confirma o salvamento após a conclusão. As operações de gravação são serializadas pelo catálogo.

Os dados ficam somente no aparelho ou navegador usado: não há sincronização, autenticação ou conexão com a API. Limpar os dados, desinstalar o app ou apagar os dados do site pode remover os cadastros. Navegadores e aparelhos diferentes têm catálogos independentes; abas abertas simultaneamente não sincronizam alterações automaticamente. Saldo, endereços, exclusão e movimentações ainda não fazem parte desta entrega.

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

A automação `.github/workflows/mobile.yml` executa análise, testes e build Android somente quando solicitada manualmente. Quando a execução terminar com sucesso, o APK estará no artefato `pim-estoque-demo-android`, na aba Actions. O APK de debug é destinado a testes locais, não à publicação em loja.

## Organização

- `lib/app.dart`: carregamento, falha de abertura e navegação.
- `lib/features/home/`: resumo do catálogo salvo.
- `lib/features/products/product_catalog.dart`: validações, estado e operações.
- `lib/features/products/product_storage.dart`: persistência em arquivo.
- `lib/features/products/product_form_page.dart`: cadastro e edição.
- `lib/features/products/products_page.dart`: pesquisa e detalhes.
- `test/`: regras, persistência em arquivo real e fluxos de interface.

Consulte `../docs/APRESENTACAO_TESTES_MOBILE.md` para o roteiro de demonstração e `../docs/PLANO_MOBILE_2026-11.md` para as próximas entregas.

## Prévia web no GitHub Pages

O workflow `.github/workflows/pages.yml` publica a main no GitHub Pages após análise, testes e build. O repositório está configurado com Pages e origem **GitHub Actions**. As alterações são publicadas após integração à main, mantendo a regra do ambiente github-pages. A publicação usa o subcaminho `/Sistema-Controle-Estoque/`.

```bash
flutter build web --release --base-href /Sistema-Controle-Estoque/ --no-web-resources-cdn
```

O armazenamento é selecionado por importação condicional: arquivo no Android e `localStorage` na web. Os oito materiais de demonstração continuam sendo carregados somente se não existir um catálogo salvo. No celular, use o mesmo navegador para manter os cadastros entre acessos.
## API e navegação conectada

Use `--dart-define=API_URL=http://host:5080` para apontar para a API. O padrão é `http://10.0.2.2:5080` no Android e `http://127.0.0.1:5080` na web. O login de desenvolvimento do contrato é `admin@fixar.com.br` / `Admin@123`, quando o seed estiver habilitado.

O fluxo é: login → início → produtos → detalhes → movimentar; a aba Estoque registra entradas e saídas. `Sincronizar` envia a fila em ordem e mostra os pendentes. Erros 409 ficam para revisão e não são reenviados. Consulta pode ler, mas não vê ações de escrita. Sair remove a sessão; 401 retorna ao login.

No login, `Usar sem servidor (demonstração)` mantém a prévia local do GitHub Pages. No modo conectado, a última lista de produtos é mantida como cache offline.
