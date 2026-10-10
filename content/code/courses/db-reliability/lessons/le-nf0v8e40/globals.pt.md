---
title: O que o dump de um banco deixa de fora
version: 1
---

A lição 1 restaurou num segundo banco do mesmo servidor, que é o teste mais gentil possível: tudo o
que o dump pressupunha já estava lá. Um desastre de verdade deixa você com um **servidor novo**, e
esse é o teste que vale a pena fazer. O Ubuntu cria um segundo na mesma máquina com um comando:

```
ana@vm:~$ sudo pg_createcluster 16 restore --port 5433 --start
Creating new PostgreSQL cluster 16/restore ...
/usr/lib/postgresql/16/bin/initdb -D /var/lib/postgresql/16/restore --auth-local peer --auth-host scram-sha-256 --no-instructions
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "C.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/16/restore ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... America/Sao_Paulo
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok
Ver Cluster Port Status Owner    Data directory                 Log file
16  restore 5433 online postgres /var/lib/postgresql/16/restore /var/log/postgresql/postgresql-16-restore.log
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory                 Log file
16  main    5432 online postgres /var/lib/postgresql/16/main    /var/log/postgresql/postgresql-16-main.log
16  restore 5433 online postgres /var/lib/postgresql/16/restore /var/log/postgresql/postgresql-16-restore.log
ana@vm:~$ psql -p 5433 -d postgres
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: FATAL:  role "ana" does not exist
```

O `pg_createcluster` rodou o `initdb`, que monta um diretório de dados vazio, e subiu o resultado
na porta 5433. O `pg_lsclusters` agora tem duas linhas: dois servidores, cada um com os próprios
arquivos, a própria configuração e o próprio log, sem compartilhar nada além do computador. Daqui
em diante, `-p 5433` fala com o novo.

E o servidor novo não conhece você. **O seu próprio papel nunca esteve em dump nenhum**, porque os
papéis não pertencem a um banco. Eles pertencem ao servidor inteiro, e todos os bancos dele os
compartilham. Crie a si mesmo lá, depois um banco para restaurar, e restaure:

```
ana@vm:~$ sudo -u postgres createuser -p 5433 --superuser $USER
ana@vm:~$ createdb -p 5433 shop
ana@vm:~$ pg_restore -p 5433 -d shop shop.dump
pg_restore: error: could not execute query: ERROR:  role "shop_owner" does not exist
Command was: ALTER TABLE public.customers OWNER TO shop_owner;

pg_restore: error: could not execute query: ERROR:  role "shop_owner" does not exist
Command was: ALTER TABLE public.orders OWNER TO shop_owner;

pg_restore: error: could not execute query: ERROR:  role "shop_app" does not exist
Command was: GRANT SELECT,INSERT ON TABLE public.customers TO shop_app;


pg_restore: error: could not execute query: ERROR:  role "shop_app" does not exist
Command was: GRANT SELECT,INSERT ON TABLE public.orders TO shop_app;


pg_restore: warning: errors ignored on restore: 4
ana@vm:~$ echo $?
1
```

Quatro erros, um para cada linha do dump que citava um papel de que este servidor nunca ouviu
falar: as tabelas não podem ser dadas a `shop_owner`, e não dá para conceder nada a `shop_app`. O
`pg_restore` seguiu em frente depois de cada um, disse `errors ignored on restore: 4` e **terminou
com status 1**. As linhas estão todas lá; as tabelas são suas, e o papel da aplicação seria recusado
na primeira consulta. Um script que ignora o status de saída chama isso de restauração bem-sucedida.

## Globais

