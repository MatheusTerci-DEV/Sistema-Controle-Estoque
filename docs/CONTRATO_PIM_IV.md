# Contrato técnico do PIM IV — PIM Estoque

Fonte única de verdade para API, banco, web, mobile e documento acadêmico. Qualquer mudança aqui deve ser refletida em todas as partes.

## Organização (Etapa 1)

Empresa fictícia (o PIM III não nomeou a organização; o grupo pode renomear):

- **Razão social:** Fixar Manutenção e Instalações Ltda. — nome fantasia **Fixar Manutenção**
- **Local:** Sorocaba/SP; pequena empresa (≈ 25 colaboradores)
- **Segmento:** manutenção predial e instalações elétricas/hidráulicas para condomínios e comércios
- **Almoxarifado:** materiais gerais — consumíveis, fixadores, EPIs, ferramentas, material elétrico, hidráulico e de limpeza
- **Estrutura:** Diretoria; Administrativo/Financeiro (compras); Operações (técnicos de campo, encarregados); Almoxarifado (1 almoxarife)
- **Problema:** controle em planilha e papel, saldo divergente, falta de material na obra, sem histórico de quem retirou, compras emergenciais caras
- **Solução:** PIM Estoque — API ASP.NET Core + painel web administrativo + app Flutter para técnicos e almoxarife

## Equipe

| RA | Nome | Papel |
| --- | --- | --- |
| H76DJJ6 | Vinnicius Gabriel M. dos Santos | Líder / Product Owner / backend |
| R661946 | Hendryo Batista Sarmento | Scrum Master / banco de dados |
| H32CIA9 | Lucas Alcântara Leal | Mobile Flutter |
| T319595 | Matheus Terci | Web / DevOps |

Curso: CST em Análise e Desenvolvimento de Sistemas — UNIP, 2026/2, PIM IV.

## Perfis de acesso

`Administrador` (tudo, inclusive usuários), `Operador` (produtos, movimentações, fornecedores), `Consulta` (somente leitura).

## Banco de dados (SQL Server, schema dbo)

| Tabela | Colunas |
| --- | --- |
| Usuarios | Id int PK identity; Nome nvarchar(100); Email nvarchar(120) UNIQUE; SenhaHash nvarchar(200); Perfil nvarchar(20) CHECK IN ('Administrador','Operador','Consulta'); Ativo bit default 1; CriadoEmUtc datetime2 |
| Fornecedores | Id int PK identity; Nome nvarchar(100); Cnpj char(14) UNIQUE (14 dígitos); Telefone nvarchar(20) null; Email nvarchar(120) null; Ativo bit default 1 |
| Produtos | (existente) Id, PartNumber nvarchar(8) UNIQUE (8 dígitos, prefixo 47/48/84/86), NomeProduto nvarchar(100), Categoria nvarchar(60), Unit nvarchar(3) IN UN/PC/PAR/CX/PCT/RL, Location nvarchar(60), MinimumStock int, Saldo int ≥ 0 |
| Movimentacoes | (existente) Id bigint PK; ProdutoId FK; Quantidade int ≠ 0 (positivo = entrada, negativo = saída); Motivo nvarchar(150); CriadaEmUtc datetime2; **UsuarioId int null FK Usuarios**; **FornecedorId int null FK Fornecedores** |
| AuditoriaProdutos | Id bigint PK; ProdutoId int; Operacao char(1) I/U/D; Dados nvarchar(max) (JSON do registro); AlteradoEmUtc datetime2 default SYSUTCDATETIME() — preenchida só por trigger |

- Triggers: `trg_Produtos_Auditoria` (AFTER INSERT/UPDATE/DELETE em Produtos → AuditoriaProdutos); `trg_Movimentacoes_Imutavel` (INSTEAD OF UPDATE, DELETE → THROW; histórico não se altera).
- Procedures: `sp_RegistrarMovimentacao(@ProdutoId,@Tipo,@Quantidade,@Motivo,@UsuarioId,@FornecedorId)` (transação, UPDLOCK, recusa saldo insuficiente), `sp_ProdutosParaReposicao`, `sp_ResumoEstoque`, `sp_ExtratoProduto(@ProdutoId,@De,@Ate)`.
- View: `vw_SaldoPorCategoria`.
- A API grava pelo EF Core (mesma regra da procedure); por causa das triggers, o EF precisa declarar `HasTrigger(...)` nas entidades Produto e Movimentacao. A trigger de auditoria **não** altera saldo — não há dupla contagem.

## API REST (JSON camelCase, prefixo /api)

Autenticação JWT Bearer. Tudo exige token, exceto `POST /api/auth/login` e `GET /health`.

| Método | Rota | Perfil | Corpo / resposta |
| --- | --- | --- | --- |
| POST | /api/auth/login | público | `{email, senha}` → `{token, expiraEmUtc, usuario:{id,nome,email,perfil}}`; 401 se inválido |
| GET | /api/auth/me | autenticado | `{id,nome,email,perfil}` |
| GET | /api/produtos?busca=&reposicao= | autenticado | lista de produtos |
| GET | /api/produtos/{id} | autenticado | produto |
| POST/PUT | /api/produtos[/{id}] | Administrador, Operador | `{partNumber,nomeProduto,categoria,unit,location,minimumStock}` |
| DELETE | /api/produtos/{id} | Administrador | 409 se houver movimentações |
| GET | /api/movimentacoes?produtoId= | autenticado | `[{id,produtoId,quantidade,motivo,criadaEmUtc,usuarioNome,fornecedorNome}]` (100 mais recentes) |
| POST | /api/movimentacoes | Administrador, Operador | `{produtoId,quantidade,tipo:"entrada"|"saida",motivo,fornecedorId?}`; usuário vem do token; 409 saldo insuficiente |
| GET | /api/dashboard/resumo | autenticado | `{totalProdutos,itensReposicao,saldoTotal,movimentacoesHoje,porCategoria:[{categoria,produtos,saldo}]}` |
| GET/POST/PUT | /api/fornecedores[/{id}] | leitura: autenticado; escrita: Administrador, Operador | `{nome,cnpj,telefone,email,ativo}` |
| GET/POST/PUT | /api/usuarios[/{id}] | Administrador | `{nome,email,senha?,perfil,ativo}`; nunca devolve hash |

Senhas: PBKDF2-SHA256 (100 000 iterações, salt aleatório) em `SenhaHash` no formato `iteracoes.saltBase64.hashBase64`.

Usuário inicial de demonstração (somente Development/Docker, via configuração `Seed:AdminEmail` / `Seed:AdminSenha`): `admin@fixar.com.br` / `Admin@123`.

## Arquitetura em camadas (.NET 8)

`Controllers/` (HTTP) → `Services/` (regras de negócio) → `Data/` (EF Core DbContext) → SQL Server. `Models/` (entidades de domínio), `Contracts/` (DTOs de entrada/saída com validação). Painel web administrativo estático em `wwwroot/` consumindo a mesma API. App Flutter em `mobile/` consumindo a mesma API.

## Infraestrutura

`Dockerfile` (API multi-stage), `docker-compose.yml` (api + sqlserver 2022 + init com `database/*.sql`), GitHub Actions (testes da API, testes Flutter, Pages). Plano de nuvem: Azure App Service for Containers / Azure SQL Database / Azure Container Registry / Application Insights / Key Vault.
