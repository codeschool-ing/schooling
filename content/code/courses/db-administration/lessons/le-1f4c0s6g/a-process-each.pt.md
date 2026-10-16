---
title: Um processo para cada conexão
version: 1
---

Muitos servidores atendem seus clientes com threads dentro de um processo só, e é fácil supor que o
PostgreSQL faz o mesmo. Ele não faz. **Cada conexão de cliente ganha um processo do sistema
operacional só para ela**, criado pelo postmaster quando o cliente conecta, e esse processo faz todo
o trabalho do cliente até ele desconectar. O PostgreSQL o chama de **backend**.

Para ver isso, abra mais dois terminais no servidor. No primeiro, conecte e deixe o prompt
esperando; no segundo, rode uma consulta que demora:

```sh
psql shop
```

```sh
psql shop -c "SELECT pg_sleep(600)"
```

Depois, no seu terminal original, liste os processos que pertencem ao `postgres`:

```
ana@db:~$ ps -u postgres -o pid,ppid,cmd
    PID    PPID CMD
    101       1 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf
    102     101 postgres: 16/main: checkpointer 
    103     101 postgres: 16/main: background writer 
    105     101 postgres: 16/main: walwriter 
    106     101 postgres: 16/main: autovacuum launcher 
    107     101 postgres: 16/main: logical replication launcher 
    204     101 postgres: 16/main: ana shop [local] idle
    219     101 postgres: 16/main: ana shop [local] SELECT
```

Os workers da lição 3 estão lá, e embaixo deles **um processo para cada terminal**. A coluna `PPID`
é o pai: todos eles foram iniciados pelo processo 101, o postmaster, que não faz nada além de aceitar
conexões e iniciar processos para atendê-las. Um backend reescreve o próprio nome para que o `ps`
possa ser lido: o cluster, o papel, o banco, onde o cliente está (`[local]` é o socket) e o que ele
está fazendo agora. Um está `idle`, esperando num prompt; o outro está no meio de um `SELECT`.

## A mesma lista vista de dentro

A `pg_stat_activity` é essa lista como o servidor a mantém, uma linha por processo, e é o que você
consulta em vez do `ps` quando precisa filtrar ou juntar:

```
ana@db:~$ psql shop
shop=# SELECT pid, backend_type, usename, state, left(query, 24) AS query
shop-#   FROM pg_stat_activity ORDER BY backend_type, pid;
 pid |         backend_type         | usename  | state  |          query           
-----+------------------------------+----------+--------+--------------------------
 106 | autovacuum launcher          |          |        | 
 103 | background writer            |          |        | 
 102 | checkpointer                 |          |        | 
 204 | client backend               | ana      | idle   | 
 219 | client backend               | ana      | active | SELECT pg_sleep(600)
 230 | client backend               | ana      | active | SELECT pid, backend_type
 107 | logical replication launcher | postgres |        | 
 105 | walwriter                    |          |        | 
(8 rows)
```

O `pid` é o mesmo número que o `ps` imprimiu, que é como você passa de uma visão para a outra. Há
três backends de cliente agora, porque a sessão que pergunta é um deles. **`state` é a coluna que
você mais vai ler**: `active` está rodando um comando, `idle` está conectado e sem fazer nada, e um
terceiro estado, que importa mais que os dois, tem uma seção própria mais adiante nesta lição. A
`query` é o último comando que o backend rodou, ou o que está rodando enquanto está `active`; a de
um backend ocioso é simplesmente o mais recente.

## Por que um processo importa

Um processo é uma coisa pesada para ter por cliente, e cada consequência desta lição vem disso:

- **conectar custa iniciar um processo**, mais a autenticação, toda vez. A última seção mede isso.
- **cada backend tem memória própria** além dos shared buffers: os seus caches do catálogo, e até
  `work_mem` para cada ordenação e cada hash que roda, que a lição 6 multiplicou.
- **os processadores são divididos entre todos eles.** Uma máquina com quatro processadores roda
  quatro backends ao mesmo tempo; os outros esperam a vez, e o kernel gasta tempo alternando entre
  eles.

Encerrar um também é, por baixo, um ato do sistema operacional. Feche os dois terminais extras antes
de seguir; os backends deles saem junto.
