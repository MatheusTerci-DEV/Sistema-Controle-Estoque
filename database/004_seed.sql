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
