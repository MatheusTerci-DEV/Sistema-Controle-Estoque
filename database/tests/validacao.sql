-- PIM Estoque — roteiro de validação do banco (rodar no SSMS depois de 001..004).
-- Cada teste imprime OK ou FALHA; no fim, o script gera erro se algo falhou.
-- Usa os produtos de teste 86999998/86999999 (criados se não existirem). Movimentações
-- não podem ser apagadas, então reexecutar acumula histórico nesses dois itens — é esperado.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

DECLARE @Falhas int = 0, @Erro int, @Pid int, @Pid2 int, @Saldo0 int, @Saldo int, @Antes int, @Depois int;
DECLARE @Ids TABLE (Id int);
DECLARE @Ret TABLE (MovimentacaoId bigint, SaldoAtual int);

PRINT '== 1. INSERT com OUTPUT INTO (padrão do EF Core) em várias linhas + auditoria';
SELECT @Antes = COUNT(*) FROM dbo.AuditoriaProdutos;
INSERT dbo.Produtos (PartNumber, NomeProduto, Categoria, Unit, Location, MinimumStock)
OUTPUT inserted.Id INTO @Ids
SELECT v.PartNumber, v.Nome, N'Teste', N'UN', N'Z-99', 5
FROM (VALUES (N'86999998', N'Item de teste A'), (N'86999999', N'Item de teste B')) v (PartNumber, Nome)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Produtos p WHERE p.PartNumber = v.PartNumber);
SELECT @Depois = COUNT(*) FROM dbo.AuditoriaProdutos;
IF @Depois - @Antes = (SELECT COUNT(*) FROM @Ids) PRINT 'OK   auditoria gravou uma linha por produto inserido';
ELSE BEGIN PRINT 'FALHA auditoria do INSERT'; SET @Falhas += 1; END;

SELECT @Pid = Id, @Saldo0 = Saldo FROM dbo.Produtos WHERE PartNumber = N'86999999';
SELECT @Pid2 = Id FROM dbo.Produtos WHERE PartNumber = N'86999998';

PRINT '== 2. sp_RegistrarMovimentacao: entrada';
INSERT @Ret EXEC dbo.sp_RegistrarMovimentacao @Pid, 'entrada', 10, N'Teste - entrada', NULL, NULL;
SELECT @Saldo = Saldo FROM dbo.Produtos WHERE Id = @Pid;
IF @Saldo = @Saldo0 + 10 PRINT 'OK   entrada somou 10 ao saldo';
ELSE BEGIN PRINT 'FALHA entrada'; SET @Falhas += 1; END;

PRINT '== 3. sp_RegistrarMovimentacao: saída';
INSERT @Ret EXEC dbo.sp_RegistrarMovimentacao @Pid, 'saida', 4, N'Teste - saída', NULL, NULL;
SELECT @Saldo = Saldo FROM dbo.Produtos WHERE Id = @Pid;
IF @Saldo = @Saldo0 + 6 PRINT 'OK   saída subtraiu 4 do saldo';
ELSE BEGIN PRINT 'FALHA saída'; SET @Falhas += 1; END;

PRINT '== 4. Saída maior que o saldo é recusada (50002) e nada muda';
SELECT @Antes = COUNT(*) FROM dbo.Movimentacoes WHERE ProdutoId = @Pid;
BEGIN TRY
    EXEC dbo.sp_RegistrarMovimentacao @Pid, 'saida', 999999, N'Teste - sem saldo', NULL, NULL;
    PRINT 'FALHA saída sem saldo foi aceita'; SET @Falhas += 1;
END TRY
BEGIN CATCH
    SET @Erro = ERROR_NUMBER();
    IF @Erro = 50002 AND @@TRANCOUNT = 0
       AND (SELECT Saldo FROM dbo.Produtos WHERE Id = @Pid) = @Saldo
       AND (SELECT COUNT(*) FROM dbo.Movimentacoes WHERE ProdutoId = @Pid) = @Antes
        PRINT 'OK   recusada: ' + ERROR_MESSAGE();
    ELSE BEGIN PRINT 'FALHA erro inesperado ' + CAST(@Erro AS varchar(10)) + ': ' + ERROR_MESSAGE(); SET @Falhas += 1; END;
