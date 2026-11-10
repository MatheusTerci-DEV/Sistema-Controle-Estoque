-- PIM Estoque — 001: tabelas, restrições e índices (SQL Server, schema dbo).
-- Pode ser executado mais de uma vez: cada objeto só é criado se ainda não existir.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON; -- obrigatório para índices filtrados; o sqlcmd clássico vem com OFF
GO

IF OBJECT_ID(N'dbo.Usuarios', N'U') IS NULL
CREATE TABLE dbo.Usuarios (
    Id          int IDENTITY(1,1) NOT NULL,
    Nome        nvarchar(100) NOT NULL,
    Email       nvarchar(120) NOT NULL,
    SenhaHash   nvarchar(200) NOT NULL,
    Perfil      nvarchar(20)  NOT NULL,
    Ativo       bit           NOT NULL CONSTRAINT DF_Usuarios_Ativo DEFAULT 1,
    CriadoEmUtc datetime2     NOT NULL CONSTRAINT DF_Usuarios_CriadoEmUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Usuarios PRIMARY KEY (Id),
    CONSTRAINT UQ_Usuarios_Email UNIQUE (Email),
    CONSTRAINT CK_Usuarios_Perfil CHECK (Perfil IN ('Administrador','Operador','Consulta'))
);
GO

IF OBJECT_ID(N'dbo.Fornecedores', N'U') IS NULL
CREATE TABLE dbo.Fornecedores (
    Id       int IDENTITY(1,1) NOT NULL,
    Nome     nvarchar(100) NOT NULL,
    Cnpj     char(14)      NOT NULL,
    Telefone nvarchar(20)  NULL,
    Email    nvarchar(120) NULL,
    Ativo    bit           NOT NULL CONSTRAINT DF_Fornecedores_Ativo DEFAULT 1,
    CONSTRAINT PK_Fornecedores PRIMARY KEY (Id),
    CONSTRAINT UQ_Fornecedores_Cnpj UNIQUE (Cnpj),
    -- char(14) completa com espaços, então "somente dígitos" já garante os 14
    CONSTRAINT CK_Fornecedores_Cnpj CHECK (Cnpj COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9]%')
);
GO

