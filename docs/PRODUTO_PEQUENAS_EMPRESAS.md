# PIM Estoque para pequenas empresas

## Segmento definido

Almoxarifado de materiais em geral: consumíveis, fixadores, EPIs, ferramentas, material elétrico, hidráulico e de limpeza. As categorias continuam livres, sem restringir o cadastro a peças automotivas.

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

## Entrega de organização do almoxarifado

Cadastro com unidade discreta (UN, PC, PAR, CX, PCT, RL), localização livre de até 60 caracteres e estoque mínimo inteiro. Mínimo zero desativa reposição; com mínimo maior que zero, saldo igual ou abaixo do mínimo gera alerta. Não há conversão automática entre caixas e peças. A unidade fica bloqueada após qualquer movimentação. Quantidades fracionadas (kg, litros e metros) precisam de uma etapa própria.

Os novos campos usam UN, mínimo zero e localização vazia nos registros antigos, preservando cadastros e histórico. A pesquisa também aceita localização. O início mostra a lista de reposição, e a aba Estoque permite filtrar os materiais que precisam repor.

Próximas entregas específicas: banco central e equipe; requisições por funcionário/setor; recebimentos por fornecedor/documento; inventário físico e estornos; itens controlados por lote/validade quando aplicável.
