# API do almoxarifado e painel web

Backend na raiz do repositório: C#/.NET 8, ASP.NET Core, EF Core e SQL Server. Contrato completo (tabelas, perfis, rotas) em [CONTRATO_PIM_IV.md](CONTRATO_PIM_IV.md); banco em [database/README.md](../database/README.md).

## Arquitetura em camadas

| Pasta | Responsabilidade |
| --- | --- |
| `Controllers/` | HTTP: rotas, `[Authorize]` por perfil, códigos de status. Sem regra de negócio. |
| `Services/` | Regras de negócio (`ProdutoService`, `MovimentacaoService`, `FornecedorService`, `UsuarioService`, `AuthService`, `DashboardService`), hash de senha (`SenhaHasher`) e `ErroNegocio` (vira `{message}` com 400/404/409). |
| `Data/` | `PimEstoqueContext` (EF Core): tamanhos, índices únicos, FKs e `HasTrigger` das triggers do banco. |
| `Models/` | Entidades `Produto`, `Movimentacao`, `Usuario`, `Fornecedor` e os perfis. |
| `Contracts/` | DTOs de entrada (com validação) e de saída. |
| `wwwroot/` | Painel administrativo (HTML + CSS + JavaScript puro) servido pela própria API. |

## Autenticação e perfis

JWT Bearer. `POST /api/auth/login` com `{email, senha}` devolve `{token, expiraEmUtc, usuario}`; envie `Authorization: Bearer <token>` nas demais rotas. Só `/api/auth/login`, `/health` e os arquivos do painel são públicos. Usuário desativado perde o acesso imediatamente, mesmo com token válido.

| Perfil | Pode |
| --- | --- |
| Administrador | tudo, inclusive usuários e exclusão de material sem histórico |
| Operador | ler; cadastrar/editar materiais e fornecedores; registrar movimentações |
| Consulta | somente leitura |

Senhas: PBKDF2-SHA256, 100 000 iterações, salt aleatório de 16 bytes, gravadas como `iteracoes.saltBase64.hashBase64`; a API nunca devolve o hash.

Configuração (`appsettings` ou variáveis de ambiente com `__`):

| Chave | Uso |
| --- | --- |
| `ConnectionStrings:DefaultConnection` | SQL Server |
| `Jwt:Key` | chave HMAC, **mínimo 32 bytes**; sem ela a API não inicia. A de `appsettings.Development.json` é só para desenvolvimento. |
| `Jwt:Issuer`, `Jwt:ExpiraEmMinutos` | emissor/audiência (padrão `PimEstoque`) e validade (padrão 480) |
| `Seed:AdminEmail`, `Seed:AdminSenha` | cria o administrador inicial se a tabela `Usuarios` estiver vazia (Development/Docker: `admin@fixar.com.br` / `Admin@123`) |
| `Cors:Origins` | origens liberadas; vazio = fechado |

## Rotas

| Método | Rota | Perfil | Comportamento |
| --- | --- | --- | --- |
| GET | /health | público | processo ativo; não verifica o banco |
| POST | /api/auth/login | público | token; 401 se e-mail/senha inválidos ou usuário inativo |
| GET | /api/auth/me | autenticado | `{id,nome,email,perfil,ativo}` |
| GET | /api/dashboard/resumo | autenticado | `{totalProdutos,itensReposicao,saldoTotal,movimentacoesHoje,porCategoria}` ("hoje" = dia UTC) |
| GET | /api/produtos?busca=&reposicao=true | autenticado | até 500; `reposicao` = `MinimumStock > 0 AND Saldo <= MinimumStock` |
| GET | /api/produtos/{id} | autenticado | material ou 404 |
| POST / PUT | /api/produtos[/{id}] | Administrador, Operador | saldo inicial zero e preservado na edição; unidade bloqueada após movimentação; 409 part number duplicado |
| DELETE | /api/produtos/{id} | Administrador | 204; 409 se houver movimentações |
| GET | /api/movimentacoes?produtoId= | autenticado | 100 mais recentes com `usuarioNome` e `fornecedorNome` |
| POST | /api/movimentacoes | Administrador, Operador | usuário vem do token; 404 material, 400 fornecedor inexistente/inativo, 409 saldo insuficiente |
| GET / POST / PUT | /api/fornecedores[/{id}] | leitura: autenticado; escrita: Administrador, Operador | CNPJ com 14 dígitos, único (409) |
| GET / POST / PUT | /api/usuarios[/{id}] | Administrador | senha obrigatória na criação; em branco na edição mantém a atual; e-mail único (409); o administrador não pode desativar nem rebaixar a si mesmo |