END CATCH;

PRINT '== 5. Parâmetros inválidos na procedure (tipo, quantidade, produto)';
BEGIN TRY EXEC dbo.sp_RegistrarMovimentacao @Pid, 'ajuste', 1, N'x'; PRINT 'FALHA tipo'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 50001 PRINT 'OK   tipo inválido recusado'; ELSE BEGIN PRINT 'FALHA tipo: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;
BEGIN TRY EXEC dbo.sp_RegistrarMovimentacao @Pid, 'entrada', 0, N'x'; PRINT 'FALHA quantidade'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 50003 PRINT 'OK   quantidade 0 recusada'; ELSE BEGIN PRINT 'FALHA quantidade: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;
BEGIN TRY EXEC dbo.sp_RegistrarMovimentacao -1, 'entrada', 1, N'x'; PRINT 'FALHA produto'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 50005 PRINT 'OK   produto inexistente recusado'; ELSE BEGIN PRINT 'FALHA produto: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;

PRINT '== 6. Histórico imutável: UPDATE e DELETE em Movimentacoes';
BEGIN TRY UPDATE dbo.Movimentacoes SET Quantidade = 1 WHERE ProdutoId = @Pid; PRINT 'FALHA UPDATE aceito'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 50010 PRINT 'OK   UPDATE bloqueado: ' + ERROR_MESSAGE(); ELSE BEGIN PRINT 'FALHA UPDATE: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;
BEGIN TRY DELETE dbo.Movimentacoes WHERE ProdutoId = @Pid; PRINT 'FALHA DELETE aceito'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 50010 PRINT 'OK   DELETE bloqueado'; ELSE BEGIN PRINT 'FALHA DELETE: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;
IF (SELECT COUNT(*) FROM dbo.Movimentacoes WHERE ProdutoId = @Pid) = @Antes PRINT 'OK   histórico intacto';
ELSE BEGIN PRINT 'FALHA histórico mudou'; SET @Falhas += 1; END;

PRINT '== 7. Saldo do produto = soma do histórico (todos os produtos)';
IF NOT EXISTS (SELECT 1 FROM dbo.Produtos p
               WHERE p.Saldo <> ISNULL((SELECT SUM(m.Quantidade) FROM dbo.Movimentacoes m WHERE m.ProdutoId = p.Id), 0))
    PRINT 'OK   saldos conferem com as movimentações';
ELSE BEGIN PRINT 'FALHA saldo divergente do histórico'; SET @Falhas += 1; END;

PRINT '== 8. Auditoria: UPDATE de várias linhas e JSON válido';
SELECT @Antes = COUNT(*) FROM dbo.AuditoriaProdutos WHERE Operacao = 'U';
UPDATE dbo.Produtos SET Location = N'Z-98' WHERE Id IN (@Pid, @Pid2);
SELECT @Depois = COUNT(*) FROM dbo.AuditoriaProdutos WHERE Operacao = 'U';
IF @Depois - @Antes = 2 PRINT 'OK   duas linhas de auditoria para o UPDATE de dois produtos';
ELSE BEGIN PRINT 'FALHA auditoria multi-linha'; SET @Falhas += 1; END;
IF EXISTS (SELECT 1 FROM dbo.AuditoriaProdutos WHERE ProdutoId = @Pid AND Operacao = 'U'
           AND JSON_VALUE(Dados, '$.antes.Location') IS NOT NULL AND JSON_VALUE(Dados, '$.depois.Location') = N'Z-98')
    PRINT 'OK   JSON guarda o antes e o depois';
ELSE BEGIN PRINT 'FALHA JSON da auditoria'; SET @Falhas += 1; END;

