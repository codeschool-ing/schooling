---
title: A linha de log para as esperas que ninguém viu
version: 1
---

Tudo até aqui precisou de alguém na janela D enquanto a espera acontecia. A maioria das esperas por
trava termina antes de alguém olhar: uma parada de dois segundos às 03:00, uma página que ficou
lenta por um minuto depois de um deploy. A crença comum é que uma espera que não terminou em erro
não deixa rastro. Por padrão, é verdade. **Uma configuração faz o servidor escrever uma linha para
toda espera por trava que passe de um segundo**, com os mesmos fatos que a janela D teve de ir
buscar.

## Ligando

O `log_lock_waits` vem desligado. Ligue-o com `ALTER SYSTEM` e recarregue, como a aula 2 fez para o
log de consultas lentas; não precisa reiniciar:

```
market=# ALTER SYSTEM SET log_lock_waits = on;
ALTER SYSTEM
Time: 2.562 ms

market=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

Time: 0.758 ms

market=# SHOW deadlock_timeout;
 deadlock_timeout 
------------------
 1s
(1 row)

Time: 1.184 ms
```

O limite não é uma configuração própria. É o **`deadlock_timeout`**, o mesmo um segundo depois do
qual uma sessão que espera procura um deadlock, como a seção 06 da aula 12 mostrou. Nesse momento
ela procura um ciclo e não acha nenhum, e com o `log_lock_waits` ligado, anota que continua
esperando. Uma checagem, dois usos, e custo nenhum para esperas menores que um segundo.

## Uma espera, registrada

Duas janelas. A janela A muda o pedido 3 e segura a transação aberta por alguns segundos antes de
confirmar; a janela B tenta mudar o mesmo pedido nesse meio-tempo:

```
market=# BEGIN;
BEGIN
Time: 0.475 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 3;
UPDATE 1
Time: 1.796 ms

market=*# COMMIT;
COMMIT
Time: 2.432 ms
```

```
market=# UPDATE orders SET status = 'cancelled' WHERE id = 3;
UPDATE 1
Time: 7288.342 ms (00:07.288)
```

A janela B esperou **7288 ms**. Agora leia o log:

```
ana@vm:~$ sudo tail -n 8 /var/log/postgresql/postgresql-16-main.log
2026-10-15 21:52:04.088 -03 [5743] LOG:  parameter "log_lock_waits" changed to "on"
2026-10-15 21:52:07.220 -03 [5813] ana@market LOG:  process 5813 still waiting for ShareLock on transaction 1609209 after 1000.266 ms
2026-10-15 21:52:07.220 -03 [5813] ana@market DETAIL:  Process holding the lock: 5811. Wait queue: 5813.
2026-10-15 21:52:07.220 -03 [5813] ana@market CONTEXT:  while updating tuple (0,3) in relation "orders"
2026-10-15 21:52:07.220 -03 [5813] ana@market STATEMENT:  UPDATE orders SET status = 'cancelled' WHERE id = 3;
2026-10-15 21:52:13.504 -03 [5813] ana@market LOG:  process 5813 acquired ShareLock on transaction 1609209 after 7284.947 ms
2026-10-15 21:52:13.504 -03 [5813] ana@market CONTEXT:  while updating tuple (0,3) in relation "orders"
2026-10-15 21:52:13.504 -03 [5813] ana@market STATEMENT:  UPDATE orders SET status = 'cancelled' WHERE id = 3;
```

Duas entradas, uma quando a espera passou de um segundo e outra quando terminou, e entre elas o
incidente inteiro:

- **`still waiting for ShareLock on transaction 1609209 after 1000.266 ms`** — o processo 5813 está
  há um segundo esperando outra transação terminar, que, como a seção 02 desta aula mostrou, é como
  fica a espera por uma linha.
- **`Process holding the lock: 5811. Wait queue: 5813.`** — por quem ele esperava, e quem mais
  estava na fila. É o `pg_blocking_pids` anotado no momento em que importava.
- **`while updating tuple (0,3) in relation "orders"`** — a linha, página 0, tupla 3: o pedido 3.
- **`STATEMENT:`** — o comando que esperava, inteiro.
- **`acquired ShareLock … after 7284.947 ms`** — quando a espera terminou, e quanto durou. A
  diferença para os 7288 ms da própria janela B é o tempo que o update em si levou depois de ter a
  trava.

O que o log **não** diz é o que o processo 5811 estava fazendo, porque o 5811 não estava esperando e
não escreveu nada. Ponha o id de processo em toda linha de log, o que o `log_line_prefix` padrão do
Ubuntu já faz (o `[5813]` depois da hora), e os comandos anteriores de quem segurava a trava estão
no mesmo arquivo, sob o número dele, se o log de consultas lentas da aula 2 ou um log de comandos os
pegou.

## Quanto custa, e onde se encaixa

Uma linha por espera maior que o `deadlock_timeout`, escrita pela própria sessão que espera. Num
servidor saudável isso é quase nada; num servidor com problema de trava são algumas linhas por
segundo, e é essa a ideia. **Deixe ligado.** Baixar o `deadlock_timeout` para ver esperas menores é
tentador e costuma ser errado: toda sessão que espera passa a pagar mais cedo por uma checagem de
deadlock, e o padrão existe porque um segundo é muita espera para uma transação que vai terminar.

As três ferramentas desta aula cobrem três momentos. **O log** diz, na manhã seguinte, que houve
esperas, quanto duraram e em que linha. **`blocked.sql` e `lock-tree.sql`** dizem, durante um
incidente, quem é a raiz agora. **`pg_locks`** diz, quando os outros dois não bastam, exatamente
qual trava, sobre o quê. A aula 23 transforma os dois primeiros em alertas.

Num servidor que você administra, deixe ligado. Na máquina deste curso, desligue antes da aula 14,
para que a configuração seja a mesma de que toda aula parte, e ponha o `market` de volta:

```sql
ALTER SYSTEM RESET log_lock_waits;
SELECT pg_reload_conf();
```

Depois feche todas as janelas e rode `~/reset-market.sh`.
