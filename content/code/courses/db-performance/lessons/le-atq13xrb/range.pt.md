---
title: Por faixa: uma partição por mês
version: 1
---

O particionamento por faixa (range) dá a cada partição **um intervalo da chave**: deste instante até
aquele, sem incluí-lo. É o tipo que combina com o trabalho da seção 02, porque o tempo vem em
intervalos e as linhas antigas saem por intervalo. A tabela abaixo é `events` de novo, com as mesmas
colunas e os mesmos cinco milhões de linhas, cortada em uma partição por mês. Salve como
`~/events_by_month.sql`:

```sql
-- events_by_month.sql: the events table again, cut into one partition a month.
-- Run it on market:  psql market -f events_by_month.sql
-- It starts by dropping the table, so running it twice builds it afresh.
DROP TABLE IF EXISTS events_by_month;

CREATE TABLE events_by_month (
    id          bigint      NOT NULL,
    at          timestamptz NOT NULL,
    customer_id integer,
    kind        text        NOT NULL,
    payload     jsonb       NOT NULL,
    PRIMARY KEY (id, at)
) PARTITION BY RANGE (at);

-- Each month runs from its first instant up to, not including, the next one.
CREATE TABLE events_2025_10 PARTITION OF events_by_month
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE events_2025_11 PARTITION OF events_by_month
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE events_2025_12 PARTITION OF events_by_month
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
CREATE TABLE events_2026_01 PARTITION OF events_by_month
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

INSERT INTO events_by_month SELECT * FROM events;

CREATE INDEX ON events_by_month (customer_id);
VACUUM ANALYZE events_by_month;
```

Leia em três partes. **O pai** é um `CREATE TABLE` como qualquer outro, mais `PARTITION BY RANGE
(at)`, que dá nome à chave. Ele não guarda linhas e nunca vai guardar. **As partições** são tabelas
próprias, cada uma anexada com `PARTITION OF` e o intervalo que aceita. O limite superior é
exclusivo, então `2025-11-01 00:00` pertence a novembro e não a outubro, e os meses se encontram sem
buraco nem sobreposição — o servidor recusa duas partições cujos intervalos se sobreponham. Janeiro
de 2026 está vazio e está ali de propósito: o mês seguinte ao fim dos dados tem de existir **antes**
de a primeira linha dele chegar. **As linhas** vêm de `events` num único `INSERT`, e cada uma é
encaminhada para a sua partição pelo seu `at`.

A chave primária é `(id, at)` e não só `id`, o que a seção 06 explica, e o índice em `customer_id` é
declarado uma vez, no pai. Rode:

```
ana@vm:~$ psql market -v ON_ERROR_STOP=1 -f events_by_month.sql
psql:events_by_month.sql:4: NOTICE:  table "events_by_month" does not exist, skipping
DROP TABLE
Time: 1.103 ms
CREATE TABLE
Time: 8.159 ms
CREATE TABLE
Time: 6.025 ms
CREATE TABLE
Time: 4.305 ms
CREATE TABLE
Time: 3.368 ms
CREATE TABLE
Time: 3.133 ms
INSERT 0 5000000
Time: 22026.298 ms (00:22.026)
CREATE INDEX
Time: 4306.158 ms (00:04.306)
VACUUM
Time: 2186.480 ms (00:02.186)
```

Vinte e dois segundos para copiar cinco milhões de linhas e encaminhar cada uma para o seu mês. O
`\d+` mostra o resultado como uma tabela com quatro partições, e uma contagem por `tableoid`, a
coluna escondida que diz em que tabela uma linha mora fisicamente, mostra para onde as linhas foram:

```
market=# \d+ events_by_month
                                          Partitioned table "public.events_by_month"
   Column    |           Type           | Collation | Nullable | Default | Storage  | Compression | Stats target | Description 
-------------+--------------------------+-----------+----------+---------+----------+-------------+--------------+-------------
 id          | bigint                   |           | not null |         | plain    |             |              | 
 at          | timestamp with time zone |           | not null |         | plain    |             |              | 
 customer_id | integer                  |           |          |         | plain    |             |              | 
 kind        | text                     |           | not null |         | extended |             |              | 
 payload     | jsonb                    |           | not null |         | extended |             |              | 
Partition key: RANGE (at)
Indexes:
    "events_by_month_pkey" PRIMARY KEY, btree (id, at)
    "events_by_month_customer_id_idx" btree (customer_id)
Partitions: events_2025_10 FOR VALUES FROM ('2025-10-01 00:00:00-03') TO ('2025-11-01 00:00:00-03'),
            events_2025_11 FOR VALUES FROM ('2025-11-01 00:00:00-03') TO ('2025-12-01 00:00:00-03'),
            events_2025_12 FOR VALUES FROM ('2025-12-01 00:00:00-03') TO ('2026-01-01 00:00:00-03'),
            events_2026_01 FOR VALUES FROM ('2026-01-01 00:00:00-03') TO ('2026-02-01 00:00:00-03')

market=# SELECT tableoid::regclass AS partition, count(*), pg_size_pretty(pg_relation_size(tableoid)) AS size FROM events_by_month GROUP BY 1 ORDER BY 1;
   partition    |  count  |  size  
----------------+---------+--------
 events_2025_10 | 1611210 | 165 MB
 events_2025_11 | 1667081 | 170 MB
 events_2025_12 | 1721709 | 176 MB
(3 rows)

Time: 353.448 ms
```

