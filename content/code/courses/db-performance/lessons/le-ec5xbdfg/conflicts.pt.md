---
title: A consulta que a réplica cancela, e o preço de mantê-la
version: 1
---

Uma réplica parece o lugar para mandar as leituras longas: o relatório que varre um ano, a exportação
que roda por dez minutos. São leituras, tirariam um processador do primário, e a réplica tem
processador sobrando. Aí o relatório falha no meio com um erro que ninguém viu antes, e falha mais
quanto mais ocupado está o primário. A crença a corrigir é a de que uma réplica só recebe mudanças.
**Ela também precisa aplicá-las enquanto a sua consulta lê**, e às vezes as duas coisas não cabem
juntas.

## Por que a reaplicação e uma consulta colidem

A aula 15 mostrou que o `VACUUM` remove versões de linha que nenhuma transação ainda enxerga, e que
uma transação longa as segura. No primário, o `VACUUM` conhece todas as transações, então nunca
remove uma linha que alguém está lendo. Ele **não** conhece as consultas rodando numa réplica. Remove
as linhas, a remoção vai para o WAL, e a réplica precisa reaplicá-la enquanto uma das suas consultas
talvez ainda precise daquelas linhas.

A réplica tem duas escolhas: pausar a reaplicação até a consulta terminar, ficando mais atrasada, ou
cancelar a consulta. Ela pausa por no máximo **`max_standby_streaming_delay`**, 30 segundos por
padrão, e então cancela. Encurte para 5 segundos na réplica e tire o atraso da seção anterior. Depois
monte a colisão com duas sessões ao mesmo tempo: na réplica, uma transação que lê os eventos mais
antigos e fica aberta; no primário, três segundos depois, um `DELETE` desses eventos e um `VACUUM`.
Primeiro as configurações, em `psql -p 5433 market` na réplica:

```
market=# ALTER SYSTEM RESET recovery_min_apply_delay;
ALTER SYSTEM
Time: 4.574 ms

market=# ALTER SYSTEM SET max_standby_streaming_delay = '5s';
ALTER SYSTEM
Time: 2.147 ms

market=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

Time: 0.723 ms
```

Sessão A, na réplica:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.357 ms

market=*# SELECT count(*) FROM events WHERE at < '2025-10-04';
 count 
-------
 55284
(1 row)

Time: 172.093 ms

market=*# SELECT pg_sleep(30);
ERROR:  canceling statement due to conflict with recovery
DETAIL:  User query might have needed to see row versions that must be removed.
Time: 8991.526 ms (00:08.992)

market=!# ROLLBACK;
ROLLBACK
Time: 0.258 ms
```

Sessão B, no primário, iniciada três segundos depois da A:

```
market=# DELETE FROM events WHERE at < '2025-10-04';
DELETE 55284
Time: 638.095 ms

market=# VACUUM events;
VACUUM
Time: 5.152 ms
```

O primário apagou **55284** eventos e os removeu com o vacuum em 5 milissegundos, sem ideia de que
alguém ainda os queria. A transação da réplica, um `REPEATABLE READ` cujo snapshot ainda inclui
aquelas linhas, foi cancelada **8992 milissegundos** depois de começar a dormir. São três segundos
esperando a B, cerca de um para o `DELETE`, e os cinco que a réplica deixou a reaplicação esperar:
**`canceling statement due to conflict with recovery`**, `User query might have needed to see row
versions that must be removed`. A transação fica abortada, `market=!#`, e o log da réplica registra
cada uma:

```
ana@vm:~$ sudo tail -n 3 /var/log/postgresql/postgresql-16-replica.log
2026-10-10 22:51:07.770 -03 [3619] ana@market ERROR:  canceling statement due to conflict with recovery
2026-10-10 22:51:07.770 -03 [3619] ana@market DETAIL:  User query might have needed to see row versions that must be removed.
2026-10-10 22:51:07.770 -03 [3619] ana@market STATEMENT:  SELECT pg_sleep(30);
```

Essas linhas são o que procurar quando relatórios numa réplica falham ao acaso. A visão
`pg_stat_database_conflicts` na réplica as conta por banco e por tipo; este tipo é `confl_snapshot`.
Linhas removidas são a causa mais comum, e não a única: um `DROP TABLE`, ou qualquer outra coisa que
pegue uma trava (lock) `ACCESS EXCLUSIVE` no primário, conflita do mesmo jeito com toda consulta
naquela tabela na réplica.

