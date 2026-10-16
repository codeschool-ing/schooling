---
title: O REINDEX, e quem espera enquanto ele roda
version: 1
---

O `REINDEX` constrói o índice de novo a partir da tabela, num arquivo novo, e joga o arquivo antigo
fora. A lição 4 mostrou que o arquivo de uma tabela tem por nome um número que muda quando a tabela
é reescrita, e um índice se comporta do mesmo jeito:

```
shop=# SELECT pg_relation_filepath('orders_created_at');
 pg_relation_filepath 
----------------------
 base/16386/16411
(1 row)

shop=# REINDEX INDEX orders_created_at;
REINDEX

shop=# SELECT pg_relation_filepath('orders_created_at');
 pg_relation_filepath 
----------------------
 base/16386/16425
(1 row)
```

Ele vem em tamanhos: `REINDEX INDEX` para um, `REINDEX TABLE` para todos os índices de uma tabela, e
`SCHEMA`, `DATABASE` e `SYSTEM` acima disso. O tamanho do trabalho não é a parte interessante. O
lock é.

## Três terminais e um REINDEX

Reconstruir este índice leva menos de um segundo, curto demais para olhar qualquer coisa enquanto
roda. Então o primeiro terminal abre uma transação, reindexa dentro dela e mantém a transação
aberta: os locks que o `REINDEX` pega ficam presos até o `COMMIT`, que é o que uma reconstrução longa
de um índice grande faz de qualquer jeito, por minutos. Abra quatro terminais no servidor, rode
`psql shop` em cada um, e digite `\timing on` no segundo e no terceiro, para eles dizerem quanto
tempo cada comando levou.

No terminal 1:

```
shop=# BEGIN;
BEGIN

shop=*# REINDEX INDEX orders_created_at;
REINDEX
```

No terminal 2, uma consulta que não tem nada a ver com `created_at`. Ela trava:

```
shop=# SELECT count(*) FROM orders WHERE customer_id = 42;
 count 
-------
    20
(1 row)

Time: 6880.993 ms (00:06.881)
```

No terminal 3, um update de uma linha. Também trava:

```
shop=# UPDATE orders SET total_cents = total_cents WHERE id = 1;
UPDATE 1
Time: 5280.572 ms (00:05.281)
```

As linhas `Time:` são quanto cada um esperou, e só foram impressas no fim, quando o terminal 1
soltou. Enquanto eles esperavam, o terminal 4 perguntou à `pg_locks` quem segura o quê na tabela e
no índice:

```
shop=# SELECT l.pid, l.relation::regclass, l.mode, l.granted, pg_blocking_pids(l.pid) AS blocked_by FROM pg_locks l WHERE l.relation IN ('orders'::regclass, 'orders_created_at'::regclass) ORDER BY l.pid, l.relation;
 pid |     relation      |        mode         | granted | blocked_by 
-----+-------------------+---------------------+---------+------------
 319 | orders            | AccessShareLock     | t       | {324}
 319 | orders_created_at | AccessShareLock     | f       | {324}
 321 | orders            | RowExclusiveLock    | f       | {324}
 324 | orders            | ShareLock           | t       | {}
 324 | orders_created_at | AccessExclusiveLock | t       | {}
(5 rows)
```

Cada linha é um lock, concedido (`granted` é `t`) ou pedido e não concedido (`f`). Os ids de
processo são os dos seus terminais e serão outros números na sua máquina; leia-os pelos locks.

- O processo com **`ShareLock` em `orders` e `AccessExclusiveLock` em `orders_created_at`** é o
  terminal 1, o `REINDEX`. Nada o bloqueia.
- O processo com `RowExclusiveLock` em `orders`, não concedido, é o terminal 3. **Um update precisa
  de um lock que conflita com `ShareLock`**, então toda escrita na tabela espera a reconstrução
  inteira.
- O processo com `AccessShareLock` em `orders` concedido e em `orders_created_at` não concedido é o
  terminal 2. A consulta dele nunca usa aquele índice, e espera por ele mesmo assim.

Essa última linha é a que ninguém espera. **Antes de escolher um plano, o planejador abre todos os
índices da tabela**, para saber o que poderia usar, e abrir um pega `AccessShareLock`, que não
conflita com nada a não ser o `AccessExclusiveLock` que o `REINDEX` segura. Então a frase da
documentação, "bloqueia escritas mas não leituras da tabela-mãe do índice", vale para a tabela e não
para as consultas: quase toda consulta que toca a tabela entra na fila atrás da reconstrução de
qualquer um dos seus índices. O `pg_blocking_pids` aponta o culpado nas duas linhas que esperam.

De volta ao terminal 1, o fim:

```
shop=*# COMMIT;
COMMIT
```

Os dois comandos que esperavam terminaram no momento do commit. A lição 22 mostra o que acontece
quando um comando como este espera atrás de uma consulta longa em vez de na frente dela, e por que
todo mundo então entra na fila atrás dos dois. As lições 12 e 13 de `db-performance` tratam de locks
em geral.

**Numa tabela em uso, um `REINDEX` comum é uma pequena interrupção para aquela tabela**, que dura o
quanto dura a construção. Para os índices de `orders` isso é menos de meio segundo, como a próxima
seção mede. Para um índice de alguns gigabytes são minutos, e nada que lê ou escreve na tabela anda
durante eles. É por isso que a próxima seção existe.
