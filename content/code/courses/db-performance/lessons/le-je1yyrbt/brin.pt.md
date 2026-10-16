---
title: BRIN: um índice minúsculo para uma tabela em ordem
version: 1
---

Todo índice até aqui teve uma entrada por linha, ou mais. O BRIN, Block Range INdex, tem uma entrada
por **trecho da tabela**: por padrão 128 páginas, um megabyte. Para cada trecho ele anota o menor e o
maior valor da coluna ali dentro, e nada mais. Uma busca por um valor lê esses resumos, pula todo
trecho cujo mínimo e máximo descartam o valor, e lê o resto da tabela página por página.

Isso só funciona num tipo de coluna, e a aula 7 deu o número que diz qual: `correlation`.

## A coluna para a qual ele foi feito

`events` é gravada em ordem de tempo, então os eventos de qualquer trecho de páginas são de poucas
horas de um mesmo dia. O resumo dela, e os dois índices:

```
market=# SELECT attname, correlation FROM pg_stats WHERE tablename = 'events' AND attname IN ('at', 'customer_id');
   attname   |  correlation  
-------------+---------------
 at          |             1
 customer_id | -0.0031879602
(2 rows)

Time: 4.506 ms

market=# CREATE INDEX events_at_brin_idx ON events USING brin (at);
CREATE INDEX
Time: 951.654 ms

market=# CREATE INDEX events_at_btree_idx ON events (at);
CREATE INDEX
Time: 2358.183 ms (00:02.358)

market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('events', 'events_at_brin_idx', 'events_at_btree_idx');
       relname       |  size  
---------------------+--------
 events              | 511 MB
 events_at_brin_idx  | 32 kB
 events_at_btree_idx | 107 MB
(3 rows)

Time: 1.069 ms
```

`at` tem correlação **1**, perfeitamente na ordem da tabela; `customer_id` tem **-0.0032**, nenhuma.
Em `at`, a B-tree tem **107 MB** e levou 2,4 segundos para ser construída. O índice BRIN tem **32
kB**, umas três mil vezes menor, e levou menos de um segundo. Ele tem algumas centenas de entradas
para cinco milhões de linhas: 511 MB de tabela em faixas de 1 MB cada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas fileiras de oito caixas, cada caixa uma faixa de 128 páginas da tabela events com o menor e o maior valor que guarda. Na fileira de cima, para a coluna at, cada caixa cobre um trecho curto de tempo, um depois do outro como degraus, e uma consulta por um trecho de tempo toca só as caixas cujo trecho o contém. Na fileira de baixo, para customer_id, toda caixa cobre quase todo o intervalo de 1 a 200.000, então uma consulta pelo cliente 4242 bate em todas as caixas e toda página precisa ser lida.\"><text x=\"14\" y=\"74\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.at</text><text x=\"14\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">na ordem da tabela</text><rect x=\"150\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"154.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"220\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"231.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"290\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"308.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"360\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"385.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"430\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"462.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"500\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"539.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"570\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"616.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"640\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"693.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"150\" y=\"120\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">uma consulta por um trecho de tempo lê só as faixas que o contêm</text><text x=\"14\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.customer_id</text><text x=\"14\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">espalhada</text><rect x=\"150\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"154.5\" y=\"190\" width=\"54.4\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"220\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"224.8\" y=\"190\" width=\"54.3\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"290\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"295.4\" y=\"190\" width=\"52.5\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"360\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"364.0\" y=\"190\" width=\"55.6\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"430\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"434.6\" y=\"190\" width=\"53.7\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"500\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"506.2\" y=\"190\" width=\"52.6\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"570\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"575.9\" y=\"190\" width=\"53.0\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"640\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"645.4\" y=\"190\" width=\"52.7\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"150\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">uma consulta pelo cliente 4242 bate em toda faixa, e lê toda página</text><text x=\"150\" y=\"40\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada caixa: 128 páginas, com o menor e o maior valor nelas</text><text x=\"150\" y=\"276\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a barra dentro da caixa: o trecho de valores que a faixa cobre</text></svg>", "caption": "O que um índice BRIN guarda: o menor e o maior valor de cada faixa de 128 páginas. Numa coluna na ordem da tabela as faixas são estreitas e uma busca pula quase todas; numa coluna espalhada toda faixa cobre tudo."}
```

Agora os eventos de um dia, só com o índice BRIN:

```
market=# DROP INDEX events_at_btree_idx;
DROP INDEX
Time: 94.962 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM events WHERE at >= '2025-12-24' AND at < '2025-12-25';
                                                                      QUERY PLAN                                                                      
------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=69223.56..69223.57 rows=1 width=8) (actual time=17.858..17.861 rows=1 loops=1)
   ->  Bitmap Heap Scan on events  (cost=31.07..69075.15 rows=59364 width=0) (actual time=1.805..15.114 rows=55835 loops=1)
         Recheck Cond: ((at >= '2025-12-24 00:00:00-03'::timestamp with time zone) AND (at < '2025-12-25 00:00:00-03'::timestamp with time zone))
         Rows Removed by Index Recheck: 12635
         Heap Blocks: lossy=896
         ->  Bitmap Index Scan on events_at_brin_idx  (cost=0.00..16.22 rows=68359 width=0) (actual time=0.188..0.189 rows=8960 loops=1)
               Index Cond: ((at >= '2025-12-24 00:00:00-03'::timestamp with time zone) AND (at < '2025-12-25 00:00:00-03'::timestamp with time zone))
 Planning Time: 0.398 ms
 Execution Time: 17.943 ms
