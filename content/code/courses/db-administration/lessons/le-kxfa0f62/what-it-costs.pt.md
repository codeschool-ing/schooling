---
title: Quanto custa
version: 1
---

**`log_statement = 'all'` escreve todo comando que o servidor recebe**, e é o ajuste que as pessoas
procuram quando querem saber o que uma aplicação está fazendo. Parece a escolha segura e completa.
O custo é fácil de medir, então meça antes de ligá-lo em qualquer lugar de verdade.

## Uma execução fixa

O teste do próprio pgbench é uma boa régua porque é fixo: toda transação é os mesmos sete comandos.
Primeiro saem as linhas de conexão e o limiar de comando lento, para que sobre um log que só escreve
quando algo dá errado:

```
shop=# ALTER SYSTEM RESET log_connections;
ALTER SYSTEM

shop=# ALTER SYSTEM RESET log_disconnections;
ALTER SYSTEM

shop=# ALTER SYSTEM RESET log_min_duration_statement;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

Depois um banco para ele, na escala 10 (um milhão de linhas na tabela principal):

```
ana@db:~$ createdb bench
ana@db:~$ pgbench -i -q -s 10 bench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
1000000 of 1000000 tuples (100%) done (elapsed 0.72 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 1.13 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.74 s, vacuum 0.13 s, primary keys 0.25 s).
```

As linhas `NOTICE` são o pgbench conferindo que não há tabelas velhas no caminho. Agora um script
que roda exatamente 10.000 transações — quatro conexões, 2.500 cada — e informa quantos bytes o log
cresceu. Salve como `logcost.sh`:

```bash
#!/usr/bin/env bash
# logcost.sh: how many bytes one fixed pgbench run adds to the server log
log=/var/log/postgresql/postgresql-16-main.log
before=$(sudo stat -c %s "$log")
pgbench -n -c 4 -t 2500 bench | grep -E 'processed|tps'
after=$(sudo stat -c %s "$log")
echo "the log grew by $((after - before)) bytes"
```

Rode uma vez com o log como está:

```
ana@db:~$ bash logcost.sh
number of transactions actually processed: 10000/10000
tps = 1555.658264 (without initial connection time)
the log grew by 0 bytes
```

Nada. Nenhum dos 70.000 comandos foi lento, esperou por trava ou transbordou para o disco.

## Todo comando

```
shop=# ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

```
ana@db:~$ bash logcost.sh
number of transactions actually processed: 10000/10000
tps = 1283.249475 (without initial connection time)
the log grew by 8758557 bytes
ana@db:~$ sudo tail -n 7 /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:45:02.948 -03 [336] ana@bench pgbench LOG:  statement: BEGIN;
2026-10-10 16:45:02.949 -03 [336] ana@bench pgbench LOG:  statement: UPDATE pgbench_accounts SET abalance = abalance + 4997 WHERE aid = 315396;
2026-10-10 16:45:02.949 -03 [336] ana@bench pgbench LOG:  statement: SELECT abalance FROM pgbench_accounts WHERE aid = 315396;
2026-10-10 16:45:02.949 -03 [336] ana@bench pgbench LOG:  statement: UPDATE pgbench_tellers SET tbalance = tbalance + 4997 WHERE tid = 76;
2026-10-10 16:45:02.949 -03 [336] ana@bench pgbench LOG:  statement: UPDATE pgbench_branches SET bbalance = bbalance + 4997 WHERE bid = 9;
2026-10-10 16:45:02.949 -03 [336] ana@bench pgbench LOG:  statement: INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (76, 9, 315396, 4997, CURRENT_TIMESTAMP);
2026-10-10 16:45:02.952 -03 [336] ana@bench pgbench LOG:  statement: END;
```

**8758557 bytes para 10.000 transações**: cerca de 876 bytes por transação, 125 por comando, cada
um deles uma linha como as sete acima, que são uma transação inteira de um processo. A conta é o
que importa. Uma aplicação modesta, com 100 transações por segundo, dia e noite, escreveria
876 × 100 × 86.400 bytes, cerca de 7,6 GB de log por dia, só por causa desse ajuste.

A vazão é o custo que as pessoas esperam, e na máquina da gravação não deu para lê-la nessas
execuções: o pgbench informou 1555.7 transações por segundo sem nada no log, 1283.2 com todos os
comandos, e 1875.2 na execução seguinte, que também registrava todos os comandos. A máquina era
compartilhada com outros trabalhos, e o ruído foi maior que o efeito. Escrever uma linha num
arquivo que o kernel bufferiza é barato por linha. Num servidor já curto de banda de disco, ou num
cujo log fica no mesmo disco que os dados, deixa de ser barato, e onde isso aparece é na latência
de todo mundo.

## Todo comando, com a duração

O `log_min_duration_statement = 0` é o outro jeito de registrar tudo: um limiar de zero
milissegundos pega todo comando, e cada linha traz quanto tempo ele levou.

```
shop=# ALTER SYSTEM RESET log_statement;
ALTER SYSTEM

shop=# ALTER SYSTEM SET log_min_duration_statement = 0;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

```
ana@db:~$ bash logcost.sh
number of transactions actually processed: 10000/10000
tps = 1875.154817 (without initial connection time)
the log grew by 10159212 bytes
ana@db:~$ sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:45:10.194 -03 [364] ana@bench pgbench LOG:  duration: 2.666 ms  statement: END;
```

10159212 bytes, 1,4 MB a mais que `log_statement = 'all'` para a mesma execução, porque cada linha
carrega também `duration: … ms`. Em troca, cada linha diz quanto tempo o seu comando levou, que é a
versão de *registrar tudo* que vale a pena numa investigação curta: o comando lento pelo menos vem
etiquetado.

```
shop=# ALTER SYSTEM RESET log_min_duration_statement;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

## O que os bytes compram

O disco é o custo que dá para contar, e não é o único. Um log desse tamanho precisa ser girado,
comprimido, enviado e pesquisado, e **uma linha que importa agora é uma entre dezenas de milhares**.
O comando lento, a espera por trava e o erro continuam lá, enterrados sob todo `BEGIN` e `END` que a
aplicação já mandou. E todo literal de todo comando está no arquivo em texto puro: o e-mail do
cliente, o endereço, a senha da chamada de `crypt` da lição anterior.

Então o `log_statement = 'all'` é uma ferramenta para uma janela curta — alguns minutos num servidor
de teste, ou um papel com `ALTER ROLE … SET log_statement = 'all'` enquanto você observa uma
aplicação — e nunca um padrão. **`log_statement = 'ddl'` é o valor permanente útil**: ele registra
todo `CREATE`, `ALTER` e `DROP`, o que na maioria dos servidores é um punhado de linhas por semana e
exatamente as que alguém pergunta depois que uma tabela some.
