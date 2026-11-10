-- SQL Server: instalação inicial em banco novo. Não executar sobre tabelas antigas.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID(N'dbo.Produtos', N'U') IS NOT NULL OR OBJECT_ID(N'dbo.Movimentacoes', N'U') IS NOT NULL
    THROW 51000, 'Existem tabelas anteriores. Preparar e revisar migração antes de continuar.', 1;
CREATE TABLE dbo.Produtos (
    Id int IDENTITY PRIMARY KEY,
    PartNumber nvarchar(8) NOT NULL,
    NomeProduto nvarchar(100) NOT NULL,
    Categoria nvarchar(60) NOT NULL,
    Unit nvarchar(3) NOT NULL DEFAULT 'UN',
    Location nvarchar(60) NOT NULL DEFAULT '',
    MinimumStock int NOT NULL DEFAULT 0,
    Saldo int NOT NULL DEFAULT 0,
    CONSTRAINT UQ_Produtos_PartNumber UNIQUE (PartNumber),
    CONSTRAINT CK_Produtos_PartNumber CHECK (LEN(PartNumber) = 8 AND LEFT(PartNumber,2) IN ('47','48','84','86') AND PartNumber COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_Produtos_Unidade CHECK (Unit IN ('UN','PC','PAR','CX','PCT','RL')),
    CONSTRAINT CK_Produtos_Minimo CHECK (MinimumStock BETWEEN 0 AND 999999999),
    CONSTRAINT CK_Produtos_Saldo CHECK (Saldo BETWEEN 0 AND 999999999)
);
CREATE TABLE dbo.Movimentacoes (
    Id bigint IDENTITY PRIMARY KEY,
    ProdutoId int NOT NULL REFERENCES dbo.Produtos(Id),
    Quantidade int NOT NULL CHECK (Quantidade <> 0 AND Quantidade BETWEEN -999999999 AND 999999999),
    Motivo nvarchar(150) NOT NULL,
    CriadaEmUtc datetime2 NOT NULL
);
CREATE INDEX IX_Movimentacoes_ProdutoId_Id ON dbo.Movimentacoes(ProdutoId, Id);
COMMIT;
