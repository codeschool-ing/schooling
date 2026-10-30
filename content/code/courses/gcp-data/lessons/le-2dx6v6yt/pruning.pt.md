---
title: Poda, medida no DuckDB
version: 1
---

**Podar é o motor decidir, antes de ler qualquer coisa, quais partições um filtro descarta.** O
BigQuery faz isso pelos metadados da tabela, e o DuckDB faz pelos nomes das pastas, e para as pastas da
aula 13 as duas decisões são a mesma ideia. O DuckDB tem a vantagem de imprimi-la. Com o `ask.py` da
aula 13, uma pergunta que começa com `EXPLAIN` imprime o plano, e o plano de uma consulta de um dia diz
quantos dos sessenta arquivos ela vai abrir:

```
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN SELECT sum(total_cents) FROM orders WHERE dt = DATE '2026-09-29'"
┌───────────────────────────┐
│    UNGROUPED_AGGREGATE    │
│    ────────────────────   │
│    Aggregates: sum(#0)    │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│         PROJECTION        │
│    ────────────────────   │
│        total_cents        │
│                           │
│        ~25,373 rows       │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│        READ_PARQUET       │
│    ────────────────────   │
│         Function:         │
│        READ_PARQUET       │
│                           │
│        Projections:       │
│        total_cents        │
│                           │
│       File Filters:       │
│ (dt = '2026-09-29'::DATE) │
│                           │
│    Scanning Files: 1/60   │
│                           │
│        ~25,373 rows       │
└───────────────────────────┘
```

**`Scanning Files: 1/60` é a poda, e `File Filters` é o que a fez.** O plano se lê de baixo para cima,
o que a aula 16 explica. O passo de leitura lista a única coluna que projeta, `total_cents`, e o filtro
em `dt` que aplicou aos nomes das pastas antes de abrir qualquer coisa. A estimativa de linhas do
DuckDB, cerca de 25.373, é um palpite feito antes da leitura; o dia tem 16.359, e o palpite não importa,
porque os arquivos que ele pulou ele nunca abre.

## Filtros que podam, e filtros que não podam

**Um filtro poda quando o motor consegue compará-lo com os valores das partições sem ler uma linha.**
Cinco filtros, cada um imprimindo a linha `Scanning Files` quando o plano tem uma, ou `every file`
quando não tem:

```
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN SELECT sum(total_cents) FROM orders WHERE dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-07'" | grep 'Scanning Files' || echo 'every file'
│    Scanning Files: 7/60   │
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN SELECT sum(total_cents) FROM orders WHERE created_at >= TIMESTAMP '2026-09-29 00:00:00-03'" | grep 'Scanning Files' || echo 'every file'
every file
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN SELECT sum(total_cents) FROM orders WHERE dt + INTERVAL 1 DAY = DATE '2026-09-30'" | grep 'Scanning Files' || echo 'every file'
every file
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN SELECT sum(total_cents) FROM orders WHERE dt = (SELECT max(dt) FROM orders)" | grep 'Scanning Files' || echo 'every file'
every file
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN SELECT sum(total_cents) FROM orders WHERE strftime(dt, '%Y-%m') = '2026-09'" | grep 'Scanning Files' || echo 'every file'
│   Scanning Files: 29/60   │
```

**Uma faixa em `dt` podou para sete arquivos**, a primeira semana de setembro. **Um filtro em
`created_at` não podou nada**: ele guarda o mesmo dia que `dt`, e o DuckDB não tem como saber disso,
porque as pastas são nomeadas por `dt`. O BigQuery se comporta do mesmo jeito. Uma tabela particionada
por uma coluna só é podada por um filtro nessa coluna, signifiquem o que significarem as outras.

**`dt + INTERVAL 1 DAY` não podou nada**, porque a coluna está dentro de uma expressão. A documentação do
Google diz o mesmo do BigQuery nos conselhos sobre consultar tabelas particionadas: deixe a coluna de
particionamento sozinha de um lado da comparação, e escreva `dt = DATE '2026-09-29'` em vez de fazer
conta com `dt`. **A subconsulta também não podou nada no planejamento**, porque o dia que ela pede só é
conhecido depois de `max(dt)` ser lido. A documentação do Google dá exatamente esse caso como um que não
limita as partições lidas: o filtro tem de ser uma expressão constante para a poda acontecer antes de a
consulta ler.

**`strftime(dt, '%Y-%m')` é onde os dois motores se separam.** O DuckDB avaliou a função no valor de cada
pasta e ficou com os 29 arquivos de setembro. Nada na documentação do Google promete que o BigQuery faz
o mesmo com uma função em volta da coluna de particionamento, e os conselhos dela apontam para o outro
lado. Então a regra que este curso tira dos dois é a segura: **compare a coluna de particionamento,
sozinha, com constantes**, e deixe `dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-30'` dizer o que o
`strftime` tentava dizer.

## O que a poda economiza, em bytes do BigQuery

Uma consulta que soma `total_cents` de uma semana cita duas colunas, `dt` e `total_cents`, ambas de 8
bytes por linha. O DuckDB conta as linhas, da tabela inteira e da semana, e o `ondemand.py` da aula 14
põe preço nelas. A tabela da Quitanda é tão pequena que as duas custariam o mínimo de 10 MB, então os
bytes são multiplicados por mil antes, como para uma empresa mil vezes maior:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT 16 * count(*) AS whole_table, 16 * count(*) FILTER (WHERE dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-07') AS one_week FROM orders"
┌─────────────┬──────────┐
│ whole_table │ one_week │
│    int64    │  int64   │
├─────────────┼──────────┤
│    19921888 │  2339968 │
└─────────────┴──────────┘

ana@laptop:~/gcp$ python3 ondemand.py 19921888000; python3 ondemand.py 2339968000
read  19,921,888,000 bytes   billed  19,921,895,424 bytes   0.203837 USD
read   2,339,968,000 bytes   billed   2,340,421,632 bytes   0.023947 USD
```

**A mil vezes o tamanho, a semana custa 0,0239 USD contra 0,2038 da tabela inteira**, um oitavo, porque
sete dos sessenta dias são mais ou menos um oitavo. A economia é exatamente a fração de partições
podadas, e cresce com o histórico: contra três anos de dias em vez de sessenta, a mesma semana custaria
cerca de um cento e cinquenta avos da varredura sem partição.

## Exigir o filtro

**`require_partition_filter` faz o BigQuery recusar uma consulta na tabela que não tenha filtro na
coluna de particionamento.** É uma opção da tabela, definida no DDL ou depois com
`ALTER TABLE quitanda.orders SET OPTIONS (require_partition_filter = TRUE)`. Uma consulta como
`SELECT sum(total_cents) FROM quitanda.orders` então falha com um erro dizendo que não pode consultar a
tabela sem um filtro em `dt`, e não custa nada, porque uma consulta que falha não é cobrada.

**É a proteção mais barata deste curso, e protege contra um erro específico**: a analista que esquece a
data, e o painel construído por alguém que não sabia que a tabela era grande. Ela não confere se o
filtro poda muito: `WHERE dt > DATE '2000-01-01'` a satisfaz e lê todas as partições. Nem pega o filtro
em `created_at` acima, que também lê todas as partições, e que esta opção só recusaria por não citar
`dt`. Ela faz da data uma pergunta que alguém tem de responder, que é a maior parte do que se precisa.
