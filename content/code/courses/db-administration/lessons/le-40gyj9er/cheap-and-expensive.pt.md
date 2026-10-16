---
title: Mudanças baratas e mudanças caras
version: 1
---

Todo `ALTER TABLE` pega o lock do mesmo jeito. **O que muda é por quanto tempo ele o segura**, e isso
depende de uma pergunta: o PostgreSQL precisa tocar em cada linha? Algumas mudanças só editam o
catálogo, a descrição da tabela, e terminam em milissegundos em qualquer tamanho. Outras **reescrevem
a tabela**: escrevem uma cópia nova de cada linha num arquivo novo e trocam um pelo outro, segurando
`ACCESS EXCLUSIVE` o tempo todo, de modo que a tabela fica fechada enquanto a cópia durar.

Duas coisas deixam uma reescrita visível. O arquivo da tabela muda, porque a cópia nova é um arquivo
novo, e o `pg_relation_filepath` (lição 4) imprime outro nome. E o PostgreSQL avisa no nível
`DEBUG1`, que o `client_min_messages` consegue mostrar na sua própria sessão:

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# SET client_min_messages = debug1;
SET
Time: 0.292 ms

shop=# SELECT pg_relation_filepath('orders_live');
 pg_relation_filepath 
----------------------
 base/16386/16420
(1 row)

Time: 0.826 ms

shop=# ALTER TABLE orders_live ADD COLUMN channel text NOT NULL DEFAULT 'web';
ALTER TABLE
Time: 19.067 ms

shop=# SELECT pg_relation_filepath('orders_live');
 pg_relation_filepath 
----------------------
 base/16386/16420
(1 row)

Time: 0.405 ms

shop=# BEGIN;
BEGIN
Time: 0.273 ms

shop=*# ALTER TABLE orders_live ADD COLUMN token uuid DEFAULT gen_random_uuid();
DEBUG:  building index "pg_toast_16427_index" on table "pg_toast_16427" serially
DEBUG:  index "pg_toast_16427_index" can safely use deduplication
DEBUG:  rewriting table "orders_live"
ALTER TABLE
Time: 2814.463 ms (00:02.814)

shop=*# ALTER TABLE orders_live ALTER COLUMN total_cents TYPE bigint;
DEBUG:  building index "pg_toast_16432_index" on table "pg_toast_16432" serially
DEBUG:  index "pg_toast_16432_index" can safely use deduplication
DEBUG:  rewriting table "orders_live"
ALTER TABLE
Time: 2048.938 ms (00:02.049)

shop=*# SELECT pg_relation_filepath('orders_live');
 pg_relation_filepath 
----------------------
 base/16386/16432
(1 row)

Time: 0.817 ms

shop=*# SELECT mode FROM pg_locks WHERE relation = 'orders_live'::regclass AND pid = pg_backend_pid();
        mode         
---------------------
 ShareLock
 AccessExclusiveLock
(2 rows)

Time: 1.092 ms

shop=*# ROLLBACK;
ROLLBACK
Time: 31.254 ms

shop=# SELECT pg_relation_filepath('orders_live');
 pg_relation_filepath 
----------------------
 base/16386/16420
(1 row)

Time: 0.321 ms

shop=# ALTER TABLE orders_live ALTER COLUMN status TYPE varchar(20);
DEBUG:  sending cancel to blocking autovacuum PID 259
DEBUG:  building index "pg_toast_16437_index" on table "pg_toast_16437" serially
DEBUG:  index "pg_toast_16437_index" can safely use deduplication
DEBUG:  rewriting table "orders_live"
ALTER TABLE
Time: 2702.689 ms (00:02.703)

shop=# ALTER TABLE orders_live ALTER COLUMN status TYPE varchar(40);
ALTER TABLE
Time: 9.340 ms

shop=# \q
```

As linhas sobre índices `pg_toast` são a reescrita criando uma nova tabela auxiliar para valores
longos; a linha a procurar é **`rewriting table "orders_live"`**. Uma linha dizendo `sending cancel to
blocking autovacuum`, se a sua execução imprimir uma, é o `ALTER` cancelando um autovacuum que
trabalhava na tabela nova e segurava um lock em conflito; o autovacuum volta a ela depois.

## Acrescentar uma coluna

**Uma coluna com default constante é instantânea**, com `NOT NULL` e tudo. Desde o PostgreSQL 11 o
default é guardado uma vez no catálogo e entregue a cada linha antiga quando ela é lida, então
nenhuma linha é tocada; o arquivo manteve o nome, e o tempo foi de poucos milissegundos. Antes da
versão 11 o mesmo comando reescrevia a tabela, e é por isso que conselhos antigos dizem para nunca
acrescentar uma coluna com default.

**Um default volátil reescreve.** `gen_random_uuid()` dá um valor diferente a cada linha, então os
valores precisam ser escritos nas linhas, e o arquivo mudou. Menos de três segundos para um milhão de
linhas na máquina da gravação. Se escalasse por igual, um bilhão de linhas levaria boa parte de uma
hora, com a tabela fechada o tempo todo.

## Mudar um tipo

**Mudar `integer` para `bigint` reescreve**, porque um `bigint` tem oito bytes e um `integer` quatro,
então cada linha muda de forma. O `pg_locks` lista `AccessExclusiveLock` entre os locks da sessão na
tabela, e ele fica preso até a transação terminar.

Algumas mudanças de tipo não precisam de reescrita, e os dois últimos comandos mostram o par que vale
guardar. `text` para `varchar(20)` reescreveu, porque o novo limite precisava ser aplicado.
`varchar(20)` para `varchar(40)` foi instantâneo: **aumentar o limite de um `varchar`, ou removê-lo,
não tem como invalidar linha nenhuma**, então o PostgreSQL só edita o catálogo. Diminuir um limite
teria de conferir cada linha.

| mudança | reescreve? |
| --- | --- |
| acrescentar uma coluna, sem default ou com um constante | não |
| acrescentar uma coluna com default volátil | sim |
| remover uma coluna | não: ela é marcada como removida, e o espaço é reaproveitado à medida que as linhas são reescritas |
| `integer` para `bigint`, `text` para `integer`, e a maioria das mudanças de tipo | sim |
| `varchar(n)` para um `n` maior, ou para `text` | não |
| `SET NOT NULL` | não reescreve, mas lê a tabela inteira sob o lock, a não ser que um `CHECK` válido prove a regra (próxima seção) |

Na dúvida, teste numa cópia como esta com `client_min_messages` em `debug1`, e leia o nome do arquivo
antes e depois.

## Mudanças de esquema são transacionais

A coluna `token` e o `bigint` nunca ficaram. Os dois aconteceram dentro de `BEGIN`, e o `ROLLBACK` os
desfez: o nome do arquivo voltou ao de antes, e a tabela está como estava. **O PostgreSQL consegue
desfazer um `ALTER TABLE`**, junto com quase toda outra mudança de esquema, o que o MySQL e o Oracle
não conseguem. Uma migração que falha no meio dentro de uma transação não deixa nada pela metade. O
custo é que cada lock que ela pegou fica preso até o fim dessa transação, então uma migração longa
numa transação só é um lock longo.
