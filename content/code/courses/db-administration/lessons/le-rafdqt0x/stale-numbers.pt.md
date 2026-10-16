---
title: Um plano feito com os números de ontem
version: 1
---

A imagem comum de uma consulta lenta é um índice que falta ou uma consulta mal escrita. **Um plano
pode dar errado com a consulta, o índice e o servidor todos iguais**, porque a tabela mudou e o
resumo dela não. Esta seção faz isso acontecer de propósito, numa cópia de `orders`, para que o
próprio `shop` nunca seja tocado.

## Uma cópia, analisada, com a análise automática segurada

```
shop=# CREATE TABLE orders_copy (LIKE orders INCLUDING ALL);
CREATE TABLE

shop=# ALTER TABLE orders_copy SET (autovacuum_enabled = off);
ALTER TABLE

shop=# CREATE INDEX orders_copy_status ON orders_copy (status);
CREATE INDEX

shop=# INSERT INTO orders_copy (customer_id, status, total_cents, created_at) SELECT customer_id, status, total_cents, created_at FROM orders;
INSERT 0 1000000

shop=# ANALYZE orders_copy;
ANALYZE
```

`LIKE orders INCLUDING ALL` copia as colunas, os defaults, a identidade e os índices, e o `INSERT`
copia o milhão de linhas. O índice em `status` é novo: a consulta abaixo filtra por ele. O
`ANALYZE` no fim põe a cópia no estado de uma tabela em dia — a cópia como estava ontem, resumida.

O `ALTER TABLE` é a linha que torna a demonstração possível, e **não é algo para fazer numa tabela
de verdade**. O autovacuum, assunto da próxima seção, perceberia a mudança que você vai fazer e
analisaria a tabela sozinho, em geral dentro de um minuto. Esse minuto é real e é nele que moram os
planos ruins, mas é curto demais para ler um plano com calma. Desligar o autovacuum só nesta tabela
mantém a janela aberta pelo tempo que você quiser.

## A importação desta noite

Chegam trezentos mil pedidos com um status que ninguém tinha usado antes, `pending`, e um relatório
os conta por país logo em seguida:

```
shop=# INSERT INTO orders_copy (customer_id, status, total_cents, created_at) SELECT 1 + (i * 7919::bigint) % 50000, 'pending', 1000, timestamptz '2026-09-01 00:00-03' + i * interval '1 second' FROM generate_series(1, 300000) AS i;
INSERT 0 300000

shop=# EXPLAIN ANALYZE SELECT c.country, count(*) FROM orders_copy o JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY c.country;
                                                                        QUERY PLAN                                                                        
----------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=15.96..15.98 rows=1 width=11) (actual time=668.789..704.301 rows=5 loops=1)
   Group Key: c.country
   ->  Sort  (cost=15.96..15.96 rows=1 width=3) (actual time=660.696..685.067 rows=300000 loops=1)
         Sort Key: c.country
         Sort Method: external merge  Disk: 2072kB
         ->  Nested Loop  (cost=0.72..15.95 rows=1 width=3) (actual time=0.094..606.783 rows=300000 loops=1)
               ->  Index Scan using orders_copy_status on orders_copy o  (cost=0.43..7.64 rows=1 width=8) (actual time=0.023..56.604 rows=300000 loops=1)
                     Index Cond: (status = 'pending'::text)
               ->  Index Scan using customers_pkey on customers c  (cost=0.29..8.31 rows=1 width=11) (actual time=0.002..0.002 rows=1 loops=300000)
                     Index Cond: (id = o.customer_id)
 Planning Time: 0.773 ms
 Execution Time: 704.651 ms
(12 rows)
```

Ler planos é a lição 3 de `db-performance`, e duas coisas neste aqui bastam. O scan de `orders_copy`
diz `rows=1` na estimativa e `rows=300000` no que aconteceu. E com base nessa única linha o
planejador escolheu um **nested loop**: para cada pedido encontrado, buscar o cliente por
`customers_pkey`. Para um pedido, esse é o plano mais barato que existe. Ele rodou 300.000 vezes
(`loops=300000`), e a consulta levou 704.651 ms.

O planejador não fez nada de errado com o que tinha. Veja o que ele tinha:

```
shop=# SELECT most_common_vals, most_common_freqs FROM pg_stats WHERE tablename = 'orders_copy' AND attname = 'status';
     most_common_vals     |         most_common_freqs          
--------------------------+------------------------------------
 {paid,shipped,cancelled} | {0.60103333,0.20153333,0.19743334}
(1 row)

shop=# SELECT n_live_tup, n_mod_since_analyze, last_analyze FROM pg_stat_user_tables WHERE relname = 'orders_copy';
 n_live_tup | n_mod_since_analyze |         last_analyze          
------------+---------------------+-------------------------------
    1300000 |              300000 | 2026-10-10 04:26:45.449579-03
(1 row)
```

**O resumo ainda diz que três valores formam a tabela inteira**: 0.60103333 + 0.20153333 +
0.19743334 dá 1. Um quarto valor não tem espaço nele, então o planejador estima o mínimo que ainda
é uma estimativa, que é uma linha. Ele sabia que a tabela tinha crescido, porque o tamanho no disco é
conferido na hora de planejar. O que ele não tinha como saber é o que as linhas novas contêm.

A `pg_stat_user_tables` é onde o servidor conta o que aconteceu com cada tabela, e duas colunas dela
são as que um administrador lê aqui. **`n_mod_since_analyze` é o número de linhas inseridas,
atualizadas ou apagadas desde que o resumo foi escrito**: 300.000, quase um quarto da tabela.
`last_analyze` é quando isso foi, e é o momento antes da importação.

