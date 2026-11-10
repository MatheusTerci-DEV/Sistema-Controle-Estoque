# Referência visual — evolução do almoxarifado

Referência enviada: https://vt.tiktok.com/ZSpf7avNs/

Foi possível observar trechos de uma demonstração de PDV com menu lateral, lista de produtos, busca e painel de resumo da operação. O TikTok passou a exibir um cadastro sobre o vídeo; não houve análise integral do áudio ou do fluxo completo. As decisões abaixo usam apenas os elementos visíveis e os requisitos do nosso almoxarifado.

## Adaptação implementada

- Navegação lateral no computador (a partir de 900 px) e inferior no celular.
- Início organizado como painel: materiais, categorias, materiais sem saldo e reposição, com dados reais do catálogo local.
- Atalhos para consulta e nova movimentação.
- Lista de reposição e atividade recente no início.
- Resumo antes de registrar: material, tipo de operação, saldo atual, quantidade e saldo previsto.
- Aviso de saldo insuficiente antes de confirmar uma saída.

A prévia não altera o saldo. A gravação continua ocorrendo apenas quando a movimentação é registrada e salva com sucesso. Não foram adicionados caixa, pagamentos, clientes ou vendas: o fluxo continua voltado ao almoxarifado. A API permanece independente e a demonstração web mantém persistência local.

## Validação

Análise Flutter sem problemas e 28 testes aprovados, incluindo navegação lateral, atalho operacional e previsão de saída sem alteração do saldo antes da confirmação. Os testes anteriores continuam cobrindo part number, cadastro, persistência, unidades e movimentações.
