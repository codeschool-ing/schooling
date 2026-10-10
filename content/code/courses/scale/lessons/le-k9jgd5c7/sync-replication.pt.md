---
title: Fazendo o primário esperar
version: 1
---

A réplica da aula 2 era **assíncrona**: o primário confirmava uma venda ao comprador e a mandava
para a réplica depois. A seção 06 daquela aula listou o que isso custa: uma réplica que responde
com o passado, e vendas confirmadas que morrem com o primário.

A **replicação síncrona** fecha essa brecha. O primário não diz ao cliente que uma transação foi
confirmada até pelo menos uma réplica confirmar que tem a mudança guardada no próprio log. Uma
venda confirmada está então em duas máquinas, e perder uma não perde nada que alguém tenha ouvido
que aconteceu.

O PostgreSQL decide quais réplicas contam com uma configuração no primário,
`synchronous_standby_names`. `'*'` quer dizer uma réplica qualquer; uma lista de nomes, ou
`ANY 2 (a, b, c)`, pede mais. Ela pode ser mudada com o servidor rodando: `ALTER SYSTEM` a grava no
arquivo de configuração do servidor e `pg_reload_conf()` faz o servidor relê-lo.

## O que custa, medido

O `pgbench` é o gerador de carga do próprio PostgreSQL, e vem na mesma imagem. `-i` cria as quatro
tabelas dele, `-s 4` as deixa quatro vezes maiores que o padrão, e uma rodada com quatro clientes
por dez segundos mede transações que atualizam três linhas e inserem uma cada. Primeiro com a
réplica assíncrona, como a aula 2 a deixou:

```
ana@lab:~/tickets$ docker compose exec db pgbench -U tickets -i -s 4 -q tickets
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
400000 of 400000 tuples (100%) done (elapsed 0.40 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.91 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.42 s, vacuum 0.14 s, primary keys 0.34 s).
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT sync_state FROM pg_stat_replication'
 sync_state 
------------
 async
(1 row)

ana@lab:~/tickets$ docker compose exec db pgbench -U tickets -n -c 4 -T 10 tickets
pgbench (16.15 (Debian 16.15-1.pgdg13+2))
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 4
query mode: simple
number of clients: 4
number of threads: 1
maximum number of tries: 1
duration: 10 s
number of transactions actually processed: 19921
number of failed transactions: 0 (0.000%)
latency average = 2.008 ms
initial connection time = 10.582 ms
tps = 1992.400653 (without initial connection time)
```

Depois a mesma rodada, depois de pedir ao primário que espere a réplica:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "ALTER SYSTEM SET synchronous_standby_names = '*'" -c 'SELECT pg_reload_conf()'
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT sync_state FROM pg_stat_replication'
 sync_state 
------------
 sync
(1 row)

ana@lab:~/tickets$ docker compose exec db pgbench -U tickets -n -c 4 -T 10 tickets
pgbench (16.15 (Debian 16.15-1.pgdg13+2))
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 4
query mode: simple
number of clients: 4
number of threads: 1
maximum number of tries: 1
duration: 10 s
number of transactions actually processed: 14392
number of failed transactions: 0 (0.000%)
latency average = 2.778 ms
initial connection time = 11.193 ms
tps = 1439.731837 (without initial connection time)
```

O `sync_state` mudou de `async` para `sync`, e as mesmas transações foram de **2,008 ms para
2,778 ms** em média, de 1992 por segundo para 1440. **Todo commit agora espera uma ida e volta até a
réplica e uma gravação no disco dela.** Aqui a réplica está na mesma máquina, atrás de uma ponte de
rede virtual, então a ida e volta é de dezenas de microssegundos e a maior parte do extra é a
gravação da própria réplica.

Em redes de verdade a ida e volta é a parte maior. Entre dois data centers na mesma cidade ela fica
perto de um milissegundo; entre São Paulo e a costa leste dos Estados Unidos passa bem de cem. Uma
réplica síncrona em outro continente soma isso a **todo commit**, e é por isso que réplicas
síncronas costumam ficar perto do primário, e as distantes ficam assíncronas.

## Qual espera

O `synchronous_commit` decide até onde o primário espera, por transação se você quiser:

| valor | o commit volta quando a mudança está | uma queda ou um failover pode perdê-la? |
|---|---|---|
| `off` | na memória do primário | sim, algumas centenas de ms de commits |
| `local` | no disco do primário | sim, se o primário se perder |
| `on` (com uma réplica síncrona) | no disco do primário e no da réplica | não |
| `remote_apply` | aplicada na réplica, visível às leituras lá | não, e uma leitura na réplica a vê |

O `remote_apply` é o que teria salvado o comprador da aula 2 de não ver o próprio ingresso. Ele
também faz todo commit esperar a réplica síncrona mais lenta terminar de aplicar, o que é a linha
mais cara da tabela.
