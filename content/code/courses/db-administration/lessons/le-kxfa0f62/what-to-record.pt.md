---
title: O que registrar
version: 1
---

Do jeito que vem, o servidor registra a própria vida — subir, parar, checkpoints — e qualquer coisa
de `WARNING` para cima (`log_min_messages`). Isso basta para dizer que o servidor está com problema
e não basta para dizer por quê. Cinco parâmetros preenchem a lacuna, e cada um escreve um tipo de
linha que você vai agradecer no dia em que algo estiver lento. Eles valem a partir de um reload:

```
shop=# ALTER SYSTEM SET log_min_duration_statement = '50ms';
ALTER SYSTEM

shop=# ALTER SYSTEM SET log_lock_waits = on;
ALTER SYSTEM

shop=# ALTER SYSTEM SET log_temp_files = 0;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

## Comandos lentos

O **`log_min_duration_statement`** escreve todo comando que levou mais que o valor, com a sua
duração. Cinquenta milissegundos é baixo, escolhido para que a demonstração tenha o que pegar; num
servidor de verdade o valor é o que "lento demais" significa para aquela aplicação, muitas vezes de
algumas centenas de milissegundos a um segundo.

```
shop=# SELECT count(*) FROM orders WHERE status = 'cancelled' AND total_cents > 49000;
 count 
-------
  6000
(1 row)

shop=# SELECT name FROM customers WHERE id = 42;
    name     
-------------
 Customer 42
(1 row)
```

```
ana@db:~$ sudo grep duration: /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:44:32.075 -03 [234] ana@shop psql LOG:  duration: 81.265 ms  statement: SELECT count(*) FROM orders WHERE status = 'cancelled' AND total_cents > 49000;
```

A contagem leu a tabela inteira e está no log. A busca pela chave primária não está, e **esse é o
sentido de um limiar**: o log guarda os comandos que merecem uma olhada e não os milhões que foram
bem. O pg_stat_statements da lição 18 soma todo comando pela forma; esta linha é a ocorrência
única, com os valores reais, que é o que você cola num `EXPLAIN ANALYZE`.

## Ordenações que transbordaram para o disco

O **`log_temp_files = 0`** escreve uma linha para cada arquivo temporário que uma consulta precisou
criar, com o tamanho. Uma ordenação ou um hash que não cabe no `work_mem` transborda, que é o
assunto da lição 6. Aqui o `work_mem` é reduzido numa sessão para que uma ordenação de um milhão de
valores não caiba:

```
shop=# SET work_mem = '1MB';
SET

shop=# SELECT count(DISTINCT total_cents) FROM orders;
 count 
-------
 50000
(1 row)
```

```
ana@db:~$ sudo grep -A1 'temporary file' /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:44:34.027 -03 [245] ana@shop psql LOG:  temporary file: path "base/pgsql_tmp/pgsql_tmp245.0", size 12050432
2026-10-10 16:44:34.027 -03 [245] ana@shop psql STATEMENT:  SELECT count(DISTINCT total_cents) FROM orders;
```

O `size` está em bytes: cerca de doze megabytes escritos e lidos de volta por uma ordenação que
teria rodado em memória com um `work_mem` maior. Um valor acima de zero registra só arquivos acima
de tantos kilobytes, o que num servidor movimentado deixa de fora os pequenos sobre os quais ninguém
vai agir.

## Esperas por trava

O **`log_lock_waits`** escreve uma linha quando uma sessão esperou por uma trava mais que o
`deadlock_timeout`, um segundo por padrão. Dois terminais produzem uma. No primeiro, uma transação
atualiza uma linha e dorme quatro segundos antes do commit:

```
ana@db:~$ psql shop -c "BEGIN; UPDATE customers SET name = name WHERE id = 1; SELECT pg_sleep(4); COMMIT;"
BEGIN
UPDATE 1
 pg_sleep 
----------
 
(1 row)

