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
