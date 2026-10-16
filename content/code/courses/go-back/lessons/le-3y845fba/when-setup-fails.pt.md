---
title: Quando o banco não responde
version: 1
---

Uma conexão com o banco falha de poucos jeitos, e **cada mensagem diz qual, na última oração**. Todas
estas foram provocadas de propósito, na máquina da seção anterior.

## Falta o role ou o banco

```
ana@vm:~/boxoffice$ psql -c "SELECT 1"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "ana" does not exist
```

O `psql` sem nome de banco tenta um com o seu nome, e não há nenhum. **`role "ana" does not exist`**, a
mensagem da seção anterior, quer dizer que o passo do `createuser` foi pulado; **`database "ana" does
not exist`** quer dizer que você entrou e pediu o banco errado. O conserto do segundo é nomear um,
`psql boxoffice`; nomear um que não existe recebe a mesma recusa, com esse nome:

```
ana@vm:~/boxoffice$ psql nowhere -c "SELECT 1"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "nowhere" does not exist
```

## O servidor não está rodando

```
ana@vm:~/boxoffice$ sudo pg_ctlcluster 16 main stop
ana@vm:~/boxoffice$ psql boxoffice -c "SELECT 1"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
ana@vm:~/boxoffice$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@vm:~/boxoffice$ sudo pg_ctlcluster 16 main start
```

**`No such file or directory` no socket quer dizer que nada está escutando**: o arquivo de socket só
existe enquanto o servidor roda. O `pg_lsclusters` confirma com `down`, e o
`pg_ctlcluster 16 main start` o traz de volta. Se ele não subir, o arquivo de log na última coluna do
`pg_lsclusters` diz por quê, e os dois motivos de costume são um disco cheio e outro programa já
segurando a porta 5432.

## Uma senha é pedida

```
ana@vm:~/boxoffice$ psql -h localhost -w boxoffice -c "SELECT 1"
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: fe_sendauth: no password supplied
```

O `-h localhost` conecta por TCP em vez do socket, e **o PostgreSQL do Ubuntu pede senha em conexões
TCP, até vindas da mesma máquina**; o `-w` diz ao `psql` para não perguntar, então ele falha na hora em
vez de esperar. O remédio não é dar uma senha ao seu role: é usar o socket, que é o que o
`host=/var/run/postgresql` do `DATABASE_URL` faz. Se uma ferramenta insiste em TCP, uma senha definida
com `ALTER ROLE` no `psql` é o caminho, e ela passa a viajar na URL ou num arquivo `~/.pgpass`.

## E do lado do boxoffice

O boxoffice da seção 09 confere as duas pré-condições dele antes de abrir uma porta:

```
ana@vm:~/boxoffice$ BOXOFFICE_MANAGER_TOKEN=x go run .
2026/10/16 19:56:40 no database: set DATABASE_URL
exit status 1
ana@vm:~/boxoffice$ BOXOFFICE_MANAGER_TOKEN=x DATABASE_URL='postgres:///nowhere?host=/var/run/postgresql' go run .
2026/10/16 19:56:41 database: failed to connect to `user=ana database=nowhere`: /var/run/postgresql/.s.PGSQL.5432 (/var/run/postgresql): server error: FATAL: database "nowhere" does not exist (SQLSTATE 3D000)
exit status 1
```

O segundo erro é do pgx, e se lê como os de cima: qual usuário e qual banco ele tentou, por qual
socket, e a resposta do próprio PostgreSQL com o seu **SQLSTATE**, `3D000`, o código de cinco
caracteres que todo erro do PostgreSQL traz. A seção 08 usa dois desses códigos de propósito.
