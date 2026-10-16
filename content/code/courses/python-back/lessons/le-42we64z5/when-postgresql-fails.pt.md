---
title: Quando o PostgreSQL recusa
version: 1
---

Preparar um servidor de banco tem mais jeitos de falhar do que instalar uma biblioteca, e cada um
imprime uma mensagem que diz a causa. Estas apareceram nesta ordem enquanto o agenda era preparado,
um passo de cada vez, que também é a ordem em que você as encontraria se pulasse um passo da seção
anterior. Cada comando fica só com a última linha do traceback, onde está a causa.

## Sem driver

```
ana@vm:~/agenda$ uv run python manage.py migrate 2>&1 | tail -1
django.core.exceptions.ImproperlyConfigured: Error loading psycopg2 or psycopg module
```

O `DATABASES` cita o PostgreSQL e o Django não consegue importar uma biblioteca para conversar com
ele. **`uv add psycopg`**, no projeto, resolve. Se o erro continuar, a biblioteca foi para outro
ambiente: confira que o comando roda por `uv run`.

## Sem papel

```
ana@vm:~/agenda$ uv run python manage.py migrate 2>&1 | tail -1
django.db.utils.OperationalError: connection failed: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

A conexão chegou ao servidor, o que é boa notícia, e o servidor não conhece o nome `ana`. Rode
**`sudo -u postgres createuser --superuser $USER`**. O caminho do socket na mensagem,
`/var/run/postgresql/.s.PGSQL.5432`, diz qual servidor respondeu: o local, na porta padrão.

## Sem banco

```
ana@vm:~/agenda$ uv run python manage.py migrate 2>&1 | tail -1
django.db.utils.OperationalError: connection failed: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "agenda" does not exist
```

Um passo adiante: o papel existe e o banco não. **`createdb agenda`**. Um erro de digitação no `NAME`
do `settings.py` produz esta mesma mensagem com o nome errado nela, e é assim que se distinguem os
dois.

## Sem servidor

Pare o servidor de propósito, e faça ao Django uma pergunta que precisa dele:

```
ana@vm:~/agenda$ sudo systemctl stop postgresql
ana@vm:~/agenda$ uv run python manage.py showmigrations events 2>&1 | tail -1
	Is the server running locally and accepting connections on that socket?
ana@vm:~/agenda$ sudo systemctl start postgresql && pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

A última linha de uma mensagem mais longa: o arquivo do socket não existe porque nada está escutando.
**Suba o servidor**, com `sudo systemctl start postgresql`, e o `pg_lsclusters` volta a dizer
`online`. Se ele não subir, o arquivo de log na última coluna do `pg_lsclusters` diz por quê, e
`sudo tail /var/log/postgresql/postgresql-16-main.log` o lê. Disco cheio e porta já em uso são as
duas causas de costume.

## Peer authentication failed

Mais uma, que estes passos evitam e que você vai encontrar a primeira vez que a configuração de um
projeto citar um `USER` diferente do seu login: `FATAL: Peer authentication failed for user
"agenda"`. Pelo socket local, o PostgreSQL do Ubuntu só aceita um papel cujo nome bate com o usuário
do sistema operacional que conecta. Um papel de aplicação, com senha, conecta por TCP, com
`'HOST': 'localhost'` na configuração, e a aula 15 faz exatamente isso. Esta não foi produzida para
este curso.