Os limites aparecem com `-03` porque foram escritos como datas e lidos no fuso horário da sessão,
aqui o de São Paulo. A fronteira de um mês é um instante, então um servidor e uma aplicação que
discordam do fuso discordam sobre a que mês pertence um clique às dez da noite. Escreva os limites
com fuso explícito, ou mantenha servidor e aplicação num mesmo fuso, e saiba qual.

**Três partições de uns 170 MB cada, e uma quarta vazia.** A vazia não aparece na contagem, que só
lista tabelas com linhas.

## Uma linha sem ter para onde ir

Uma linha cuja chave cai fora de todos os intervalos é recusada, não guardada num lugar aproximado:

```
market=# INSERT INTO events_by_month VALUES (0, '2026-03-01', NULL, 'view', '{}');
ERROR:  no partition of relation "events_by_month" found for row
DETAIL:  Partition key of the failing row contains (at) = (2026-03-01 00:00:00-03).
Time: 1.549 ms
```

Março de 2026 não tem partição, então o insert falha. É a falha que o particionamento por faixa traz
consigo, e ela chega numa data: **alguém precisa criar o mês que vem antes do mês que vem**. Uma
rotina que cria partições alguns meses adiante, monitorada como um backup, é a resposta habitual; a
seção 05 mostra a outra, uma partição padrão, e quanto ela custa.

## Não é mais rápido por si só

Eis o custo da seção 02, medido. A mesma busca por `id`, em `events` e em `events_by_month`:

```
market=# EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM events WHERE id = 2500000;
                                    QUERY PLAN                                    
----------------------------------------------------------------------------------
 Index Scan using events_pkey on events (actual time=0.127..0.128 rows=1 loops=1)
   Index Cond: (id = 2500000)
 Planning Time: 0.824 ms
 Execution Time: 0.218 ms
(4 rows)

Time: 3.445 ms

market=# EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM events_by_month WHERE id = 2500000;
                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 Append (actual time=0.144..0.221 rows=1 loops=1)
   ->  Index Scan using events_2025_10_pkey on events_2025_10 events_by_month_1 (actual time=0.080..0.080 rows=0 loops=1)
         Index Cond: (id = 2500000)
   ->  Index Scan using events_2025_11_pkey on events_2025_11 events_by_month_2 (actual time=0.062..0.063 rows=1 loops=1)
         Index Cond: (id = 2500000)
   ->  Index Scan using events_2025_12_pkey on events_2025_12 events_by_month_3 (actual time=0.070..0.070 rows=0 loops=1)
         Index Cond: (id = 2500000)
   ->  Seq Scan on events_2026_01 events_by_month_4 (actual time=0.005..0.005 rows=0 loops=1)
         Filter: (id = 2500000)
 Planning Time: 1.560 ms
 Execution Time: 0.279 ms
(11 rows)

Time: 2.626 ms
```

Em `events` é **uma leitura de índice**. Em `events_by_month` é um `Append` de **quatro leituras**,
uma por partição, porque nada em `id = 2500000` diz em que mês a linha está: três leituras de índice
e uma leitura sequencial do janeiro vazio, que não custa nada. A execução é 0,218 contra 0,279
milissegundos, e o planejamento 0,824 contra 1,560, quase o dobro, porque o planejador tinha quatro
tabelas para planejar em vez de uma.

Números pequenos, os dois. O que importa é a direção: numa consulta que não menciona a chave, a
tabela particionada fez **mais** trabalho, nunca menos. Uma consulta que a menciona, com `at` numa
faixa, é assunto da aula 18, e é ali que o particionamento recupera custos como este. Esta tabela
fica em `market` para a aula 18; o fim desta aula diz como deixá-la exatamente como a aula 18
espera.