(9 rows)

Time: 19.358 ms
```

**18 milissegundos para 55.835 eventos.** Leia as linhas do bitmap de baixo para cima. O scan do
índice bateu em algumas faixas, e `Heap Blocks: lossy=896` são sete faixas de 128 páginas: o BRIN não
sabe dizer que linhas batem, só que páginas podem ter alguma, então o bitmap é **lossy**, uma lista
de páginas e não de linhas. Toda linha dessas páginas foi conferida de novo, e `Rows Removed by Index
Recheck: 12635` são os eventos das horas antes e depois do dia que dividiam com ele a primeira e a
última faixa. Uma B-tree teria apontado direto para as 55.835 linhas; o BRIN leu 68.470 linhas para
achá-las, e por 0,03% do tamanho da B-tree é uma boa troca.

Essa é toda a oferta do BRIN: um índice quase de graça para guardar e barato de manter, que uma linha
nova só altera quando cai fora do resumo da sua faixa, em troca de ler um pouco mais que a resposta.
Ele serve exatamente às tabelas grandes que só recebem linhas no fim, logs, eventos e leituras, onde
uma B-tree na coluna de tempo seria uma das maiores coisas do disco.

## A coluna para a qual ele não foi feito

Crie o mesmo tipo de índice em `customer_id`, cujos valores estão espalhados pela tabela:

```
market=# CREATE INDEX events_customer_brin_idx ON events USING brin (customer_id);
CREATE INDEX
Time: 927.104 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM events WHERE customer_id = 4242;
                                                                          QUERY PLAN                                                                           
---------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=82412.88..82412.89 rows=1 width=8) (actual time=436.591..445.316 rows=1 loops=1)
   ->  Gather  (cost=82412.66..82412.87 rows=2 width=8) (actual time=436.349..445.305 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=81412.66..81412.67 rows=1 width=8) (actual time=432.313..432.315 rows=1 loops=3)
               ->  Parallel Bitmap Heap Scan on events  (cost=26.04..81412.64 rows=8 width=0) (actual time=171.791..432.288 rows=6 loops=3)
                     Recheck Cond: (customer_id = 4242)
                     Rows Removed by Index Recheck: 1666661
                     Heap Blocks: lossy=26267
                     ->  Bitmap Index Scan on events_customer_brin_idx  (cost=0.00..26.04 rows=3063283 width=0) (actual time=3.463..3.464 rows=654320 loops=1)
                           Index Cond: (customer_id = 4242)
 Planning Time: 0.583 ms
 Execution Time: 445.468 ms
(13 rows)

Time: 447.036 ms
```

**445 milissegundos para 18 eventos.** O índice bateu em faixas equivalentes a 654.320 linhas, que
são todas elas: todo trecho de páginas tem eventos de clientes de perto de 1 até perto de 200.000,
então todo resumo diz "pode estar aqui". O scan rodou em três processos, e `Rows Removed by Index
Recheck: 1666661` em cada um deles, três vezes, é todo o resto dos eventos da tabela. O índice não
deixou a consulta mais rápida que um scan sequencial, e o planejador só o escolheu porque não sabe de
antemão o quanto os resumos são inúteis.

Então o BRIN é uma aposta na ordem física. Confira `correlation` antes de criar um, e lembre que a
ordem pode se desfazer: uma tabela cujas linhas são atualizadas, ou apagadas e repostas, vai
perdendo a ordem aos poucos, e o índice BRIN perde a utilidade junto.

## Que consulta da aula 2 cada índice conserta

| índice | pergunta que responde | no `market` | carga da aula 2 |
|---|---|---|---|
| B-tree | `=`, faixas, `ORDER BY`, `LIKE 'prefixo%'` | `price_cents`, para o `ORDER BY … LIMIT` da busca por tag | **`tag-search.sql`**, de 58,7 para 0,7 ms; a aula 2 já tinha criado `seller_id` para o `seller-dashboard.sql` |
| hash | só `=` | `customers.email` | nenhuma |
| GIN | contém: elementos de array, chaves de `jsonb`, palavras | `tags`, `payload` | `tag-search.sql`, de 58,7 para 19,8 ms |
| GiST | parecido, mais próximo, sobreposto | títulos por trigrama, intervalos de ausência | nenhuma |
| BRIN | faixas numa coluna na ordem da tabela | `events.at` | nenhuma |

O `pending-count.sql`, segundo no placar da aula 2, ficou fora da tabela de propósito. Uma B-tree
comum em `status` resolveria, e a aula 9 constrói uma setenta vezes menor. O `customer-orders.sql` já
é atendido pelo `orders_customer_id_idx`, e a aula 10 faz com que ele nunca toque a tabela.

Esta aula criou índices, duas extensões e uma tabela no `market`. Feche o `psql` e devolva o banco ao
estado em que a aula 3 começa:

```sh
~/reset-market.sh
```
