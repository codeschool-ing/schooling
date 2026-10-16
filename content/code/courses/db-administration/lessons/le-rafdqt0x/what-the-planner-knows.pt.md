---
title: O que o planejador sabe sobre uma tabela
version: 1
---

O planejador escolhe um plano antes de ler uma única linha da tabela. Precisa ser assim: ler as
linhas é justamente o trabalho que o plano existe para organizar. **Então ele decide a partir de um
resumo**, guardado em dois catálogos do sistema, e o resumo só é tão recente quanto a última vez que
alguém o escreveu.

O tamanho de cada tabela está em `pg_class`:

```
shop=# SELECT relname, reltuples, relpages FROM pg_class WHERE relname IN ('orders', 'customers');
  relname  | reltuples | relpages 
-----------+-----------+----------
 customers |     50000 |      568
 orders    |     1e+06 |     8334
(2 rows)
```

`reltuples` é o número de linhas e `relpages` o número de páginas de 8 kB, ambos como estavam na
última vez que um `VACUUM` ou um `ANALYZE` olhou. A lição 4 apresentou as páginas como os arquivos
no disco; aqui elas são um dos dois números de onde toda estimativa de custo parte.

O que há dentro de cada coluna está em `pg_statistic`, que é difícil de ler diretamente, e por isso o
PostgreSQL põe sobre ele uma view chamada `pg_stats`. Uma linha por coluna:

```
shop=# SELECT attname, null_frac, n_distinct FROM pg_stats WHERE tablename = 'orders';
   attname   | null_frac | n_distinct 
-------------+-----------+------------
 id          |         0 |         -1
 customer_id |         0 |      49325
 status      |         0 |          3
 total_cents |         0 |      49325
 created_at  |         0 |      87417
(5 rows)

shop=# SELECT most_common_vals, most_common_freqs FROM pg_stats WHERE tablename = 'orders' AND attname = 'status';
     most_common_vals     |       most_common_freqs       
--------------------------+-------------------------------
 {paid,cancelled,shipped} | {0.6027333,0.19946666,0.1978}
(1 row)
```

Três colunas dessa view fazem quase todo o trabalho.

- **`null_frac`** é a fração de linhas em que a coluna é nula. Toda coluna de `orders` é
  `NOT NULL`, então ela vale 0 em todas.
- **`n_distinct`** é quantos valores diferentes a coluna guarda. Um número positivo é uma contagem;
  um negativo é uma fração das linhas, para continuar certo quando a tabela cresce. O `-1` em `id`
  diz que cada linha tem o seu próprio valor, que é o que uma chave primária é.
- **`most_common_vals`** e **`most_common_freqs`** são os valores frequentes e a fração das linhas
  que cada um ocupa. `status` tem três valores, e a lista nomeia todos.

## Do resumo a uma estimativa

Peça um plano e olhe só para `rows=`, o número de linhas que o planejador espera que um passo
produza:

```
shop=# EXPLAIN SELECT * FROM orders WHERE status = 'cancelled';
                           QUERY PLAN                           
----------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..20834.00 rows=199467 width=34)
   Filter: (status = 'cancelled'::text)
(2 rows)

shop=# EXPLAIN SELECT * FROM orders WHERE customer_id = 42;
                                    QUERY PLAN                                    
----------------------------------------------------------------------------------
 Bitmap Heap Scan on orders  (cost=4.58..81.89 rows=20 width=34)
   Recheck Cond: (customer_id = 42)
   ->  Bitmap Index Scan on orders_customer_id  (cost=0.00..4.58 rows=20 width=0)
         Index Cond: (customer_id = 42)
(4 rows)
```

Os dois números são aritmética sobre o que você acabou de ler. `cancelled` ocupa 0.19946666 das
linhas, e 0.19946666 × 1.000.000 dá 199.467: **a estimativa é a frequência vezes o número de
linhas**, exatamente. `42` não está em nenhuma lista de valores comuns, então o planejador supõe que
os clientes dividem a tabela por igual: 1.000.000 de linhas sobre 49.325 valores distintos dá 20
linhas para cada um.

A verdade é 200.000 pedidos cancelados e 20 pedidos para cada cliente, porque o gerador da lição 4
os fez por aritmética. **As estimativas são próximas e não exatas porque o `ANALYZE` lê uma
amostra** — 30.000 linhas desta tabela, escolhidas ao acaso — e uma amostra de um milhão de linhas
erra por pouco. As suas frequências e o seu `n_distinct` vão diferir destes nos últimos dígitos, e
mudam de novo toda vez que a tabela é analisada. Um plano não liga para o último dígito. Liga para a
diferença entre vinte e vinte mil.

A `pg_stats` tem mais colunas do que essas: `histogram_bounds`, que serve às condições de
intervalo como `created_at > …`, e `correlation`, que diz o quanto a ordem física das linhas segue a
coluna. A lição 7 de `db-performance` lê as duas, e também as estatísticas estendidas, que juntam
duas colunas. O que importa para administrar o servidor é mais simples. **Toda estimativa é feita a
partir desse resumo, e nada atualiza o resumo a não ser o `ANALYZE`**, rodado à mão ou pelo
autovacuum. Quando a tabela muda e o resumo não, o planejador continua decidindo sobre uma tabela
que não existe mais.
