# Deploy em produção — Oracle Cloud

**Endereço:** https://estoque.vinnisantos.com.br (painel web + API REST; o app Android usa este endereço por padrão).

## Arquitetura

```
Internet ──HTTPS──► Nginx (Let's Encrypt) ──► api  127.0.0.1:8090 (container ASP.NET Core 8)
                                                │ rede interna do Docker
                                                ▼
                                              sqledge (Azure SQL Edge, sem porta exposta)
```

- **Instância:** Oracle Cloud `VM.Standard.A2.Flex` (ARM64, Ubuntu 24.04), região São Paulo.
- **Banco:** Azure SQL Edge, que é o motor do SQL Server compilado para ARM64. A imagem `mssql/server` só existe para x86-64: testada na instância via emulação, ela encerra com *segmentation fault*.
  - Os scripts `database/0*.sql` e `database/tests/validacao.sql` foram executados no SQL Edge e passaram integralmente.
  - A Microsoft encerrou o suporte ao SQL Edge em 2025. Por isso o banco não expõe porta e só a API o acessa.
  - Em uma nuvem x86 (por exemplo, Azure SQL Database), os mesmos scripts rodam sem mudança.
- **Usuário da API no banco:** `pim_api`, com `db_datareader`, `db_datawriter` e `EXECUTE`. A aplicação não usa `sa`.
- **Segredos:** ficam em `/opt/stacks/pim-estoque/.env` no servidor, com permissão 600 e fora do Git.
  - Variáveis: `MSSQL_SA_PASSWORD`, `DB_APP_PASSWORD`, `JWT_KEY`, `ADMIN_EMAIL` e `ADMIN_SENHA`.
  - Todas foram geradas com `openssl rand`.
- **Limites de memória:** 1,5 GB para o SQL Edge e 512 MB para a API.

## Atualizar a aplicação

```bash
# no PC, na raiz do repositório
git ls-files -- . ':!mobile' ':!docs/pim' | tar czf pim-deploy.tgz -T -
scp pim-deploy.tgz oracle-vps:/tmp/
# na instância
cd /opt/stacks/pim-estoque && tar xzf /tmp/pim-deploy.tgz
docker compose -f docker-compose.prod.yml up -d --build api
```

## Aplicar scripts do banco

A imagem do SQL Edge não inclui `sqlcmd`. Os scripts são aplicados por um túnel SSH, a partir do SSMS ou do Azure Data Studio:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' pim-estoque-sqledge-1   # na instância
ssh -N -L 14331:<ip-do-container>:1433 oracle-vps                                                     # no PC
```

1. No SSMS, conecte em `127.0.0.1,14331` com o usuário `sa` e a senha do `.env`.
2. Crie o banco `PimEstoque`.
3. Execute `database/001` a `004`, nessa ordem. Os scripts podem ser reexecutados.

## Operação

- **Logs:** `docker compose -f docker-compose.prod.yml logs -f api`.
- **Saúde:** `curl https://estoque.vinnisantos.com.br/health`.
- **Certificado:** renovação automática pelo `certbot.timer`.
- **Backup do banco:**
  1. Pelo túnel, no SSMS, execute `BACKUP DATABASE PimEstoque TO DISK = '/var/opt/mssql/backup.bak'`.
  2. Na instância, copie o arquivo para fora do volume: `docker cp pim-estoque-sqledge-1:/var/opt/mssql/backup.bak ~/backups/`.