COMMIT
```

No segundo, enquanto o primeiro ainda dorme, a mesma linha:

```
ana@db:~$ psql shop -c "UPDATE customers SET name = name WHERE id = 1"
UPDATE 1
```

O segundo `UPDATE` ficou calado até o primeiro fazer commit. O log diz o que ele estava fazendo:

```
ana@db:~$ sudo tail -n 9 /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:44:36.801 -03 [258] ana@shop psql LOG:  process 258 still waiting for ShareLock on transaction 782 after 1000.153 ms
2026-10-10 16:44:36.801 -03 [258] ana@shop psql DETAIL:  Process holding the lock: 254. Wait queue: 258.
2026-10-10 16:44:36.801 -03 [258] ana@shop psql CONTEXT:  while updating tuple (0,1) in relation "customers"
2026-10-10 16:44:36.801 -03 [258] ana@shop psql STATEMENT:  UPDATE customers SET name = name WHERE id = 1
2026-10-10 16:44:38.740 -03 [254] ana@shop psql LOG:  duration: 4009.722 ms  statement: BEGIN; UPDATE customers SET name = name WHERE id = 1; SELECT pg_sleep(4); COMMIT;
2026-10-10 16:44:38.740 -03 [258] ana@shop psql LOG:  process 258 acquired ShareLock on transaction 782 after 2939.305 ms
2026-10-10 16:44:38.740 -03 [258] ana@shop psql CONTEXT:  while updating tuple (0,1) in relation "customers"
2026-10-10 16:44:38.740 -03 [258] ana@shop psql STATEMENT:  UPDATE customers SET name = name WHERE id = 1
2026-10-10 16:44:38.741 -03 [258] ana@shop psql LOG:  duration: 2940.940 ms  statement: UPDATE customers SET name = name WHERE id = 1
```

**A linha `DETAIL` dá o processo que segurava a trava**, e o comando do primeiro terminal também está
no log, com os seus quatro segundos, porque passou do `log_min_duration_statement`. Juntas, elas
dizem quem bloqueou quem e com o quê, escrito enquanto acontecia. Uma sessão bloqueada que foi
cancelada antes de alguém olhar não deixa nada no `pg_stat_activity`; deixa estas linhas. Encontrar
quem bloqueia, ao vivo, é a lição 13 de db-performance.

## Conexões

O **`log_connections`** e o **`log_disconnections`** escrevem uma linha quando uma sessão chega e
quando termina:

```
shop=# ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM

shop=# ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

```
ana@db:~$ psql shop -c "SELECT 1"
 ?column? 
----------
        1
(1 row)

ana@db:~$ sudo grep -E 'connection (received|authenticated|authorized)|disconnection' /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:44:41.991 -03 [99] LOG:  parameter "log_disconnections" changed to "on"
2026-10-10 16:44:42.423 -03 [275] [unknown]@[unknown] [unknown] LOG:  connection received: host=[local]
2026-10-10 16:44:42.423 -03 [275] ana@shop [unknown] LOG:  connection authenticated: identity="ana" method=peer (/etc/postgresql/16/main/pg_hba.conf:123)
2026-10-10 16:44:42.423 -03 [275] ana@shop [unknown] LOG:  connection authorized: user=ana database=shop application_name=psql
2026-10-10 16:44:42.425 -03 [275] ana@shop psql LOG:  disconnection: session time: 0:00:00.002 user=ana database=shop host=[local]
```

Três linhas para chegar e uma para sair. A linha `authenticated` dá o método e **a linha do
`pg_hba.conf` que casou**, que é o jeito mais rápido de responder à pergunta da lição 5, de por que
uma conexão entrou ou foi recusada. A linha `disconnection` traz a duração da sessão. Num servidor
cuja aplicação abre uma conexão por requisição, esses dois parâmetros escrevem um par de linhas por
requisição, que é o argumento da lição 10 a favor de um pool, visto pelo outro lado.

## Checkpoints, já ligados

O **`log_checkpoints`** vem ligado por padrão desde o PostgreSQL 16. Um `CHECKPOINT` manual mostra
o par de linhas que ele escreve:

```
shop=# CHECKPOINT;
CHECKPOINT
```

```
ana@db:~$ sudo grep checkpoint /var/log/postgresql/postgresql-16-main.log | tail -n 2
2026-10-10 16:44:43.295 -03 [103] LOG:  checkpoint starting: immediate force wait
2026-10-10 16:44:43.529 -03 [103] LOG:  checkpoint complete: wrote 15298 buffers (93.4%); 0 WAL file(s) added, 0 removed, 20 recycled; write=0.114 s, sync=0.113 s, total=0.235 s; sync files=620, longest=0.074 s, average=0.001 s; distance=331117 kB, estimate=331117 kB; lsn=0/1584AD88, redo lsn=0/1584AD50
```

O `[%p]` aqui é o checkpointer, e o `%q` deixou de fora o usuário e o banco. A lição 8 lê os números
da linha `complete`. Para o log, a palavra útil está na linha `starting`: o motivo, `immediate force
wait` para este manual, e `time` ou `wal` para os que o próprio servidor inicia. Um servidor que
escreve `wal` ali o tempo todo está fazendo checkpoint porque ficou sem espaço de WAL, e não porque
o relógio mandou.

## E o autovacuum

O **`log_autovacuum_min_duration`** é o último do conjunto. O seu padrão, `600000`, está em
milissegundos: uma execução do autovacuum que levou mais de dez minutos é registrada, o que na
maioria dos servidores não é nenhuma. A lição 14 o reduz e lê o que o autovacuum relata.

Um conjunto razoável para começar num servidor de produção é, então: um limiar de comando lento
com que os donos da aplicação concordem, `log_lock_waits = on`, `log_temp_files` em alguns
megabytes, conexões ligadas a menos que a taxa de conexões seja muito alta, e os checkpoints como
estão. **Cada um desses escreve linhas só quando aconteceu algo que vale ler.** A próxima seção mede
o único parâmetro que não funciona assim.
