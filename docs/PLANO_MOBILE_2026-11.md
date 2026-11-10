# PIM Estoque — evolução mobile | novembro de 2026

## Direção

Criar um aplicativo Flutter em Dart para o PIM Estoque, com foco inicial em Android. Evoluir por entregas pequenas, cada uma com commit próprio. A API .NET e o SQL Server continuam sendo a opção de integração; o aplicativo não acessará o banco diretamente.

## Diagnóstico do repositório em 10/11/2026

A branch main contém oito arquivos. Program.cs referencia PimEstoque.Data e PimEstoque.Services, mas essas pastas não estão na versão atual. Controllers, Models, Migrations e Views também estão ausentes. Portanto, a API atual não está pronta para compilar nem para conectar o aplicativo.

O commit histórico 3c5da55 contém essas pastas sob sistema-controle-estoque/. Elas foram removidas no commit 716746c. A recuperação e validação do backend devem ser uma entrega própria, evitando presumir que a API esteja disponível.

O modelo histórico de produto tem Id, PartNumber, NomeProduto e Categoria; não tem saldo, estoque mínimo ou localização. Esses campos precisam de modelagem e migração antes de apresentar valores reais no mobile.

## Entregas

- [x] Diagnóstico e plano de migração.
- [x] Base Flutter: projeto Android, tema e navegação.
- [x] Consulta inicial de produtos, pesquisa e detalhes usando demonstração explícita.
- [ ] Recuperar e validar a API .NET a partir do histórico.
- [ ] Integrar consulta de produtos com tratamento de carregamento, falha e lista vazia.
- [ ] Cadastro e edição de produtos com validações.
- [ ] Modelar saldo, endereços e movimentações; definir regras e persistência.
- [ ] Recebimento, armazenagem, transferências e consultas.
- [ ] Autenticação, testes de integração e validação no aparelho.
- [ ] Preparar APK e documentação da entrega acadêmica.

## Critérios desta primeira etapa

O app deve abrir, permitir navegar entre início e produtos, pesquisar por nome, part number ou categoria e visualizar detalhes. Dados de demonstração devem estar identificados. Não deve simular login, leitura de código de barras, persistência ou operações que ainda não existem.

## Verificação

Executar flutter analyze e flutter test. O build e a instalação Android dependem do Android SDK. Registrar quais verificações foram executadas, sem tratar análise estática como validação em aparelho.

## Resultado da primeira etapa — 10/11/2026

- Flutter 3.47.9 / Dart 3.13.7.
- flutter analyze --no-pub: sem problemas.
- flutter test --no-pub: 3 testes aprovados (pesquisa, fluxo de consulta/detalhes e navegação com tela pequena e texto ampliado).
- Android SDK ausente neste ambiente: APK e instalação em aparelho ainda não validados.
- API e SQL Server não foram executados nem alterados.
