-- PIM Estoque — script completo do banco (gerado por database/entrega/gerar.ps1; não editar à mão).
-- Cria o banco PimEstoque e executa 001_schema, 002_triggers, 003_procedures e 004_seed.
-- Usado pela API ASP.NET Core, pelo painel web e pelo app mobile. Gerado em 2026-11-10.
IF DB_ID(N'PimEstoque') IS NULL CREATE DATABASE PimEstoque;
GO
USE PimEstoque;
GO
-- ============================== 001_schema.sql ==============================
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

-- ============================== 002_triggers.sql ==============================
-- PIM Estoque — 002: triggers. CREATE OR ALTER permite reexecutar o script.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Auditoria: grava um registro por linha afetada (funciona com INSERT/UPDATE/DELETE de várias linhas).
-- Dados = {"antes":{...},"depois":{...}}; "antes" falta no INSERT e "depois" falta no DELETE.
-- Não altera Saldo: só lê inserted/deleted, então não há dupla contagem.
CREATE OR ALTER TRIGGER dbo.trg_Produtos_Auditoria
ON dbo.Produtos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.AuditoriaProdutos (ProdutoId, Operacao, Dados)
    SELECT k.Id,
           CASE WHEN NOT EXISTS (SELECT 1 FROM deleted d WHERE d.Id = k.Id) THEN 'I'
                WHEN NOT EXISTS (SELECT 1 FROM inserted i WHERE i.Id = k.Id) THEN 'D'
                ELSE 'U' END,
           (SELECT JSON_QUERY((SELECT d.* FROM deleted d WHERE d.Id = k.Id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS antes,
                   JSON_QUERY((SELECT i.* FROM inserted i WHERE i.Id = k.Id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS depois
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM (SELECT Id FROM inserted UNION SELECT Id FROM deleted) AS k; -- Id é IDENTITY, não muda no UPDATE
END;
GO

-- Histórico imutável: correção de lançamento se faz com nova movimentação (estorno), nunca editando.
-- INSTEAD OF apenas em UPDATE/DELETE, para não interferir no INSERT ... OUTPUT do EF Core.
CREATE OR ALTER TRIGGER dbo.trg_Movimentacoes_Imutavel
ON dbo.Movimentacoes
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted)
        THROW 50010, N'Movimentações não podem ser alteradas nem excluídas. Registre um estorno.', 1;
END;
GO

-- ============================== 003_procedures.sql ==============================
-- PIM Estoque — 003: view e procedures. CREATE OR ALTER permite reexecutar o script.
-- Regra de reposição (igual à API): MinimumStock > 0 AND Saldo <= MinimumStock.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW dbo.vw_SaldoPorCategoria
AS
SELECT Categoria,
       COUNT(*)    AS Produtos,
       SUM(Saldo)  AS Saldo,
       SUM(CASE WHEN MinimumStock > 0 AND Saldo <= MinimumStock THEN 1 ELSE 0 END) AS ItensReposicao
FROM dbo.Produtos
GROUP BY Categoria;
GO

-- Entrada ou saída de material: atualiza o saldo e grava o histórico na mesma transação.
-- UPDLOCK + HOLDLOCK trava a linha do produto até o COMMIT, então duas saídas simultâneas
-- não conseguem ler o mesmo saldo e deixá-lo negativo.
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarMovimentacao
    @ProdutoId    int,
    @Tipo         varchar(7),      -- 'entrada' ou 'saida'
    @Quantidade   int,             -- sempre positiva; o sinal vem do @Tipo
    @Motivo       nvarchar(150),
    @UsuarioId    int = NULL,
    @FornecedorId int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Tipo NOT IN ('entrada', 'saida') OR @Tipo IS NULL
        THROW 50001, N'Tipo inválido: use ''entrada'' ou ''saida''.', 1;
    IF @Quantidade IS NULL OR @Quantidade NOT BETWEEN 1 AND 999999999
        THROW 50003, N'Quantidade deve estar entre 1 e 999999999.', 1;
    IF NULLIF(LTRIM(RTRIM(@Motivo)), N'') IS NULL
        THROW 50004, N'Informe o motivo da movimentação.', 1;

    DECLARE @Delta int = CASE @Tipo WHEN 'entrada' THEN @Quantidade ELSE -@Quantidade END;
    DECLARE @Saldo int, @MovimentacaoId bigint;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @Saldo = Saldo
        FROM dbo.Produtos WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @ProdutoId;

        IF @Saldo IS NULL
            THROW 50005, N'Produto não encontrado.', 1;
        IF @Saldo + CAST(@Delta AS bigint) < 0
            THROW 50002, N'Saldo insuficiente para a saída.', 1;
        IF @Saldo + CAST(@Delta AS bigint) > 999999999
            THROW 50006, N'Saldo ultrapassaria o limite de 999999999.', 1;

        UPDATE dbo.Produtos SET Saldo = Saldo + @Delta WHERE Id = @ProdutoId;

        INSERT dbo.Movimentacoes (ProdutoId, Quantidade, Motivo, CriadaEmUtc, UsuarioId, FornecedorId)
        VALUES (@ProdutoId, @Delta, LTRIM(RTRIM(@Motivo)), SYSUTCDATETIME(), @UsuarioId, @FornecedorId);
        SET @MovimentacaoId = SCOPE_IDENTITY();

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH;

    SELECT @MovimentacaoId AS MovimentacaoId, @Saldo + @Delta AS SaldoAtual;
END;
GO

-- Itens no mínimo ou abaixo dele, os mais críticos primeiro.
CREATE OR ALTER PROCEDURE dbo.sp_ProdutosParaReposicao
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, PartNumber, NomeProduto, Categoria, Unit, Location, MinimumStock, Saldo,
           MinimumStock - Saldo AS Falta
    FROM dbo.Produtos
    WHERE MinimumStock > 0 AND Saldo <= MinimumStock
    ORDER BY MinimumStock - Saldo DESC, NomeProduto;
END;
GO

-- Indicadores do painel (mesmos campos de GET /api/dashboard/resumo).
-- 1º resultado: totais; 2º resultado: saldo por categoria. "Hoje" é o dia UTC.
CREATE OR ALTER PROCEDURE dbo.sp_ResumoEstoque
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Hoje datetime2 = CAST(CAST(SYSUTCDATETIME() AS date) AS datetime2);

    SELECT (SELECT COUNT(*) FROM dbo.Produtos) AS TotalProdutos,
           (SELECT COUNT(*) FROM dbo.Produtos WHERE MinimumStock > 0 AND Saldo <= MinimumStock) AS ItensReposicao,
           (SELECT ISNULL(SUM(CAST(Saldo AS bigint)), 0) FROM dbo.Produtos) AS SaldoTotal,
           (SELECT COUNT(*) FROM dbo.Movimentacoes WHERE CriadaEmUtc >= @Hoje AND CriadaEmUtc < DATEADD(day, 1, @Hoje)) AS MovimentacoesHoje;

    SELECT Categoria, Produtos, Saldo FROM dbo.vw_SaldoPorCategoria ORDER BY Categoria;
END;
GO

-- Extrato de um produto com saldo após cada lançamento. O saldo acumulado é calculado
-- sobre todo o histórico e só depois filtrado pelo período, para não começar do zero.
CREATE OR ALTER PROCEDURE dbo.sp_ExtratoProduto
    @ProdutoId int,
    @De        datetime2 = NULL,
    @Ate       datetime2 = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Produtos WHERE Id = @ProdutoId)
        THROW 50005, N'Produto não encontrado.', 1;

    WITH Extrato AS (
        SELECT m.Id, m.CriadaEmUtc, m.Quantidade, m.Motivo,
               u.Nome AS UsuarioNome, f.Nome AS FornecedorNome,
               SUM(m.Quantidade) OVER (ORDER BY m.Id ROWS UNBOUNDED PRECEDING) AS SaldoApos
        FROM dbo.Movimentacoes m
        LEFT JOIN dbo.Usuarios u ON u.Id = m.UsuarioId
        LEFT JOIN dbo.Fornecedores f ON f.Id = m.FornecedorId
        WHERE m.ProdutoId = @ProdutoId
    )
    SELECT Id, CriadaEmUtc,
           CASE WHEN Quantidade > 0 THEN 'entrada' ELSE 'saida' END AS Tipo,
           ABS(Quantidade) AS Quantidade, Motivo, UsuarioNome, FornecedorNome, SaldoApos
    FROM Extrato
    WHERE (@De IS NULL OR CriadaEmUtc >= @De)
      AND (@Ate IS NULL OR CriadaEmUtc <= @Ate)
    ORDER BY Id;
END;
GO

-- ============================== 004_seed.sql ==============================
-- PIM Estoque — 004: dados de demonstração (empresa fictícia Fixar Manutenção).
-- Não cria usuários: o administrador inicial é semeado pela API (Seed:AdminEmail / Seed:AdminSenha).
-- Produtos começam com saldo 0 e recebem as quantidades por sp_RegistrarMovimentacao,
-- então o histórico sempre fecha com o saldo. Reexecutar não duplica nada.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

INSERT dbo.Fornecedores (Nome, Cnpj, Telefone, Email)
SELECT v.Nome, v.Cnpj, v.Telefone, v.Email
FROM (VALUES
    (N'Proteção Sorocaba EPIs Ltda.',     '12345678000195', N'(15) 3221-4400', N'vendas@protecaosorocaba.com.br'),
    (N'Fixa Forte Parafusos e Fixadores', '45678912000155', N'(15) 3232-1010', N'pedidos@fixaforte.com.br'),
    (N'EletroHidro Materiais Ltda.',      '78912345000109', N'(15) 3018-7788', N'comercial@eletrohidro.com.br')
) AS v (Nome, Cnpj, Telefone, Email)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Fornecedores f WHERE f.Cnpj = v.Cnpj);
GO

INSERT dbo.Produtos (PartNumber, NomeProduto, Categoria, Unit, Location, MinimumStock)
SELECT v.PartNumber, v.NomeProduto, v.Categoria, v.Unit, v.Location, v.MinimumStock
FROM (VALUES
    (N'47000101', N'Luva de vaqueta tamanho 9',            N'EPI',        N'PAR', N'A-01-01', 20),
    (N'47000102', N'Óculos de proteção incolor',           N'EPI',        N'UN',  N'A-01-02', 10),
    (N'47000201', N'Detergente neutro 5 L',                N'Limpeza',    N'UN',  N'D-01-01', 4),
    (N'47000202', N'Pano de microfibra 40x40 cm',          N'Limpeza',    N'PCT', N'D-01-02', 6),
    (N'48000101', N'Parafuso sextavado M8x50 zincado',     N'Fixadores',  N'CX',  N'B-02-01', 5),
    (N'48000102', N'Bucha de nylon 8 mm',                  N'Fixadores',  N'PCT', N'B-02-02', 10),
    (N'84000101', N'Cabo flexível 2,5 mm² azul 100 m',     N'Elétrico',   N'RL',  N'C-01-01', 3),
    (N'84000102', N'Disjuntor monopolar DIN 20 A',         N'Elétrico',   N'UN',  N'C-01-02', 10),
    (N'84000103', N'Fita isolante 19 mm x 20 m',           N'Elétrico',   N'RL',  N'C-01-03', 15),
    (N'86000101', N'Tubo PVC soldável 25 mm barra 6 m',    N'Hidráulico', N'PC',  N'E-01-01', 10),
    (N'86000102', N'Registro de gaveta 3/4"',              N'Hidráulico', N'UN',  N'E-01-02', 4),
    (N'86000103', N'Fita veda-rosca 18 mm x 50 m',         N'Hidráulico', N'RL',  N'E-01-03', 12)
) AS v (PartNumber, NomeProduto, Categoria, Unit, Location, MinimumStock)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Produtos p WHERE p.PartNumber = v.PartNumber);
GO

-- Movimentações só na primeira carga (banco sem histórico).
IF NOT EXISTS (SELECT 1 FROM dbo.Movimentacoes)
BEGIN
    DECLARE @Lancamentos TABLE (Ordem int IDENTITY, PartNumber nvarchar(8), Tipo varchar(7), Quantidade int, Motivo nvarchar(150), Cnpj char(14));
    INSERT @Lancamentos (PartNumber, Tipo, Quantidade, Motivo, Cnpj) VALUES
        ('47000101', 'entrada', 60,  N'NF 10231 - compra mensal de EPIs',          '12345678000195'),
        ('47000102', 'entrada', 30,  N'NF 10231 - compra mensal de EPIs',          '12345678000195'),
        ('47000201', 'entrada', 12,  N'NF 10240 - material de limpeza',            '12345678000195'),
        ('47000202', 'entrada', 10,  N'NF 10240 - material de limpeza',            '12345678000195'),
        ('48000101', 'entrada', 20,  N'NF 5521 - reposição de fixadores',          '45678912000155'),
        ('48000102', 'entrada', 40,  N'NF 5521 - reposição de fixadores',          '45678912000155'),
        ('84000101', 'entrada', 8,   N'NF 88310 - material elétrico',              '78912345000109'),
        ('84000102', 'entrada', 25,  N'NF 88310 - material elétrico',              '78912345000109'),
        ('84000103', 'entrada', 40,  N'NF 88310 - material elétrico',              '78912345000109'),
        ('86000101', 'entrada', 30,  N'NF 88342 - material hidráulico',            '78912345000109'),
        ('86000102', 'entrada', 10,  N'NF 88342 - material hidráulico',            '78912345000109'),
        ('86000103', 'entrada', 36,  N'NF 88342 - material hidráulico',            '78912345000109'),
        ('47000101', 'saida',   44,  N'OS 2026-118 - equipe de campo Cond. Ipanema', NULL),
        ('47000102', 'saida',   6,   N'OS 2026-118 - equipe de campo Cond. Ipanema', NULL),
        ('47000202', 'saida',   5,   N'Limpeza pós-obra loja Centro',              NULL),
        ('48000101', 'saida',   8,   N'OS 2026-121 - fixação de eletrocalhas',     NULL),
        ('84000101', 'saida',   6,   N'OS 2026-121 - troca de circuito',           NULL),
        ('84000102', 'saida',   12,  N'OS 2026-124 - quadro de distribuição',      NULL),
        ('84000103', 'saida',   10,  N'OS 2026-124 - quadro de distribuição',      NULL),
        ('86000101', 'saida',   24,  N'OS 2026-127 - prumada de água fria',        NULL),
        ('86000102', 'saida',   7,   N'OS 2026-127 - prumada de água fria',        NULL),
        ('86000103', 'saida',   20,  N'OS 2026-127 - prumada de água fria',        NULL);

    DECLARE @i int = 1, @Fim int = (SELECT MAX(Ordem) FROM @Lancamentos),
            @ProdutoId int, @Tipo varchar(7), @Quantidade int, @Motivo nvarchar(150), @FornecedorId int;
    DECLARE @Ignorar TABLE (MovimentacaoId bigint, SaldoAtual int); -- descarta o retorno da procedure

    WHILE @i <= @Fim
    BEGIN
        SELECT @ProdutoId = p.Id, @Tipo = l.Tipo, @Quantidade = l.Quantidade, @Motivo = l.Motivo, @FornecedorId = f.Id
        FROM @Lancamentos l
        JOIN dbo.Produtos p ON p.PartNumber = l.PartNumber
        LEFT JOIN dbo.Fornecedores f ON f.Cnpj = l.Cnpj
        WHERE l.Ordem = @i;

        INSERT @Ignorar EXEC dbo.sp_RegistrarMovimentacao @ProdutoId, @Tipo, @Quantidade, @Motivo, NULL, @FornecedorId;
        SET @i += 1;
    END;
END;
GO
