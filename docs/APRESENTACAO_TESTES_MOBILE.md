# Apresentação e testes — PIM Estoque Mobile

Data: 10/11/2026. Versão: 0.2.0+2. Demonstração acadêmica com catálogo fictício e cadastros salvos no aparelho, sem integração com a API.

## Materiais iniciais

| Part number | Material | Categoria |
| --- | --- | --- |
| 47000001 | Filtro de óleo | Filtros |
| 47000002 | Filtro de ar | Filtros |
| 48000001 | Parafuso M10 × 30 | Fixadores |
| 48000002 | Porca M10 | Fixadores |
| 48000003 | Arruela M10 | Fixadores |
| 84000001 | Rolamento 6204 | Rolamentos |
| 86000001 | Correia de transmissão | Transmissão |
| 86000002 | Mangueira hidráulica | Hidráulica |

## Roteiro sugerido — 5 a 8 minutos

1. **Início:** mostrar oito produtos e cinco categorias em uma instalação nova. Explicar o aviso de demonstração e a persistência local.
2. **Consulta:** abrir Produtos e pesquisar `47000001`. Abrir Filtro de óleo e mostrar os detalhes. Fechar, limpar a busca e pesquisar `Fixadores`: três resultados.
3. **Cadastro:** abrir Cadastrar material e tentar salvar vazio. Mostrar as mensagens de campos obrigatórios.
4. **Duplicidade:** preencher `47000001`, `Outro filtro` e `Filtros`. Tentar salvar: o part number deve ser recusado por já estar cadastrado.
5. **Novo material:** alterar para `86009001`, `Sensor de pressão` e `Elétrica`. Salvar. Mostrar a confirmação e os nove produtos. No Início, o total passa para nove produtos e seis categorias.
6. **Edição:** pesquisar `86009001`, abrir detalhes, escolher Editar material e alterar o nome para `Sensor de pressão revisado`. Salvar sem mudar o part number: a edição do próprio código é permitida.
7. **Persistência:** fechar completamente e reabrir o aplicativo. Pesquisar `86009001` e conferir o nome revisado.
8. **Busca vazia:** pesquisar `XYZ-INEXISTENTE` e mostrar a mensagem sem resultados. Limpar a busca.

Os totais do roteiro pressupõem uma instalação nova. Se o material de teste já existir, use outro part number, como `86009002`. Não limpe os dados do aplicativo para repetir o teste se quiser preservar os cadastros.

## Evidências automatizadas

- 17 testes aprovados na validação local.
- Pesquisa por nome, part number e categoria.
- Cadastro, edição, totais e reabertura do app na interface.
- Campos obrigatórios, limites, duplicidade e cancelamento.
- Persistência com gravação, substituição e reabertura de arquivo real temporário.
- Catálogo corrompido ou versão incompatível não é sobrescrito.
- Falhas de leitura e gravação permitem nova tentativa.
- Gravações simultâneas são bloqueadas.
- Navegação e formulário em tela de 320 × 640 com texto ampliado.

A reabertura do arquivo real foi validada no ambiente de testes. Instalação Android, fechamento pelo sistema e reabertura no aparelho precisam ser conferidos com o APK. A automação do GitHub tenta gerar esse APK; a existência do workflow, por si só, não comprova sucesso do build.

## Como obter o APK pelo GitHub

Abra a aba Actions, escolha a execução mais recente de **PIM Estoque Mobile** e aguarde o resultado. Se passar, baixe o artefato **pim-estoque-demo-android** e extraia `app-debug.apk`. O APK é somente para testes Android.

## Explicação técnica curta

“O aplicativo foi desenvolvido em Flutter com Dart. A interface consulta um catálogo com validações de cadastro, e os dados são gravados localmente em JSON. A API .NET será integrada em uma próxima etapa. Neste momento, o objetivo é demonstrar cadastro, consulta, edição e persistência.”
