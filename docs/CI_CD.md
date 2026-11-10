# CI/CD e gestão do repositório

## Pipelines

| Workflow | Execução automática | Execução manual | Resultado |
| --- | --- | --- | --- |
| `PIM Estoque API` | Push em `main`, `feat/**` ou `fix/**` e PR para `main` com alterações na API | Sim | Testes .NET e build da imagem Docker |
| `PIM Estoque Mobile` | Push em `main`, `feat/**` ou `fix/**` e PR para `main` com alterações em `mobile/` | Sim | Formatação, análise e testes Flutter; APK apenas na execução manual |
| `PIM Estoque Web` | Push em `main` com alterações em `mobile/` | Sim | Testes Flutter, build web e publicação no GitHub Pages |

Os workflows usam permissões mínimas de leitura, cancelam execuções antigas da mesma referência e aplicam filtros de caminho para evitar execuções desnecessárias.

## Fluxo recomendado

1. Crie uma branch `feat/...` ou `fix/...`.
2. Abra um pull request para `main`.
3. Aguarde os checks de API e/ou mobile antes do merge.
4. Faça o merge em `main` para publicar a versão web.
5. Use `workflow_dispatch` no pipeline mobile quando precisar baixar um APK de demonstração.

O Dependabot verifica mensalmente dependências NuGet, Flutter e GitHub Actions. Issues novas podem usar os modelos de bug e melhoria disponíveis no repositório.
