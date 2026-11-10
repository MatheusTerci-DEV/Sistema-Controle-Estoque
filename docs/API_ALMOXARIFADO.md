# API do almoxarifado — primeira estrutura

Backend na raiz do repositório: C#/.NET 8, ASP.NET Core, EF Core e SQL Server. A referência antiga a Services/MVC foi removida; agora a raiz é uma API independente do Flutter.

## Estado

A API está estruturada para execução local. O frontend do Pages continua usando armazenamento local: **não está conectado a esta API**. Autenticação, isolamento por empresa, idempotência de movimentações e implantação do backend ainda são próximos passos antes de disponibilizar acesso público. Não há dados de produção inseridos nem alterações aplicadas a bancos existentes.

## Contrato

Part number é string com exatamente 8 dígitos ASCII, prefixo 47, 48, 84 ou 86. A API não gera automaticamente códigos de materiais reais. Não aceita códigos alfanuméricos, prefixos diferentes, espaço ou quebra de linha. No Flutter, espaços nas extremidades são normalizados antes da validação; no JSON da API envie o código já normalizado.

| Método | Rota | Comportamento |
| --- | --- | --- |
| GET | /health | Processo ativo; informa que não verificou o banco |
| GET | /api/produtos | Busca opcional `busca`, filtro `reposicao=true`; até 500 resultados |
| GET | /api/produtos/{id} | Material ou 404 |
| POST | /api/produtos | Criar, saldo inicial zero; 201, 400 ou 409 |
| PUT | /api/produtos/{id} | Editar metadados, preservando saldo; unidade bloqueada após movimentação |
| GET | /api/movimentacoes | Últimas 100; filtro opcional `produtoId` |
| POST | /api/movimentacoes | Entrada ou saída com atualização condicional de saldo e histórico na mesma transação |

Produto:

```json
{"partNumber":"47000001","nomeProduto":"Parafuso M10","categoria":"Fixadores","unit":"PC","location":"A-01-02","minimumStock":10}
```

Movimentação:

```json
{"produtoId":1,"quantidade":20,"tipo":"entrada","motivo":"Recebimento NF 123"}
```

Saída usa `tipo: "saida"`. Quantidade deve ser inteira de 1 a 999999999. O servidor calcula o sinal. Saldo não pode ficar negativo nem ultrapassar 999999999. Não há endpoint para sobrescrever saldo ou excluir histórico. Uma repetição da mesma requisição ainda pode registrar outra movimentação: idempotência será tratada na integração.

## Executar localmente

1. Instalar .NET SDK 8 e SQL Server.
2. Usar um banco novo e revisar/aplicar `database/001_almoxarifado.sql`. O script recusa tabelas existentes; migração de um banco antigo exige plano específico.
3. Configurar `ConnectionStrings__DefaultConnection` por variável de ambiente ou User Secrets. A configuração existente usa SQL Express e autenticação Windows; não colocar senhas no Git.
4. Na raiz, executar:

```bash
dotnet restore PimEstoque.csproj
dotnet run --project PimEstoque.csproj --launch-profile api
```

Swagger em `http://127.0.0.1:5080/swagger`; health em `http://127.0.0.1:5080/health`. O script SQL não é executado automaticamente na inicialização.

CORS é fechado por padrão. Quando houver integração, definir a lista `Cors:Origins` na configuração; origem do Pages é `https://matheusterci-dev.github.io` (sem caminho). CORS não substitui autenticação ou autorização.

## Verificação

```bash
dotnet test Tests/PimEstoque.Tests.csproj --configuration Release
```

Testes HTTP com WebApplicationFactory e SQLite em memória verificam os quatro prefixos, códigos inválidos, duplicidade, consulta, entrada/saída, saldo insuficiente, unidade bloqueada e quantidades inválidas. O script e as particularidades do SQL Server ainda exigem validação contra um SQL Server real. Não tratar testes SQLite como prova de concorrência ou da migração no SQL Server.

## Dados locais anteriores

Os oito códigos conhecidos dos exemplos `PIM-*` são compatibilizados para códigos numéricos, mantendo id, dados e movimentos. Se o novo código já existir, o antigo é preservado para revisão. Códigos personalizados fora do padrão são mantidos e sinalizados nos detalhes; edite o material para atribuir o código correto. Novas movimentações desses materiais ficam bloqueadas até a correção. Não há importação automática dos dados locais para a API.
