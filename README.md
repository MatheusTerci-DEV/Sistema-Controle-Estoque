# PIM Estoque — mobile em Flutter

Atualização iniciada em **10 de novembro de 2026**. O projeto está evoluindo para um aplicativo mobile em **Flutter/Dart** (Android e web), com entregas pequenas e commits separados.

## Aplicativo mobile

**Prévia online:** https://matheusterci-dev.github.io/Sistema-Controle-Estoque/

O aplicativo fica em [`mobile/`](mobile/README.md): início, oito materiais de demonstração, pesquisa, detalhes, cadastro e edição com persistência local. Os dados são salvos no aparelho ou no navegador, conforme a plataforma. Integração com a API e operações de estoque serão implementadas nas próximas entregas.

Veja o [roteiro de apresentação e testes](docs/APRESENTACAO_TESTES_MOBILE.md). A automação na aba Actions testa o app e publica a prévia web no GitHub Pages. A geração de APK fica disponível para execução manual.

```bash
cd mobile
flutter pub get
flutter run
```

Veja o [plano de novembro](docs/PLANO_MOBILE_2026-11.md) para a sequência de implementação e o diagnóstico do backend.

## Situação da API

A raiz contém a API .NET 8 em camadas (Controllers → Services → EF Core/SQL Server) com autenticação JWT e perfis Administrador/Operador/Consulta, cobrindo materiais, movimentações, fornecedores, usuários e painel-resumo, e o painel web administrativo em `wwwroot/` servido pela própria API. `docker compose up --build` sobe API, SQL Server 2022 e os scripts de `database/` (painel em `http://localhost:8080`, `admin@fixar.com.br` / `Admin@123`, só para demonstração). Veja [execução e rotas](docs/API_ALMOXARIFADO.md) e o [contrato do PIM IV](docs/CONTRATO_PIM_IV.md). O Pages continua sendo a versão histórica com armazenamento local.

A documentação abaixo descreve a versão web histórica; para executar a nova API use o documento acima.

---

# Sistema de Controle de Estoque

Aplicação web acadêmica para cadastrar, consultar, editar e excluir produtos de um estoque. O projeto reúne uma API REST em ASP.NET Core, persistência com Entity Framework Core e SQL Server e uma interface web construída com ASP.NET Core MVC e Razor.

## Funcionalidades

- Cadastro de produtos com part number, nome e categoria
- Listagem dos produtos cadastrados
- Edição e exclusão de produtos
- API REST com operações CRUD
- Dashboard com quantidade de produtos e categorias
- Documentação e testes da API pelo Swagger

## Tecnologias

- C# e .NET 8
- ASP.NET Core Web API
- ASP.NET Core MVC e Razor
- Entity Framework Core
- Microsoft SQL Server
- Swagger / OpenAPI
- HTML, CSS, JavaScript e Bootstrap

## Estrutura do projeto

```text
Controllers/  Endpoints da API e controladores das páginas
Data/         Contexto do Entity Framework Core
Migrations/   Migrações do banco de dados
Models/       Modelo de produto
Services/     Comunicação da interface MVC com a API
Views/        Páginas Razor
wwwroot/      CSS e JavaScript
```

## Como executar

### Pré-requisitos

- .NET SDK 8
- SQL Server ou SQL Server Express
- Entity Framework Core CLI (`dotnet-ef`)

### Configuração

1. Clone o repositório:

```bash
git clone https://github.com/MatheusTerci-DEV/sistema-controle-estoque.git
cd sistema-controle-estoque
```

2. Confira a conexão com o banco em `appsettings.json`. A configuração atual utiliza o SQL Server Express local:

```json
"DefaultConnection": "Server=localhost\\SQLEXPRESS;Database=PimEstoque;Trusted_Connection=True;TrustServerCertificate=True;"
```

3. Restaure as dependências e aplique as migrações:

```bash
dotnet restore
dotnet ef database update
```

4. Execute o projeto usando o perfil HTTPS:

```bash
dotnet run --launch-profile https
```

5. Acesse:

- Interface web: `https://localhost:7240`
- Swagger: `https://localhost:7240/swagger`

## Endpoints principais

| Método | Rota | Ação |
| --- | --- | --- |
| GET | `/api/produtos` | Lista os produtos |
| GET | `/api/produtos/{id}` | Consulta um produto |
| POST | `/api/produtos` | Cadastra um produto |
| PUT | `/api/produtos/{id}` | Atualiza um produto |
| DELETE | `/api/produtos/{id}` | Exclui um produto |

## Contexto acadêmico

Projeto desenvolvido como parte do curso de Análise e Desenvolvimento de Sistemas, com o objetivo de praticar desenvolvimento back-end, criação de APIs, modelagem de dados e integração entre interface e banco de dados.

## Próximas melhorias

- Adicionar controle de quantidade e estoque mínimo
- Implementar pesquisa e filtros
- Criar autenticação e perfis de acesso
- Adicionar testes automatizados
- Exibir gráficos reais no dashboard

## Autor

Matheus Terci  
[LinkedIn](https://www.linkedin.com/in/matheus-terci-9075a5325/)