## Um comando

```
shop=# ANALYZE orders_copy;
ANALYZE

shop=# EXPLAIN ANALYZE SELECT c.country, count(*) FROM orders_copy o JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY c.country;
                                                                               QUERY PLAN                                                                               
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=19268.11..19269.37 rows=5 width=11) (actual time=77.028..82.518 rows=5 loops=1)
   Group Key: c.country
   ->  Gather Merge  (cost=19268.11..19269.27 rows=10 width=11) (actual time=77.018..82.507 rows=15 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=18268.08..18268.10 rows=5 width=11) (actual time=73.180..73.185 rows=5 loops=3)
               Sort Key: c.country
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=18267.97..18268.02 rows=5 width=11) (actual time=73.142..73.147 rows=5 loops=3)
                     Group Key: c.country
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Hash Join  (cost=4941.25..17648.67 rows=123861 width=3) (actual time=18.323..60.508 rows=100000 loops=3)
                           Hash Cond: (o.customer_id = c.id)
                           ->  Parallel Bitmap Heap Scan on orders_copy o  (cost=3248.25..15630.51 rows=123861 width=8) (actual time=1.748..13.959 rows=100000 loops=3)
                                 Recheck Cond: (status = 'pending'::text)
                                 Heap Blocks: exact=985
                                 ->  Bitmap Index Scan on orders_copy_status  (cost=0.00..3173.93 rows=297267 width=0) (actual time=4.797..4.798 rows=300000 loops=1)
                                       Index Cond: (status = 'pending'::text)
                           ->  Hash  (cost=1068.00..1068.00 rows=50000 width=11) (actual time=16.265..16.266 rows=50000 loops=3)
                                 Buckets: 65536  Batches: 1  Memory Usage: 2856kB
                                 ->  Seq Scan on customers c  (cost=0.00..1068.00 rows=50000 width=11) (actual time=0.027..7.081 rows=50000 loops=3)
 Planning Time: 0.716 ms
 Execution Time: 82.626 ms
(27 rows)
```

O plano ficou mais longo porque é melhor. O bitmap index scan agora espera 297.267 linhas e encontra
300.000. Os clientes são lidos uma vez para uma tabela hash (`Hash Join`) em vez de buscados 300.000
vezes, e dois workers paralelos dividem o trabalho. **82.626 ms em vez de 704.651 ms, para a mesma
consulta sobre os mesmos dados**, e a única coisa que mudou foi o resumo.

Oito vezes mais lento é um caso brando. O mesmo erro diante de um join com uma tabela grande, ou
debaixo de uma ordenação que esperava uma linha e recebeu um milhão, leva uma consulta de
milissegundos a minutos, e nada na consulta, no índice ou no log aponta a causa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma linha do tempo. O ANALYZE escreve o resumo: três valores, todas as linhas. Então chegam 300.000 linhas pending. Desse momento até o próximo ANALYZE, todo plano acha que 'pending' é uma linha, enquanto n_mod_since_analyze conta 300.000 mudanças. O próximo ANALYZE, rodado por você ou pelo autovacuum quando 50 linhas mais 10% da tabela mudaram, faz a estimativa virar 297.267 linhas.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"250\" y=\"62\" width=\"330\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><line x1=\"20\" y1=\"120\" x2=\"700\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"60\" y1=\"110\" x2=\"60\" y2=\"130\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><line x1=\"250\" y1=\"110\" x2=\"250\" y2=\"130\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><line x1=\"580\" y1=\"110\" x2=\"580\" y2=\"130\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"60\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">ANALYZE</text><text x=\"66\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o resumo é escrito</text><text x=\"72\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3 valores, 100% das linhas</text><text x=\"250\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">chegam 300.000 linhas pending</text><text x=\"415\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">todo plano feito aqui dentro</text><text x=\"415\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">acha que 'pending' é 1 linha</text><text x=\"415\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">n_mod_since_analyze: 300.000</text><text x=\"415\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">last_analyze: antes da importação</text><text x=\"580\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">ANALYZE</text><text x=\"580\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">por você, ou pelo autovacuum quando</text><text x=\"580\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">50 + 10% das linhas mudaram</text><text x=\"640\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">297.267 linhas</text><text x=\"640\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">estimadas</text><text x=\"700\" y=\"106\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "Entre uma mudança e o próximo ANALYZE, o planejador trabalha com o resumo antigo. A janela dura enquanto ninguém analisar a tabela."}
```

## O que isso pede de você

**Um job que carrega ou reescreve uma parte grande de uma tabela roda `ANALYZE` nessa tabela como
último passo**, antes que qualquer coisa a leia. Importações noturnas, um backfill, um `DELETE`
grande de linhas antigas, uma migração que reescreve uma coluna: todos eles. Custa uma fração de
segundo numa tabela como esta, e a lição 10 de `sql-databases` já mostrou a versão mais curta do
hábito, uma carga seguida de `ANALYZE`.

É seguro rodá-lo numa tabela em uso. O `ANALYZE` pega um lock que deixa leituras e escritas
continuarem, e só espera por coisas que mudam a estrutura da tabela, por um `VACUUM` ou por outro
`ANALYZE`. Dentro de uma transação ele também é permitido, então uma carga feita numa transação pode
terminar com o `ANALYZE` que a descreve.

A cópia continua com o autovacuum desligado por enquanto. A próxima seção o religa e o vê fazer o
mesmo trabalho sozinho.
