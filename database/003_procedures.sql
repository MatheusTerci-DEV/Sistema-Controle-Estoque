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