## Manter a consulta, e o que isso custa ao primário

O **`hot_standby_feedback`** faz a réplica contar ao primário de quais linhas as suas consultas ainda
precisam, e o `VACUUM` do primário as deixa em paz. Ligue-o, na réplica, e repita a colisão com o dia
seguinte de eventos:

```
market=# ALTER SYSTEM SET hot_standby_feedback = on;
ALTER SYSTEM
Time: 2.541 ms

market=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

Time: 0.663 ms
```

Sessão A, na réplica:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.256 ms

market=*# SELECT count(*) FROM events WHERE at < '2025-10-05';
 count 
-------
 55395
(1 row)

Time: 214.634 ms

market=*# SELECT pg_sleep(15);
 pg_sleep 
----------
 
(1 row)

Time: 15015.869 ms (00:15.016)

market=*# ROLLBACK;
ROLLBACK
Time: 0.227 ms
```

Sessão B, no primário:

```
market=# DELETE FROM events WHERE at < '2025-10-05';
DELETE 55395
Time: 473.174 ms

market=# VACUUM (VERBOSE) events;
INFO:  vacuuming "market.public.events"
INFO:  finished vacuuming "market.public.events": index scans: 0
pages: 0 removed, 65432 remain, 1450 scanned (2.22% of total)
tuples: 0 removed, 4944521 remain, 55395 are dead but not yet removable
removable cutoff: 1579487, which was 1 XIDs old when operation ended
frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
index scan bypassed: 724 pages from table (1.11% of total) have 55284 dead item identifiers
avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
buffer usage: 2216 hits, 0 misses, 0 dirtied
WAL usage: 1 records, 0 full page images, 188 bytes
system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
```

O sono da réplica durou os **15 segundos** inteiros e a transação terminou normalmente. No primário,
o `VACUUM (VERBOSE)` diz por quê: **`55395 are dead but not yet removable`**, e `0 removed`. As
linhas de que o snapshot da réplica precisava continuam na tabela, porque a réplica pediu. Depois
deste relatório a mesma saída se repete para a tabela TOAST de `events`, vazia, e termina com
`VACUUM`.

Então o conflito não sumiu. Mudou de lugar. Sem feedback, a réplica cancela as próprias consultas.
Com ele, uma consulta longa na réplica segura o `VACUUM` **no primário**, exatamente como uma
transação longa no primário faz na aula 15. Linhas mortas se acumulam nas tabelas em que o primário
escreve, as tabelas e os índices incham, e toda consulta que as lê paga. Uma réplica montada para
tirar carga do primário pode, por uma configuração e um relatório esquecido, deixar o primário mais
lento.

## Escolhendo

Nenhuma configuração dá as duas coisas, então escolha pelo que a réplica faz:

| a réplica atende | configure | e aceite |
|---|---|---|
| leituras curtas: páginas, buscas, painéis | o padrão: `hot_standby_feedback` desligado, espera de 30 s | uma consulta cancelada de vez em quando, que a aplicação repete |
| relatórios longos que precisam terminar | `hot_standby_feedback` ligado | inchaço no primário enquanto rodam; fique de olho |
| relatórios, e uma réplica que pode virar o primário | uma réplica separada para cada trabalho | mais um servidor |

Uma réplica que também está de prontidão para failover não deveria ser a que roda relatórios de uma
hora, seja qual for a configuração: com feedback ela incha o primário, e com um
`max_standby_streaming_delay` longo ela fica para trás, que é o pior momento para promovê-la. A aula
15 de `db-reliability` trata dessa escolha.

## Pondo a máquina de volta

A réplica é um segundo servidor inteiro com uma cópia de cada banco: remova-a quando terminar. O
`pg_dropcluster` a para e apaga o diretório de dados e a configuração dela:

```
ana@vm:~$ sudo pg_dropcluster 16 replica --stop
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

Um cluster de novo. As configurações do primário estão intactas, já que toda mudança desta aula foi
feita com `ALTER SYSTEM` na réplica, que foi embora com ela. As linhas não: os dois `DELETE`s
removeram os dois primeiros dias de `events`, dois pedidos foram cancelados, e as rodadas de compra
acrescentaram uns quarenta mil pedidos. Feche o `psql` e rode o `~/reset-market.sh` antes da aula 21.