IF OBJECT_ID(N'dbo.Produtos', N'U') IS NULL
CREATE TABLE dbo.Produtos (
    Id           int IDENTITY(1,1) NOT NULL,
    PartNumber   nvarchar(8)   NOT NULL,
    NomeProduto  nvarchar(100) NOT NULL,
    Categoria    nvarchar(60)  NOT NULL,
    Unit         nvarchar(3)   NOT NULL CONSTRAINT DF_Produtos_Unit DEFAULT 'UN',
    Location     nvarchar(60)  NOT NULL CONSTRAINT DF_Produtos_Location DEFAULT '',
    MinimumStock int           NOT NULL CONSTRAINT DF_Produtos_MinimumStock DEFAULT 0,
    Saldo        int           NOT NULL CONSTRAINT DF_Produtos_Saldo DEFAULT 0,
    CONSTRAINT PK_Produtos PRIMARY KEY (Id),
    CONSTRAINT UQ_Produtos_PartNumber UNIQUE (PartNumber),
    CONSTRAINT CK_Produtos_PartNumber CHECK (LEN(PartNumber) = 8 AND LEFT(PartNumber, 2) IN ('47','48','84','86')
        AND PartNumber COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_Produtos_Unidade CHECK (Unit IN ('UN','PC','PAR','CX','PCT','RL')),
    CONSTRAINT CK_Produtos_Minimo CHECK (MinimumStock BETWEEN 0 AND 999999999),
    CONSTRAINT CK_Produtos_Saldo CHECK (Saldo BETWEEN 0 AND 999999999)
);
GO

IF OBJECT_ID(N'dbo.Movimentacoes', N'U') IS NULL
CREATE TABLE dbo.Movimentacoes (
    Id           bigint IDENTITY(1,1) NOT NULL,
    ProdutoId    int           NOT NULL,
    Quantidade   int           NOT NULL, -- positivo = entrada, negativo = saída
    Motivo       nvarchar(150) NOT NULL,
    CriadaEmUtc  datetime2     NOT NULL CONSTRAINT DF_Movimentacoes_CriadaEmUtc DEFAULT SYSUTCDATETIME(),
    UsuarioId    int           NULL,
    FornecedorId int           NULL,
    CONSTRAINT PK_Movimentacoes PRIMARY KEY (Id),
    CONSTRAINT FK_Movimentacoes_Produtos FOREIGN KEY (ProdutoId) REFERENCES dbo.Produtos (Id),
    CONSTRAINT FK_Movimentacoes_Usuarios FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuarios (Id),
    CONSTRAINT FK_Movimentacoes_Fornecedores FOREIGN KEY (FornecedorId) REFERENCES dbo.Fornecedores (Id),
    CONSTRAINT CK_Movimentacoes_Quantidade CHECK (Quantidade <> 0 AND Quantidade BETWEEN -999999999 AND 999999999)
);
GO

IF OBJECT_ID(N'dbo.AuditoriaProdutos', N'U') IS NULL
CREATE TABLE dbo.AuditoriaProdutos (
    Id            bigint IDENTITY(1,1) NOT NULL,
    ProdutoId     int           NOT NULL, -- sem FK: o registro sobrevive à exclusão do produto
    Operacao      char(1)       NOT NULL,
    Dados         nvarchar(max) NOT NULL,
    AlteradoEmUtc datetime2     NOT NULL CONSTRAINT DF_AuditoriaProdutos_AlteradoEmUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_AuditoriaProdutos PRIMARY KEY (Id),
    CONSTRAINT CK_AuditoriaProdutos_Operacao CHECK (Operacao IN ('I','U','D')),
    CONSTRAINT CK_AuditoriaProdutos_Dados CHECK (ISJSON(Dados) = 1)
);
GO

-- Índices para as consultas reais da API (a PK e as UNIQUE já criam os seus).
-- Busca por nome (GET /api/produtos?busca=); PartNumber já é coberto por UQ_Produtos_PartNumber.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Produtos_NomeProduto' AND object_id = OBJECT_ID(N'dbo.Produtos'))
    CREATE INDEX IX_Produtos_NomeProduto ON dbo.Produtos (NomeProduto);
-- Reposição (MinimumStock > 0 AND Saldo <= MinimumStock): o filtro deixa de fora os itens sem mínimo.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Produtos_Reposicao' AND object_id = OBJECT_ID(N'dbo.Produtos'))
    CREATE INDEX IX_Produtos_Reposicao ON dbo.Produtos (MinimumStock, Saldo) WHERE MinimumStock > 0;
-- Histórico por produto em ordem de lançamento (GET /api/movimentacoes?produtoId=).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Movimentacoes_ProdutoId_Id' AND object_id = OBJECT_ID(N'dbo.Movimentacoes'))
    CREATE INDEX IX_Movimentacoes_ProdutoId_Id ON dbo.Movimentacoes (ProdutoId, Id);
-- Extrato por produto e período (sp_ExtratoProduto).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Movimentacoes_ProdutoId_CriadaEmUtc' AND object_id = OBJECT_ID(N'dbo.Movimentacoes'))
    CREATE INDEX IX_Movimentacoes_ProdutoId_CriadaEmUtc ON dbo.Movimentacoes (ProdutoId, CriadaEmUtc) INCLUDE (Quantidade);
-- Movimentações do dia (dashboard / sp_ResumoEstoque).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Movimentacoes_CriadaEmUtc' AND object_id = OBJECT_ID(N'dbo.Movimentacoes'))
    CREATE INDEX IX_Movimentacoes_CriadaEmUtc ON dbo.Movimentacoes (CriadaEmUtc);
-- Consulta da auditoria de um produto.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuditoriaProdutos_ProdutoId' AND object_id = OBJECT_ID(N'dbo.AuditoriaProdutos'))
    CREATE INDEX IX_AuditoriaProdutos_ProdutoId ON dbo.AuditoriaProdutos (ProdutoId, AlteradoEmUtc);
GO