Exemplos:

```json
{"partNumber":"47000001","nomeProduto":"Parafuso M10","categoria":"Fixadores","unit":"PC","location":"A-01-02","minimumStock":10}
{"produtoId":1,"quantidade":20,"tipo":"entrada","motivo":"Recebimento NF 123","fornecedorId":1}
```

Part number: exatamente 8 dígitos ASCII com prefixo 47, 48, 84 ou 86. Quantidade inteira de 1 a 999999999; o servidor calcula o sinal. O saldo é atualizado de forma condicional (nunca negativo, nunca acima de 999999999) na mesma transação que grava o histórico, a mesma regra da `sp_RegistrarMovimentacao`. Histórico não tem edição nem exclusão (a trigger `trg_Movimentacoes_Imutavel` também impede no banco). Repetir a mesma requisição registra outra movimentação (sem idempotência).

## Painel web

`http://<host>/` abre o painel: login, painel com indicadores e saldo por categoria, materiais (cadastro, edição, busca e filtro "para repor", exclusão para Administrador), movimentações (entrada/saída e histórico), fornecedores e usuários (somente Administrador). O token fica em `sessionStorage` (some ao fechar a aba). Acessibilidade: `lang="pt-BR"`, rótulos em todos os campos, foco visível, link "Pular para o conteúdo", navegação por teclado, mensagens em região `aria-live`, situação "Repor" escrita (não só por cor) e contraste AA.

Cabeçalhos de segurança em todas as respostas: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer` e `Content-Security-Policy` com `default-src 'self'; frame-ancestors 'none'` (exceto no Swagger, que usa script inline).

## Executar

**Docker (API + SQL Server 2022 + scripts do banco):**

```bash
docker compose up --build
```

Painel em `http://localhost:8080`, Swagger em `http://localhost:8080/swagger`. O serviço `db-init` cria o banco `PimEstoque` e aplica `database/0*.sql` em ordem antes de a API subir. Senha do `sa` e chave JWT do `docker-compose.yml` são exemplos de desenvolvimento; troque com `MSSQL_SA_PASSWORD` e `JWT_KEY`.

**Local:** aplicar os scripts conforme [database/README.md](../database/README.md), configurar `ConnectionStrings__DefaultConnection` (o padrão usa SQL Express com autenticação Windows) e:

```bash
dotnet run --project PimEstoque.csproj --launch-profile api
```

Painel em `http://127.0.0.1:5080`, Swagger em `http://127.0.0.1:5080/swagger` (botão **Authorize** aceita o token). `PimEstoque.http` tem as chamadas prontas.

## Verificação

```bash
dotnet test Tests/PimEstoque.Tests.csproj --configuration Release
```

Testes HTTP com WebApplicationFactory e SQLite em memória: prefixos e códigos inválidos, duplicidade, entrada/saída, saldo insuficiente, unidade bloqueada, quantidades inválidas, 401 sem token, 403 por perfil (Consulta e Operador), login/`me`, usuários (sem expor hash, autoproteção do administrador, desativação corta o token), fornecedores e vínculo na entrada, exclusão de material, dashboard, formato do hash PBKDF2 e recusa de iniciar sem chave JWT. SQLite ignora triggers e procedures: concorrência e objetos do SQL Server são validados com `database/tests/validacao.sql` e pelo `docker compose`.