O que mora fora de todos os bancos se chama **global**: os papéis, com as senhas e os atributos, e
os tablespaces. O dump de um banco não consegue guardá-los, seja qual for o formato:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma caixa para um servidor PostgreSQL. No alto, uma faixa de objetos globais, os papéis com as senhas e os tablespaces, que não pertencem a nenhum banco. Embaixo, dois bancos, shop e bigshop, cada um com tabelas, linhas, índices, chaves e permissões. pg_dump shop alcança só um banco; pg_dumpall --globals-only alcança só a faixa; um backup completo precisa dos dois.\"><defs><marker id=\"l2s-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"l2s-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"440\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um servidor PostgreSQL</text><rect x=\"40\" y=\"52\" width=\"400\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">global: compartilhado por todos os bancos</text><text x=\"160\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">papéis e as senhas deles</text><text x=\"350\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tablespaces</text><rect x=\"40\" y=\"124\" width=\"190\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">banco shop</text><text x=\"135\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tabelas, linhas, índices,</text><text x=\"135\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chaves, permissões</text><rect x=\"250\" y=\"124\" width=\"190\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"345\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">banco bigshop</text><text x=\"345\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tabelas, linhas, índices,</text><text x=\"345\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chaves, permissões</text><rect x=\"500\" y=\"60\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">pg_dumpall --globals-only</text><path d=\"M500 80 L444 80\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2s-am)\"></path><rect x=\"55\" y=\"252\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pg_dump shop</text><path d=\"M135 252 L135 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2s-ph)\"></path></svg>", "caption": "O que mora onde. O dump de um banco nunca contém os papéis que as permissões dele citam, porque os papéis pertencem ao servidor inteiro; os globais são um segundo arquivo, e um backup são os dois.", "same": ["tablespaces"]}
```

`pg_dumpall --globals-only` faz o dump exatamente da parte global, em SQL puro:

```
ana@vm:~$ pg_dumpall --globals-only -f globals.sql
ana@vm:~$ grep -E '^(CREATE|ALTER) ROLE' globals.sql
CREATE ROLE ana;
ALTER ROLE ana WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;
CREATE ROLE shop_app;
ALTER ROLE shop_app WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:WasJ/NKVQHsRPGO7PHzYIQ==$DR6YU7hfJ+NGKYBPwrGW+S+wyufhd9St8g29KIK2mMc=:WrtE9UsOMp9lPnUxa2b55rJ01dE64Yrg1234UY0RFXg=';
CREATE ROLE shop_owner;
ALTER ROLE shop_owner WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;
```

Todos os papéis do servidor, inclusive `postgres` e você, com o que cada um pode fazer. `shop_app`
traz a senha, guardada como um hash **SCRAM** e não como o texto `app-secret-1`, o que quer dizer
que o servidor restaurado aceita a mesma senha sem que ninguém a conheça. Quer dizer também que
**este arquivo é um segredo**: quem o tiver pode atacar esses hashes com toda a calma. Guarde-o onde
os dumps são guardados e proteja os dois do mesmo jeito; a lição 9 decide como.

## A restauração que funciona

Comece de novo, com os globais primeiro:

```
ana@vm:~$ dropdb -p 5433 shop
ana@vm:~$ psql -p 5433 -d postgres -f globals.sql
SET
SET
SET
psql:globals.sql:16: ERROR:  role "ana" already exists
ALTER ROLE
psql:globals.sql:18: ERROR:  role "postgres" already exists
ALTER ROLE
CREATE ROLE
ALTER ROLE
CREATE ROLE
ALTER ROLE
ana@vm:~$ createdb -p 5433 shop
ana@vm:~$ pg_restore -p 5433 -d shop shop.dump
ana@vm:~$ echo $?
0
ana@vm:~$ psql -X -A -t -p 5433 shop -f verify.sql > restored.txt
ana@vm:~$ psql -X -A -t shop -f verify.sql > live.txt
ana@vm:~$ diff live.txt restored.txt && echo identical
identical
```

As duas linhas de `ERROR` são o `CREATE ROLE` de `ana` e de `postgres`, que já existem no servidor
novo; o `ALTER ROLE` depois de cada um roda mesmo assim e acerta os atributos. Todos os outros papéis
são criados. Desta vez o `pg_restore` fica em silêncio e termina com 0, e o relatório da lição 1 diz
que os dois servidores guardam o mesmo shop.

**O backup de um servidor PostgreSQL são, portanto, dois arquivos, e não um**: os globais, e um dump
por banco. Uma rotina que faz dump dos bancos e esquece os globais produz cópias que restauram com
erros e uma aplicação que não consegue entrar, e a primeira vez que alguém descobre é num servidor
novo. O `pg_dumpall` sem `--globals-only` escreve tudo num único arquivo SQL puro, papéis e todos os
bancos, e esse arquivo tem todas as fraquezas do SQL puro; o arranjo de costume é os globais com
`pg_dumpall` e cada banco com `pg_dump -Fc`.
