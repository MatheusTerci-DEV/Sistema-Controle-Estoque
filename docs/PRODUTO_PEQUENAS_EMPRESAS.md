# PIM Estoque para pequenas empresas

## Objetivo e situação atual

Evoluir o Flutter web/mobile para controle de materiais de uma pequena empresa, em entregas pequenas. A versão publicada ainda é uma demonstração local, não um serviço com dados compartilhados. Não deve ser apresentada como pronta para operar o estoque real de uma empresa.

## Entregas e critérios

| Etapa | Entrega | Critério de conclusão |
| --- | --- | --- |
| 1 | Entradas, saídas e saldo em unidades inteiras | Recusar quantidade inválida e saída sem saldo; salvar saldo e histórico juntos; reabrir sem perder alterações |
| 2 | Estoque mínimo, unidade e localização | Configurar mínimo por produto; listar itens para reposição; definir suporte a unidades fracionadas conforme o negócio |
| 3 | Banco central, API e autenticação | Compartilhar registros entre aparelhos; verificar permissões no servidor; impedir perda de saldo em saídas simultâneas |
| 4 | Empresa e equipe | Administrador, operador e consulta; separação dos dados por empresa; responsável identificado em cada operação |
| 5 | Fornecedores e compras | Registrar recebimentos por documento e fornecedor; consultar pendências e reposição |
| 6 | Inventário e correções | Contagem física, divergências e ajustes com justificativa; estorno vinculado ao original, preservando histórico |
| 7 | Relatórios e proteção dos dados | Exportação, períodos, indicadores, backup e restauração testada |
| 8 | Piloto | Testar com uma pequena empresa, no celular e computador, incluindo conexão instável e operações simultâneas |

## Regras da primeira entrega

- Todo material começa com saldo zero; não inventar quantidades de exemplos.
- Saldo é calculado pelas movimentações; editar nome/categoria não altera quantidade.
- Entradas e saídas devem ter quantidade inteira positiva e motivo/referência.
- Saída maior que o saldo é recusada.
- Uma falha ao salvar não deve mudar o saldo em memória nem confirmar sucesso.
- Catálogos antigos sem histórico continuam abrindo; não substituir os produtos já cadastrados.
- Interface mostra as 30 movimentações mais recentes, mas o catálogo preserva o histórico completo.

## Decisões para as próximas etapas

Confirmar primeiro segmento atendido (loja, oficina, materiais ou outro), necessidade de quantidades fracionadas e operação de uma ou várias empresas. Preservar Flutter e avaliar a recuperação da API .NET antes de escolher nova infraestrutura. Não colocar credenciais administrativas no app. GitHub Pages hospeda o frontend; banco, autenticação e regras compartilhadas exigem um backend.

Vendas com pagamento, emissão fiscal, contabilidade, lotes e validade devem ser tratados como módulos próprios quando houver requisitos definidos.
