---
title: Uma réplica no notebook, e o atraso que dá para ver
version: 1
---

**Esta seção é PostgreSQL, não Cloud SQL.** O Cloud SQL monta uma réplica PostgreSQL com a replicação
em streaming do próprio motor, e o motor está no seu notebook desde a aula 6, então o mecanismo pode
ser rodado, parado e medido aqui. O que o Cloud SQL acrescenta em volta, a cópia que tira por você, a
instância que cria, o endereço que dá à réplica, é a seção anterior e não está aqui.

Todo comando abaixo roda num terminal com as variáveis da aula 6 exportadas:

```sh
export PATH=/usr/lib/postgresql/16/bin:$PATH PGHOST=localhost PGPORT=5433 PGUSER=postgres
```

Se `~/gcp/pg/orders` não existe porque a aula 6 foi lida e não praticada, a linha de `initdb` dela, em
"Flags de banco de dados, praticadas no próprio motor", o cria.

## O primário, com algo para replicar

Inicie o cluster da aula 6 na 5433 e dê a ele uma tabela de mil pedidos:

```
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/orders -o "-p 5433 -k $HOME/gcp/pg" -l ~/gcp/pg/orders.log start
waiting for server to start.... done
server started
ana@laptop:~/gcp$ psql -c 'CREATE TABLE orders (id bigint PRIMARY KEY, customer text NOT NULL, total_cents integer NOT NULL, created timestamptz NOT NULL DEFAULT now())' -c "INSERT INTO orders (id, customer, total_cents) SELECT g, 'c-' || g % 50, 1000 + g FROM generate_series(1, 1000) g"
CREATE TABLE
INSERT 0 1000
```

## Uma réplica em três comandos

**O `pg_basebackup` copia o diretório de dados de um servidor rodando por uma conexão de
replicação**, que é o que o Cloud SQL faz por você quando uma réplica é criada. O `-R` escreve as
configurações que tornam a cópia uma réplica, o `-X stream` traz junto o log escrito durante a cópia, e
o `-c fast` pede ao primário um checkpoint agora, em vez de no próximo agendado:

```
ana@laptop:~/gcp$ pg_basebackup -D ~/gcp/pg/reports -R -X stream -c fast
ana@laptop:~/gcp$ ls ~/gcp/pg/reports | head -4 && ls ~/gcp/pg/reports/standby.signal && grep primary_conninfo ~/gcp/pg/reports/postgresql.auto.conf | cut -c1-80
PG_VERSION
backup_label
backup_manifest
base
/home/ana/gcp/pg/reports/standby.signal
primary_conninfo = 'user=postgres passfile=''/home/ana/.pgpass'' channel_binding
```

**A cópia é um diretório de dados inteiro**, e duas coisas nele o tornam uma réplica: um arquivo
chamado `standby.signal`, cuja presença diz ao servidor que inicie em recuperação e fique nela, e uma
linha `primary_conninfo`, que diz de onde fazer o streaming. Os padrões do PostgreSQL 16 bastam do
lado do primário: o `initdb` definiu `wal_level` como `replica` e permitiu dez conexões de replicação,
e o `--auth=trust` deixou entrar a local.

```
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/reports -o "-p 5434 -k $HOME/gcp/pg" -l ~/gcp/pg/reports.log start
waiting for server to start.... done
server started
ana@laptop:~/gcp$ psql -p 5434 -Atc 'SELECT pg_is_in_recovery(), count(*) FROM orders'
t|1000
ana@laptop:~/gcp$ psql -c 'SELECT application_name, state, sync_state FROM pg_stat_replication'
 application_name |   state   | sync_state 
------------------+-----------+------------
 walreceiver      | streaming | async
(1 row)
```

**`t` em `pg_is_in_recovery()`, e os mil pedidos**, na porta 5434. No primário, `pg_stat_replication`
tem uma linha por réplica conectada a ele, e `sync_state` diz `async`: o primário não espera por esta,
que é a metade assíncrona da figura da seção anterior.

## Uma réplica recusa escritas

```
ana@laptop:~/gcp$ psql -p 5434 -c "INSERT INTO orders (id, customer, total_cents) VALUES (5001, 'c-7', 4590)"
ERROR:  cannot execute INSERT in a read-only transaction
```

**Quem recusa é o próprio motor**, não uma configuração que alguém lembrou de fazer: um servidor em
recuperação roda toda transação como só leitura. Uma réplica de leitura do Cloud SQL recusa do mesmo
jeito, porque é o mesmo motor no mesmo estado. Uma aplicação que manda as escritas para o endereço da
réplica descobre isso no primeiro `INSERT`.

## O atraso, à vista

Num notebook o atraso é de poucos milissegundos, curto demais para ver. Então impeça a réplica de
aplicar o que recebe, escreva no primário, e olhe os dois:

```
ana@laptop:~/gcp$ psql -p 5434 -c 'SELECT pg_wal_replay_pause()'
 pg_wal_replay_pause 
---------------------
 
(1 row)

ana@laptop:~/gcp$ psql -c "INSERT INTO orders (id, customer, total_cents) SELECT g, 'c-' || g % 50, 1000 + g FROM generate_series(1001, 1100) g"
INSERT 0 100
ana@laptop:~/gcp$ psql -Atc 'SELECT count(*) FROM orders' && psql -p 5434 -Atc 'SELECT count(*) FROM orders'
1100
1000
ana@laptop:~/gcp$ psql -c 'SELECT pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind, replay_lag FROM pg_stat_replication'
 bytes_behind |   replay_lag    
--------------+-----------------
        21952 | 00:00:00.042561
(1 row)

ana@laptop:~/gcp$ psql -p 5434 -c 'SELECT pg_wal_replay_resume()' && sleep 1 && psql -p 5434 -Atc 'SELECT count(*) FROM orders'
 pg_wal_replay_resume 
----------------------
 
(1 row)

1100
ana@laptop:~/gcp$ psql -c 'SELECT pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication'
 bytes_behind 
--------------
            0
(1 row)
```

**O primário tem 1.100 pedidos e a réplica 1.000.** A réplica recebeu os cem, e `bytes_behind` é
quanto log ela guarda sem ter aplicado, 21.952 bytes; `replay_lag` é o tempo que o primário mediu
entre enviar e o último aviso da réplica de ter aplicado, que é mais ou menos o estado da réplica antes
da pausa. Retomar leva a contagem a 1.100 e o intervalo a 0.

**É assim que o atraso aparece numa réplica de verdade**, sem a pausa: um relatório rodado no intervalo
lê mil pedidos enquanto o primário tem mil e cem. O que o torna grande numa instância de verdade é
qualquer coisa que atrase a reaplicação: uma réplica numa máquina menor que o primário, uma consulta
longa na réplica pela qual a reaplicação precisa esperar, ou uma carga em massa no primário que escreve
log mais rápido do que a réplica aplica. O Cloud SQL publica o atraso como uma métrica da réplica no
Cloud Monitoring, e um alerta nela é como um time descobre antes de o relatório sair errado.

Os dois servidores continuam no ar para a próxima seção, que comete um engano no primário e observa a
réplica copiá-lo.