PRINT '== 9. CHECK constraints recusam dados inválidos (erro 547)';
BEGIN TRY INSERT dbo.Produtos (PartNumber, NomeProduto, Categoria) VALUES (N'12345678', N'x', N'x'); PRINT 'FALHA prefixo'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 547 PRINT 'OK   PartNumber com prefixo inválido'; ELSE BEGIN PRINT 'FALHA prefixo: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;
BEGIN TRY INSERT dbo.Produtos (PartNumber, NomeProduto, Categoria) VALUES (N'4700A001', N'x', N'x'); PRINT 'FALHA letra'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 547 PRINT 'OK   PartNumber com letra'; ELSE BEGIN PRINT 'FALHA letra: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;
BEGIN TRY INSERT dbo.Produtos (PartNumber, NomeProduto, Categoria, Unit) VALUES (N'47999990', N'x', N'x', N'KG'); PRINT 'FALHA unidade'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 547 PRINT 'OK   unidade fora da lista'; ELSE BEGIN PRINT 'FALHA unidade: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;
BEGIN TRY UPDATE dbo.Produtos SET Saldo = -1 WHERE Id = @Pid; PRINT 'FALHA saldo negativo'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 547 PRINT 'OK   saldo negativo'; ELSE BEGIN PRINT 'FALHA saldo: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;
BEGIN TRY INSERT dbo.Movimentacoes (ProdutoId, Quantidade, Motivo) VALUES (@Pid, 0, N'x'); PRINT 'FALHA quantidade 0'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 547 PRINT 'OK   movimentação com quantidade 0'; ELSE BEGIN PRINT 'FALHA qtd: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;
BEGIN TRY INSERT dbo.Fornecedores (Nome, Cnpj) VALUES (N'x', '12.345.678/00'); PRINT 'FALHA cnpj'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 547 PRINT 'OK   CNPJ com pontuação'; ELSE BEGIN PRINT 'FALHA cnpj: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;
BEGIN TRY INSERT dbo.Usuarios (Nome, Email, SenhaHash, Perfil) VALUES (N'x', N'x@x', N'x', N'Root'); PRINT 'FALHA perfil'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 547 PRINT 'OK   perfil inexistente'; ELSE BEGIN PRINT 'FALHA perfil: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;
BEGIN TRY INSERT dbo.Produtos (PartNumber, NomeProduto, Categoria) VALUES (N'86999999', N'x', N'x'); PRINT 'FALHA duplicado'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 2627 PRINT 'OK   PartNumber duplicado (UNIQUE)'; ELSE BEGIN PRINT 'FALHA duplicado: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;
BEGIN TRY DELETE dbo.Produtos WHERE Id = @Pid; PRINT 'FALHA exclusão com histórico'; SET @Falhas += 1; END TRY
BEGIN CATCH IF ERROR_NUMBER() = 547 PRINT 'OK   produto com movimentações não pode ser excluído (FK)'; ELSE BEGIN PRINT 'FALHA FK: ' + ERROR_MESSAGE(); SET @Falhas += 1; END; END CATCH;

PRINT '== Resultado';
IF @Falhas = 0 PRINT 'TODOS OS TESTES PASSARAM';
ELSE THROW 50099, 'Há testes com FALHA. Veja as mensagens acima.', 1;
GO

-- Consultas para mostrar na apresentação.
SELECT * FROM dbo.vw_SaldoPorCategoria ORDER BY Categoria;
EXEC dbo.sp_ProdutosParaReposicao;
EXEC dbo.sp_ResumoEstoque;
DECLARE @Pid int = (SELECT Id FROM dbo.Produtos WHERE PartNumber = N'86999999');
EXEC dbo.sp_ExtratoProduto @Pid;
SELECT TOP (10) Id, ProdutoId, Operacao, AlteradoEmUtc, Dados FROM dbo.AuditoriaProdutos ORDER BY Id DESC;
GO
